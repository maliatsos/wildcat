addpath('./Tools');
addpath('./Filters');

%% Software radio rx:
% SDR_RX;
rx_signal = read_complex_binary ('rx_signal.bin', 'double');
rx_signal = rx_signal(end/2+1:end);
%% Sampling Frequency:
Fs = 3125000; % in Hz

load('ofdm_signal.mat')
load('ofdm_preamble.mat')
load('preamble_signal.mat');

%% Receiver:
receiver(rx_signal(1:10000), filter_params, preambles_only, ofdm_params)