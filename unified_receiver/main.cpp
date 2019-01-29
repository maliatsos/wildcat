//
// Copyright 2010-2011,2014 Ettus Research LLC
// Copyright 2018 Ettus Research, a National Instruments Company
//
// SPDX-License-Identifier: GPL-3.0-or-later
//

#include <uhd/types/tune_request.hpp>
#include <uhd/utils/thread.hpp>
#include <uhd/utils/safe_main.hpp>
#include <uhd/usrp/multi_usrp.hpp>
#include <uhd/exception.hpp>
#include <boost/program_options.hpp>
#include <boost/format.hpp>
#include <boost/lexical_cast.hpp>
#include <iostream>
#include <fstream>
#include <csignal>
#include <complex>
#include <thread>
#include <chrono>

#include "usrp_config.h"

namespace po = boost::program_options;
using namespace std;

static bool stop_signal_called = false;
void sig_int_handler(int){stop_signal_called = true;}

template<typename samp_type> void recv_to_file(
    uhd::usrp::multi_usrp::sptr usrp,
    const std::string &cpu_format,
    const std::string &wire_format,
    const size_t &channel,
    const std::string &file,
    size_t samps_per_buff,
    unsigned long long num_requested_samples,
    double time_requested = 0.0,
    bool bw_summary = false,
    bool stats = false,
    bool null = false,
    bool enable_size_map = false,
    bool continue_on_bad_packet = false
){
    unsigned long long num_total_samps = 0;
    //create a receive streamer
    uhd::stream_args_t stream_args(cpu_format,wire_format);
    std::vector<size_t> channel_nums;
    channel_nums.push_back(0);
    stream_args.channels = channel_nums;
    uhd::rx_streamer::sptr rx_stream = usrp->get_rx_stream(stream_args);

    cout << "****************" << file << endl;
    cout << "****************" << channel_nums[0] << endl;

    uhd::rx_metadata_t md;
    std::vector<samp_type> buff(samps_per_buff);
    std::ofstream outfile;
    if (not null)
        outfile.open(file.c_str(), std::ofstream::binary);
    bool overflow_message = true;

    //setup streaming
    uhd::stream_cmd_t stream_cmd((num_requested_samples == 0)?
        uhd::stream_cmd_t::STREAM_MODE_START_CONTINUOUS:
        uhd::stream_cmd_t::STREAM_MODE_NUM_SAMPS_AND_DONE
    );
    stream_cmd.num_samps = size_t(num_requested_samples);
    stream_cmd.stream_now = true;
    stream_cmd.time_spec = uhd::time_spec_t();
    rx_stream->issue_stream_cmd(stream_cmd);

    typedef std::map<size_t,size_t> SizeMap;
    SizeMap mapSizes;
    const auto start_time = std::chrono::steady_clock::now();
    const auto stop_time =
        start_time
        + std::chrono::milliseconds(int64_t(1000 * time_requested));
    // Track time and samps between updating the BW summary
    auto last_update = start_time;
    unsigned long long last_update_samps = 0;

    // Run this loop until either time expired (if a duration was given), until
    // the requested number of samples were collected (if such a number was
    // given), or until Ctrl-C was pressed.
    while (not stop_signal_called
            and (num_requested_samples != num_total_samps
                 or num_requested_samples == 0)
            and (time_requested == 0.0
                 or std::chrono::steady_clock::now() <= stop_time)
            ) {
        const auto now = std::chrono::steady_clock::now();

        size_t num_rx_samps =
            rx_stream->recv(&buff.front(), buff.size(), md, 3.0, enable_size_map);

        if (md.error_code == uhd::rx_metadata_t::ERROR_CODE_TIMEOUT) {
            std::cout << boost::format("Timeout while streaming") << std::endl;
            break;
        }
        if (md.error_code == uhd::rx_metadata_t::ERROR_CODE_OVERFLOW){
            if (overflow_message) {
                overflow_message = false;
                std::cerr << boost::format(
                    "Got an overflow indication. Please consider the following:\n"
                    "  Your write medium must sustain a rate of %fMB/s.\n"
                    "  Dropped samples will not be written to the file.\n"
                    "  Please modify this example for your purposes.\n"
                    "  This message will not appear again.\n"
                ) % (usrp->get_rx_rate(channel)*sizeof(samp_type)/1e6);
            }
            continue;
        }
        if (md.error_code != uhd::rx_metadata_t::ERROR_CODE_NONE){
            std::string error = str(boost::format("Receiver error: %s") % md.strerror());
            if (continue_on_bad_packet){
                std::cerr << error << std::endl;
                continue;
            }
            else
                throw std::runtime_error(error);
        }

        if (enable_size_map) {
            SizeMap::iterator it = mapSizes.find(num_rx_samps);
            if (it == mapSizes.end())
                mapSizes[num_rx_samps] = 0;
            mapSizes[num_rx_samps] += 1;
        }

        num_total_samps += num_rx_samps;

        if (outfile.is_open()) {
            outfile.write(
                (const char*)&buff.front(),
                num_rx_samps*sizeof(samp_type)
            );
        }

        if (bw_summary) {
            last_update_samps += num_rx_samps;
            const auto time_since_last_update = now - last_update;
            if (time_since_last_update > std::chrono::seconds(1)) {
                const double time_since_last_update_s =
                    std::chrono::duration<double>(time_since_last_update).count();
                const double rate =
                    double(last_update_samps) / time_since_last_update_s;
                std::cout << "\t" << (rate/1e6) << " Msps" << std::endl;
                last_update_samps = 0;
                last_update = now;
            }
        }
    }
    const auto actual_stop_time = std::chrono::steady_clock::now();

    stream_cmd.stream_mode = uhd::stream_cmd_t::STREAM_MODE_STOP_CONTINUOUS;
    rx_stream->issue_stream_cmd(stream_cmd);

    if (outfile.is_open()) {
        outfile.close();
    }

    if (stats) {
        std::cout << std::endl;
        const double actual_duration_seconds =
            std::chrono::duration<float>(actual_stop_time - start_time).count();

        std::cout
            << boost::format("Received %d samples in %f seconds")
               % num_total_samps
               % actual_duration_seconds
            << std::endl;
        const double rate = (double)num_total_samps / actual_duration_seconds;
        std::cout << (rate/1e6) << " Msps" << std::endl;

        if (enable_size_map) {
            std::cout << std::endl;
            std::cout << "Packet size map (bytes: count)" << std::endl;
            for (SizeMap::iterator it = mapSizes.begin(); it != mapSizes.end(); it++)
                std::cout << it->first << ":\t" << it->second << std::endl;
        }
    }
}

typedef std::function<uhd::sensor_value_t(const std::string&)> get_sensor_fn_t;

bool check_locked_sensor(
    std::vector<std::string> sensor_names,
    const char* sensor_name,
    get_sensor_fn_t get_sensor_fn,
    double setup_time
) {
    if (std::find(sensor_names.begin(), sensor_names.end(), sensor_name) == sensor_names.end())
        return false;

    auto setup_timeout =
        std::chrono::steady_clock::now()
        + std::chrono::milliseconds(int64_t(setup_time * 1000));
    bool lock_detected = false;

    std::cout << boost::format("Waiting for \"%s\": ") % sensor_name;
    std::cout.flush();

    while (true) {
        if (lock_detected and
            (std::chrono::steady_clock::now() > setup_timeout)) {
            std::cout << " locked." << std::endl;
            break;
        }
        if (get_sensor_fn(sensor_name).to_bool()) {
            std::cout << "+";
            std::cout.flush();
            lock_detected = true;
        }
        else {
            if (std::chrono::steady_clock::now() > setup_timeout) {
                std::cout << std::endl;
                throw std::runtime_error(str(
                    boost::format("timed out waiting for consecutive locks on sensor \"%s\"")
                    % sensor_name
                ));
            }
            std::cout << "_";
            std::cout.flush();
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
    std::cout << std::endl;
    return true;
}

template <class T>
void write_complex_to_binary(string file,  vector<T>& input_vector ) {
    //------------------------------------ WRITE TO BINARY FILE_------------------------------------------
    std::ofstream outfile;
    outfile.open(file.c_str(), std::ofstream::binary);
    int num_rx_samps = input_vector.size();
    outfile.write((const char*)&input_vector.front(), num_rx_samps*sizeof(std::complex<double>));
    outfile.close();
}
template void write_complex_to_binary<double>(string, vector<double>&);
template void write_complex_to_binary<complex<double> >(string, vector<complex<double> >&);

void discover_usrps(uhd::device_addr_t & hint, uhd::device_addrs_t & dev_addrs, UsrpConfig & usrp_config) {

  try {
    // ===== Find devices:
    dev_addrs = uhd::device::find(hint);

    // ===== Number of identified devices:
    cout << "Discovered USRPs:" << dev_addrs.size() << endl;

    // Check the type of detected USRPs
    vector<size_t> n_ind;vector<size_t> b_ind;
    vector<string> serials; vector<string> ip_addresses;

    for (size_t ii = 0; ii<dev_addrs.size(); ii++) {
        usrp_config.usrp_type.push_back(dev_addrs[ii].get("type"));
        usrp_config.usrp_discovered_serials.push_back(dev_addrs[ii].get("serial"));
        if (usrp_config.usrp_type[ii].at(0) == 'b') {
            //===================
            cout << "Found b-device with serial:" << usrp_config.usrp_discovered_serials[ii] << endl;
            //==================
            usrp_config.usrp_discovered_addresses.push_back("N/A");
          } else if (usrp_config.usrp_type[ii] == "usrp2") {
            usrp_config.usrp_discovered_addresses.push_back(dev_addrs[ii].get("addr"));
            //===========================
            cout << "Found n-device with address:" << usrp_config.usrp_discovered_addresses[ii] << endl;
            //===========================
          }
        else if (usrp_config.usrp_type[ii] == "x300") {
            usrp_config.usrp_discovered_addresses.push_back(dev_addrs[ii].get("addr"));
            //===========================
            cout << "Found x-device with address:" << usrp_config.usrp_discovered_addresses[ii] << endl;
            //===========================
          }
      }

  } catch (invalid_argument& e) {
    cerr << e.what() << endl;
  }

}

int UHD_SAFE_MAIN(int argc, char *argv[]){

    if (argc != 3) {
        cout
                << "Usage: ./unified_receiver <path_to_usrp_config> <path_to_waveform_config>"
                << endl;
        return -1;
    }

    UsrpConfig config;
    // Read the configuration file
    initialize_config(argv[1], &config);

    uhd::set_thread_priority_safe();
    uhd::device_addr_t hint;
    uhd::device_addrs_t dev_addrs;

    discover_usrps(hint, dev_addrs, config);
    cout << "===========================================================" << endl;
    cout << "Number of Discovered usrps: " << dev_addrs.size() << endl;
    cout << "===========================================================" << endl;

    //variables to be set by po
    std::string args, file, type, ant, subdev, ref, wirefmt;
    size_t channel, total_num_samps, spb;
    double rate, freq, gain, bw, total_time, setup_time;

    file = argv[2];
    rate = config.usrp_rx_rate[0][0];
    freq = config.usrp_rx_freq[0];
    gain = config.usrp_rx_gain[0][0];
    bw = config.usrp_rx_analog_bw[0];
    setup_time = config.usrp_timeout_secs[0];
    spb = config.usrp_rx_frame_size[0];

    ref = config.usrp_ref[0];
    channel = config.usrp_rx_chan_num[0]-1;
    type = "double";
    wirefmt = "sc16";

    bool bw_summary = true;
    bool stats = true;
    bool null = false;
    bool enable_size_map = true;
    bool continue_on_bad_packet = true;

    if (config.usrp_type[0][0]=='b') {
        string tmp = to_string(config.usrp_master_clock_rate[0]);
        args = "master_clock_rate=" + tmp;
    } else {
        args = "addr=" + config.usrp_addresses[0][0];
        bw = 50000000;
    }

    if (config.usrp_number_of_samples[0]!=0) {
        total_num_samps =config.usrp_number_of_samples[0];
        total_time =0;
    } else {
        total_time = config.usrp_duration_secs[0];
        total_num_samps = 0;
    }
    cout << "total num:" << total_num_samps << endl;
    cout << "total time:" << total_time << endl;

    if (enable_size_map)
        std::cout << "Packet size tracking enabled - will only recv one packet at a time!" << std::endl;

    //create a usrp device
    std::cout << std::endl;
    std::cout << boost::format("Creating the usrp device with: %s...") % args << std::endl;
    uhd::usrp::multi_usrp::sptr usrp = uhd::usrp::multi_usrp::make(args);

    //Lock mboard clocks
    usrp->set_clock_source(ref);

    if (config.usrp_rx_subdevs[0].size()>0) {
        //always select the subdevice first, the channel mapping affects the other settings
        subdev = config.usrp_rx_subdevs[0][0];
        usrp->set_rx_subdev_spec(subdev);
    }

    std::cout << boost::format("Using Device: %s") % usrp->get_pp_string() << std::endl;

    //set the sample rate
    if (rate <= 0.0){
        std::cerr << "Please specify a valid sample rate" << std::endl;
        return ~0;
    }
    std::cout << boost::format("Setting RX Rate: %f Msps...") % (rate/1e6) << std::endl;
    usrp->set_rx_rate(rate, channel);
    std::cout << boost::format("Actual RX Rate: %f Msps...") % (usrp->get_rx_rate(channel)/1e6) << std::endl << std::endl;

    //set the center frequency
    std::cout << boost::format("Setting RX Freq: %f MHz...") % (freq/1e6) << std::endl;
    uhd::tune_request_t tune_request(freq);
    if(config.usrp_intn[0]) tune_request.args = uhd::device_addr_t("mode_n=integer");
    usrp->set_rx_freq(tune_request, channel);
    std::cout << boost::format("Actual RX Freq: %f MHz...") % (usrp->get_rx_freq(channel)/1e6) << std::endl << std::endl;

    //set the rf gain
    std::cout << boost::format("Setting RX Gain: %f dB...") % gain << std::endl;
    usrp->set_rx_gain(gain, channel);
    std::cout << boost::format("Actual RX Gain: %f dB...") % usrp->get_rx_gain(channel) << std::endl << std::endl;

    //set the IF filter bandwidth
    std::cout << boost::format("Setting RX Bandwidth: %f MHz...") % (bw/1e6) << std::endl;
    usrp->set_rx_bandwidth(bw, channel);
    std::cout << boost::format("Actual RX Bandwidth: %f MHz...") % (usrp->get_rx_bandwidth(channel)/1e6) << std::endl << std::endl;

    //set the antenna
    if (config.usrp_rx_antennas[0].size()>0) {
        ant = config.usrp_rx_antennas[0][0];
        usrp->set_rx_antenna(ant, channel);
    }
    std::this_thread::sleep_for(
        std::chrono::milliseconds(int64_t(1000 * setup_time))
    );

    //check Ref and LO Lock detect
    check_locked_sensor(
        usrp->get_rx_sensor_names(channel),
        "lo_locked",
        [usrp,channel](const std::string& sensor_name){
            return usrp->get_rx_sensor(sensor_name, channel);
        },
        setup_time
    );
    if (ref == "mimo") {
        check_locked_sensor(
            usrp->get_mboard_sensor_names(0),
            "mimo_locked",
            [usrp](const std::string& sensor_name){
                return usrp->get_mboard_sensor(sensor_name);
            },
            setup_time
        );
    }
    if (ref == "external") {
        check_locked_sensor(
            usrp->get_mboard_sensor_names(0),
            "ref_locked",
            [usrp](const std::string& sensor_name){
                return usrp->get_mboard_sensor(sensor_name);
            },
            setup_time
        );
    }

    if (total_num_samps == 0){
        std::signal(SIGINT, &sig_int_handler);
        std::cout << "Press Ctrl + C to stop streaming..." << std::endl;
    }


#define recv_to_file_args(format) \
    (usrp, format, wirefmt, channel, file, spb, total_num_samps, total_time, bw_summary, stats, null, enable_size_map, continue_on_bad_packet)
    //recv to file
    if (wirefmt == "s16") {
        if (type == "double") recv_to_file<double>recv_to_file_args("f64");
        else if (type == "float") recv_to_file<float>recv_to_file_args("f32");
        else if (type == "short") recv_to_file<short>recv_to_file_args("s16");
        else throw std::runtime_error("Unknown type " + type);
    } else {
        if (type == "double") recv_to_file<std::complex<double> >recv_to_file_args("fc64");
        else if (type == "float") recv_to_file<std::complex<float> >recv_to_file_args("fc32");
        else if (type == "short") recv_to_file<std::complex<short> >recv_to_file_args("sc16");
        else throw std::runtime_error("Unknown type " + type);
    }

    //finished
    std::cout << std::endl << "Done!" << std::endl << std::endl;

    return EXIT_SUCCESS;
}
