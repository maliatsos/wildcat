/*
 * usrp_config.cpp
 *
 *  Created on: Oct 27, 2017
 *      Author: Feron Technologies
 */

#pragma GCC diagnostic ignored "-Wsign-conversion"
#include "usrp_config.h"

#include <iostream>
#include <vector>
#include <fstream>
#include <math.h>
#include <stdlib.h>
#include <sstream>


#define CONFIG_DELIM '='

using namespace std;

int minimum_usrp_gain;
vector<double> detection_thresholds;

/*
 * Handle the input configuration file and construct the appropriate config struct
 */
void initialize_config(const char * usrp_filename, UsrpConfig * usrp_config) {

    try {
        read_usrp_config(usrp_filename, usrp_config);
        cout << "Reading configuration from file complete" << endl;

    } catch (ifstream::failure& e) {
        throw ifstream::failure(e.what());
    }
}



void read_usrp_config(const char * filename, UsrpConfig * config) {

    try {
        cout << "Initializing configuration..." << endl;
        initvalues(config);

        ifstream is_file(filename);
        stringstream is_file_content;

        is_file_content << is_file.rdbuf();
        is_file.close();

        string line;

        int identified_usrp_systems = -1;
        while (getline(is_file_content, line)) {
            istringstream is_line(line);
            string key;
            // key - value pairs are separated via equals sign
            if (getline(is_line, key, CONFIG_DELIM)) {
                if (key.substr(0,3)=="new")  {
                    if (identified_usrp_systems>-1) {
                        initvalues(config);
                        identified_usrp_systems++;
                    }
                }
                if (identified_usrp_systems==-1) {
                    identified_usrp_systems = 0;
                }
                config->usrp_addresses.resize(identified_usrp_systems+1);
                config->usrp_serials.resize(identified_usrp_systems+1);
                config->usrps_per_conf.resize(identified_usrp_systems+1);
                config->usrp_rx_antennas.resize(identified_usrp_systems+1);
                config->usrp_tx_antennas.resize(identified_usrp_systems+1);
                config->usrp_rx_subdevs.resize(identified_usrp_systems+1);
                config->usrp_tx_subdevs.resize(identified_usrp_systems+1);

                string value;
                if (getline(is_line >> std::ws, value)) {
                    if (key.find("usrp_master_clock") != string::npos) {
                        config->usrp_master_clock_rate[identified_usrp_systems] = atof(value.c_str());
                        config->usrp_tx_analog_bw[identified_usrp_systems] = atof(value.c_str());
                        config->usrp_rx_analog_bw[identified_usrp_systems] = atof(value.c_str());
                    } else if (key.find("usrp_tx_freq") != string::npos) {
                        config->usrp_tx_freq[identified_usrp_systems] = atof(value.c_str());
                    } else if (key.find("usrp_rx_freq") != string::npos) {
                        config->usrp_rx_freq[identified_usrp_systems] = atof(value.c_str());
                    } else if (key.find("usrp_tx_gain") != string::npos) {
                        size_t pos_start = 0; size_t pos = 0; size_t pos_end;
                        vector<double> tmp;
                        string tmpstr;
                        while ((pos!=string::npos)) {
                            pos = value.find(",", pos_start);
                            if (pos==string::npos) pos_end=value.size(); else pos_end=pos;
                            tmpstr = value.substr(pos_start, pos_end-pos_start);
                            tmp.push_back(atof(value.c_str()));
                            pos_start = pos+1;
                         }
                        config->usrp_tx_gain[identified_usrp_systems] = tmp;
                      } else if (key.find("usrp_rx_gain") != string::npos) {
                        size_t pos_start = 0; size_t pos = 0; size_t pos_end;
                        vector<double> tmp;
                        string tmpstr;
                        while ((pos!=string::npos)) {
                          pos = value.find(",", pos_start);
                          if (pos==string::npos) pos_end=value.size(); else pos_end=pos;
                              tmpstr = value.substr(pos_start, pos_end-pos_start);
                              tmp.push_back(atof(value.c_str()));
                              pos_start = pos+1;
                           }
                        config->usrp_rx_gain[identified_usrp_systems] = tmp;
                      } else if (key.find("usrp_rx_rate") != string::npos) {
                        size_t pos_start = 0; size_t pos = 0; size_t pos_end;
                        vector<double> tmp;
                        string tmpstr;
                        while ((pos!=string::npos)) {
                          pos = value.find(",", pos_start);
                          if (pos==string::npos) pos_end=value.size(); else pos_end=pos;
                              tmpstr = value.substr(pos_start, pos_end-pos_start);
                              tmp.push_back(atof(value.c_str()));
                              pos_start = pos+1;
                           }
                        config->usrp_rx_rate[identified_usrp_systems] = tmp;
                    } else if (key.find("usrp_tx_frame_size") != string::npos) {
                        config->usrp_tx_frame_size[identified_usrp_systems] = atoi(value.c_str());
                    } else if (key.find("usrp_rx_frame_size") != string::npos) {
                        config->usrp_rx_frame_size[identified_usrp_systems] = atoi(value.c_str());
                    } else if (key.find("usrp_rx_chan_num") != string::npos) {
                        config->usrp_rx_chan_num[identified_usrp_systems] = atoi(value.c_str());
                    } else if (key.find("usrp_tx_chan_num") != string::npos) {
                        config->usrp_tx_chan_num[identified_usrp_systems] = atoi(value.c_str());
                    } else if (key.find("usrp_data_type") != string::npos) {
                        config->usrp_data_type[identified_usrp_systems] = value;
                    } else if (key.find("cpu_mode") != string::npos) {
                        if ((value!="fc64") && (value!="fc32") && (value!="sc8") && (value!="sc16")) {
                        config->cpu_mode[identified_usrp_systems] = "fc32";
                          } else {
                        config->cpu_mode[identified_usrp_systems] = value;
                          }
                      } else if (key.find("otw_mode") != string::npos) {
                        if ((value!="sc16") && (value!="sc12") && (value!="sc8")) {
                          config->otw_mode[identified_usrp_systems] = "sc16";
                        } else {
                          config->otw_mode[identified_usrp_systems] = value;
                        }
                    } else if (key.find("usrp_intn") != string::npos) {
                        if (value.find("1") != string::npos
                                || value.find("true") != string::npos) {
                            config->usrp_intn[identified_usrp_systems] = true;
                        } else {
                            config->usrp_intn[identified_usrp_systems] = false;
                        }
                    } else if (key.find("usrp_timeout_secs") != string::npos) {
                        config->usrp_timeout_secs[identified_usrp_systems] = atof(value.c_str());
                    } else if (key.find("usrp_duration_secs") != string::npos) {
                        config->usrp_duration_secs[identified_usrp_systems] = atof(value.c_str());
                    } else if (key.find("usrp_ref") != string::npos) {
                        if ((value!="internal") && (value!="external") && (value!="mimo")) {
                        config->usrp_ref[identified_usrp_systems] = "internal";
                          } else {
                        config->usrp_ref[identified_usrp_systems] = value;
                          }
                    } else if (key.find("usrp_number_of_samples") != string::npos) {
                        config->usrp_number_of_samples[identified_usrp_systems] = (atoi(value.c_str()));
                    } else if (key.find("mode") != string::npos) {
                          config->mode[identified_usrp_systems]= value.c_str();
                    } else if (key.find("usrp_serials") != string::npos) {
                        size_t pos_start = 0; size_t pos = 0; size_t pos_end;
                        vector<string> tmp;
                        while ((pos!=string::npos)) {
                            pos = value.find(",", pos_start);
                            if (pos==string::npos) pos_end=value.size(); else pos_end=pos;
                            tmp.push_back(value.substr(pos_start, pos_end-pos_start));
                            pos_start = pos+1;
                        }
                        config->usrp_serials[identified_usrp_systems]= tmp;
                        config->usrps_per_conf[identified_usrp_systems]= config->usrps_per_conf[identified_usrp_systems]+(tmp.size());
                    } else if (key.find("usrp_addresses") != string::npos) {
                        size_t pos_start = 0; size_t pos = 0; size_t pos_end;
                        vector<string> tmp;
                        while ((pos!=string::npos)) {
                            pos = value.find(",", pos_start);
                            if (pos==string::npos) pos_end=value.size(); else pos_end=pos;
                            tmp.push_back(value.substr(pos_start, pos_end-pos_start));
                            pos_start = pos+1;
                        }
                        config->usrp_addresses[identified_usrp_systems] = tmp;
                        config->usrps_per_conf[identified_usrp_systems] = config->usrps_per_conf[identified_usrp_systems]+(tmp.size());
                    } else if (key.find("usrp_rx_antennas") != string::npos) {
                        size_t pos_start = 0; size_t pos = 0; size_t pos_end;
                        vector<string> tmp;
                        while ((pos!=string::npos)) {
                            pos = value.find(",", pos_start);
                            if (pos==string::npos) pos_end=value.size(); else pos_end=pos;
                            tmp.push_back(value.substr(pos_start, pos_end-pos_start));
                            pos_start = pos+1;
                        }
                        config->usrp_rx_antennas[identified_usrp_systems] = tmp;
                     } else if (key.find("usrp_tx_antennas") != string::npos) {
                        size_t pos_start = 0; size_t pos = 0; size_t pos_end;
                        vector<string> tmp;
                        while ((pos!=string::npos)) {
                        pos = value.find(",", pos_start);
                        if (pos==string::npos) pos_end=value.size(); else pos_end=pos;
                        tmp.push_back(value.substr(pos_start, pos_end-pos_start));
                        pos_start = pos+1;
                        }
                      config->usrp_tx_antennas[identified_usrp_systems] = tmp;
                      }
                    else if (key.find("usrp_tx_subdevs") != string::npos) {
                      size_t pos_start = 0; size_t pos = 0; size_t pos_end;
                      vector<string> tmp;
                      while ((pos!=string::npos)) {
                          pos = value.find(",", pos_start);
                          if (pos==string::npos) pos_end=value.size(); else pos_end=pos;
                          tmp.push_back(value.substr(pos_start, pos_end-pos_start));
                          pos_start = pos+1;
                        }
                      config->usrp_tx_subdevs[identified_usrp_systems] = tmp;
                      }
                    else if (key.find("usrp_rx_subdevs") != string::npos) {
                      size_t pos_start = 0; size_t pos = 0; size_t pos_end;
                      vector<string> tmp;
                      while ((pos!=string::npos)) {
                          pos = value.find(",", pos_start);
                          if (pos==string::npos) pos_end=value.size(); else pos_end=pos;
                          tmp.push_back(value.substr(pos_start, pos_end-pos_start));
                          pos_start = pos+1;
                        }
                      config->usrp_rx_subdevs[identified_usrp_systems] = tmp;
                      }
                    }
              }
        }
        config->usrp_setups = identified_usrp_systems+1;
        cout << "# of Configurations provides as input:" <<  config->usrp_setups << endl;
        for (unsigned int kk=0; kk<config->usrp_setups; kk++) {
            cout << "In configuration " << kk << ", usrps provided:" << config->usrps_per_conf[kk] << endl;
            if (config->usrps_per_conf[kk]==0) {
                cout << "Zero is not acceptable value - but in this case zero means to be defined by existing usrps" << endl;
                config->usrps_per_conf[kk] = 0;
            }

        }
        config->config_status.resize(config->usrp_setups);
    } catch (ifstream::failure& e) {
        throw ifstream::failure(e.what());
    }
}

void initvalues(UsrpConfig * config) {
    config->usrp_setups++;
    config->duplex.push_back("fdd");
    config->mode.push_back("tx/rx");
    // The default configuration considers a B2XX
    config->usrp_master_clock_rate.push_back(30720000); // Default value the LTE clock
    // Tx parameters:
    config->usrp_tx_chan_num.push_back(1); // Default SISO
    config->usrp_tx_analog_bw.push_back(30720000); // Analog BW set to clock rate
    config->usrp_tx_freq.push_back(2560000000);
        vector<double> tmp; tmp.push_back(60);
        config->usrp_tx_gain.push_back(tmp);
        vector<double> tmp2; tmp2.push_back(config->usrp_tx_analog_bw.back()/2);
        config->usrp_tx_rate.push_back(tmp2); // Half of the Analog BW

    config->usrp_tx_frame_size.push_back(config->usrp_tx_analog_bw.back()/2000);
    // Rx parameters:
    config->usrp_rx_chan_num.push_back(1); // Default SISO
    config->usrp_rx_analog_bw.push_back(30720000); // Analog BW set to clock rate
    config->usrp_rx_rate.push_back(tmp2); // Half of the Analog BW
    config->usrp_rx_freq.push_back(2560000000);
    config->usrp_rx_gain.push_back(tmp);
    config->usrp_rx_frame_size.push_back(config->usrp_rx_analog_bw.back()/2000);
    // Other general parameters:
    config->usrp_intn.push_back(false);
    config->usrp_timeout_secs.push_back(6);
    config->usrp_duration_secs.push_back(30);
    config->usrp_number_of_samples.push_back(0);
    config->usrp_ref.push_back("internal");
    config->usrp_data_type.push_back("double");
    config->cpu_mode.push_back("fc32");
    config->otw_mode.push_back("sc16");
}
