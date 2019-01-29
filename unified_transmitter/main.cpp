//
// Copyright 2011-2012,2014 Ettus Research LLC
// Copyright 2018 Ettus Research, a National Instruments Company
//
// SPDX-License-Identifier: GPL-3.0-or-later
//

#include <uhd/types/tune_request.hpp>
#include <uhd/utils/thread.hpp>
#include <uhd/utils/safe_main.hpp>
#include <uhd/usrp/multi_usrp.hpp>
#include <boost/program_options.hpp>
#include <boost/format.hpp>
#include <iostream>
#include <fstream>
#include <complex>
#include <csignal>
#include <chrono>
#include <thread>

#include "usrp_config.h"

namespace po = boost::program_options;
using namespace std;

static bool stop_signal_called = false;
void sig_int_handler(int){stop_signal_called = true;}

template<typename samp_type> void send_from_file(
    uhd::tx_streamer::sptr tx_stream,
    const std::string &file,
    size_t samps_per_buff
){
    uhd::tx_metadata_t md;
    md.start_of_burst = false;
    md.end_of_burst = false;
    std::vector<samp_type> buff(samps_per_buff);
    std::ifstream infile(file.c_str(), std::ifstream::binary);

    //loop until the entire file has been read

    while(not md.end_of_burst and not stop_signal_called){

        infile.read((char*)&buff.front(), buff.size()*sizeof(samp_type));
        size_t num_tx_samps = size_t(infile.gcount()/sizeof(samp_type));

        md.end_of_burst = infile.eof();

        tx_stream->send(&buff.front(), num_tx_samps, md);
    }

    infile.close();
}

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
                << "Usage: ./unified_receiver <path_to_usrp_config> <path_to_waveform_config> <file-to-sent>"
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
    std::string args, file, type, ant, subdev, ref, wirefmt, channel;
    size_t spb;
    double rate, freq, gain, bw, delay, lo_off;

    file = argv[2];
    rate = config.usrp_tx_rate[0][0];
    freq = config.usrp_tx_freq[0];
    gain = config.usrp_tx_gain[0][0];
    spb = config.usrp_tx_frame_size[0];
    lo_off = config.usrp_lo_off[0];
    bw = config.usrp_tx_analog_bw[0];

    ref = config.usrp_ref[0];
    channel = config.usrp_tx_chan_num[0];
    type = "double";
    wirefmt = "sc16";
    bool repeat = true;
    delay = 0;

    if (config.usrp_type[0][0]=='b') {
        string tmp = to_string(config.usrp_master_clock_rate[0]);
        args = "master_clock_rate=" + tmp;
    } else {
        args = "addr=" + config.usrp_addresses[0][0];
        bw = 100000000;
    }


    //create a usrp device
    std::cout << std::endl;
    std::cout << boost::format("Creating the usrp device with: %s...") % args << std::endl;
    uhd::usrp::multi_usrp::sptr usrp = uhd::usrp::multi_usrp::make(args);

    //Lock mboard clocks
    usrp->set_clock_source(ref);

    std::this_thread::sleep_for(std::chrono::seconds(1));

    if (config.usrp_tx_subdevs[0].size()>0) {
        //always select the subdevice first, the channel mapping affects the other settings
        subdev = config.usrp_tx_subdevs[0][0];
        usrp->set_tx_subdev_spec(subdev);
    }

    std::cout << boost::format("Using Device: %s") % usrp->get_pp_string() << std::endl;

    //set the sample rate
    if (rate <= 0.0){
        std::cerr << "Please specify a valid sample rate" << std::endl;
        return ~0;
    }
    std::cout << boost::format("Setting TX Rate: %f Msps...") % (rate/1e6) << std::endl;
    usrp->set_tx_rate(rate);
    std::cout << boost::format("Actual TX Rate: %f Msps...") % (usrp->get_tx_rate()/1e6) << std::endl << std::endl;

    //set the center frequency
    std::cout << boost::format("Setting TX Freq: %f MHz...") % (freq/1e6) << std::endl;
    uhd::tune_request_t tune_request;
    if(lo_off!=0.0) tune_request = uhd::tune_request_t(freq, lo_off);
    else tune_request = uhd::tune_request_t(freq);
    if(config.usrp_intn[0]) tune_request.args = uhd::device_addr_t("mode_n=integer");
    usrp->set_tx_freq(tune_request);
    std::cout << boost::format("Actual TX Freq: %f MHz...") % (usrp->get_tx_freq()/1e6) << std::endl << std::endl;

    //set the rf gain
    std::cout << boost::format("Setting TX Gain: %f dB...") % gain << std::endl;
    usrp->set_tx_gain(gain);
    std::cout << boost::format("Actual TX Gain: %f dB...") % usrp->get_tx_gain() << std::endl << std::endl;

    //set the IF filter bandwidth
    std::cout << boost::format("Setting TX Bandwidth: %f MHz...") % (bw/1e6) << std::endl;
    usrp->set_tx_bandwidth(bw);
    std::cout << boost::format("Actual TX Bandwidth: %f MHz...") % (usrp->get_tx_bandwidth()/1e6) << std::endl << std::endl;

    //set the antenna
    if (config.usrp_tx_antennas[0].size()>0) {
        ant = config.usrp_tx_antennas[0][0];
        usrp->set_tx_antenna(ant);
    }

    //allow for some setup time:
    std::this_thread::sleep_for(std::chrono::seconds(1));

    //Check Ref and LO Lock detect
    std::vector<std::string> sensor_names;
    sensor_names = usrp->get_tx_sensor_names(0);
    if (std::find(sensor_names.begin(), sensor_names.end(), "lo_locked") != sensor_names.end()) {
        uhd::sensor_value_t lo_locked = usrp->get_tx_sensor("lo_locked",0);
        std::cout << boost::format("Checking TX: %s ...") % lo_locked.to_pp_string() << std::endl;
        UHD_ASSERT_THROW(lo_locked.to_bool());
    }
    sensor_names = usrp->get_mboard_sensor_names(0);
    if ((ref == "mimo") and (std::find(sensor_names.begin(), sensor_names.end(), "mimo_locked") != sensor_names.end())) {
        uhd::sensor_value_t mimo_locked = usrp->get_mboard_sensor("mimo_locked",0);
        std::cout << boost::format("Checking TX: %s ...") % mimo_locked.to_pp_string() << std::endl;
        UHD_ASSERT_THROW(mimo_locked.to_bool());
    }
    if ((ref == "external") and (std::find(sensor_names.begin(), sensor_names.end(), "ref_locked") != sensor_names.end())) {
        uhd::sensor_value_t ref_locked = usrp->get_mboard_sensor("ref_locked",0);
        std::cout << boost::format("Checking TX: %s ...") % ref_locked.to_pp_string() << std::endl;
        UHD_ASSERT_THROW(ref_locked.to_bool());
    }

    //set sigint if user wants to receive
    if(repeat){
        std::signal(SIGINT, &sig_int_handler);
        std::cout << "Press Ctrl + C to stop streaming..." << std::endl;
    }

    //create a transmit streamer
    std::string cpu_format;
    std::vector<size_t> channel_nums;
    if (type == "double") cpu_format = "fc64";
    else if (type == "float") cpu_format = "fc32";
    else if (type == "short") cpu_format = "sc16";
    uhd::stream_args_t stream_args(cpu_format, wirefmt);
    channel_nums.push_back(boost::lexical_cast<size_t>(0));
    stream_args.channels = channel_nums;
    uhd::tx_streamer::sptr tx_stream = usrp->get_tx_stream(stream_args);

    //send from file
    int packet_counter = 0;
    do{
        if (type == "double") send_from_file<std::complex<double> >(tx_stream, file, spb);
        else if (type == "float") send_from_file<std::complex<float> >(tx_stream, file, spb);
        else if (type == "short") send_from_file<std::complex<short> >(tx_stream, file, spb);
        else throw std::runtime_error("Unknown type " + type);

        if(repeat and delay > 0.0) {
            std::this_thread::sleep_for(
                std::chrono::milliseconds(int64_t(delay*1000))
            );
        }
        packet_counter++;
        if (packet_counter % 50 == 0) {cout << "Packets send:" << packet_counter << endl;}
    } while(repeat and not stop_signal_called);

    //finished
    std::cout << std::endl << "Done!" << std::endl << std::endl;

    return EXIT_SUCCESS;
}
