#ifndef USRP_CONFIG_H
#define USRP_CONFIG_H

#endif // USRP_CONFIG_H
/*
 * usrp_config.h
 *
 *      Author: Feron Technologies
 */

#ifndef CONFIGURATION_USRP_CONFIG_H_
#define CONFIGURATION_USRP_CONFIG_H_

#include <vector>
#include <complex>
#include <string>

extern std::vector<double> detection_thresholds;
extern int minimum_usrp_gain;

struct UsrpConfig {

    std::vector<std::string> usrp_discovered_serials;
    std::vector<std::string> usrp_discovered_addresses;
    std::vector<std::string> usrp_type;

    // Mode of operation:
    std::vector<std::string> mode;
    std::vector<std::string> duplex;

    // USRP setup parameters:
    std::vector<double> usrp_master_clock_rate;
    std::vector<double> usrp_tx_freq;
    std::vector<double> usrp_rx_freq;
    std::vector<std::vector<double> > usrp_tx_gain;
    std::vector<std::vector<double> > usrp_rx_gain;
    std::vector<std::vector<double> > usrp_rx_rate;
    std::vector<std::vector<double> > usrp_tx_rate;
    std::vector<double> usrp_rx_analog_bw;
    std::vector<double> usrp_tx_analog_bw;
    std::vector<double> usrp_lo_off;
    std::vector<size_t> usrp_rx_chan_num;
    std::vector<size_t> usrp_tx_chan_num;
    std::vector<int> usrp_rx_frame_size;
    std::vector<int> usrp_tx_frame_size;

    std::vector<bool> usrp_intn;
    std::vector<std::string> usrp_ref;
    std::vector<double> usrp_timeout_secs;
    std::vector<double> usrp_duration_secs;
    std::vector<int> usrp_number_of_samples;

    // Parameters ...kept mainly private:
    size_t usrp_setups;
    std::vector<int> usrps_per_conf;
    std::vector<bool> config_status;
    std::vector<std::vector<int> > usrp_indexes;
    std::vector<std::string> usrp_data_type;
    std::vector<std::vector<std::string> > usrp_serials;
    std::vector<std::vector<std::string> > usrp_addresses;
    std::vector<std::vector<std::string> >usrp_rx_antennas;
    std::vector<std::vector<std::string> > usrp_tx_antennas;
    std::vector<std::vector<std::string> > usrp_tx_subdevs;
    std::vector<std::vector<std::string> > usrp_rx_subdevs;
    std::vector<std::string> cpu_mode;
    std::vector<std::string> otw_mode;

    // USRP CPU Thread Affinity Parameters
    int cpu_affinity_core=-1;
    int rx_proc_core;
    int tx_proc_core;
    unsigned int max_memory_size;
    int max_tx_bucket_size;

};


void initialize_config(const char *, UsrpConfig *);
void read_usrp_config(const char *, UsrpConfig *);
void initvalues(UsrpConfig *);

#endif /* CONFIGURATION_USRP_CONFIG_H_ */
