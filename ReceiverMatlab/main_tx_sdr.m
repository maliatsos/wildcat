addpath('./Tools');
addpath('./Filters');

%% Sampling Frequency:
Fs = 3.125e6; % in Hz

%% Configuration of the Unified modulator (parameters):
N1 = 20; Lpreamble = 6;
filter_params = configuration_input(N1, Lpreamble);

%% Create Multi-Carrier modulation data frame:
modrank = 4;    % qam modulation rank
[DataFrame, X1, X2] = create_mc_data_frame(filter_params.N1-filter_params.Lpreamble, filter_params.e1, filter_params.Lpreamble, filter_params.oqam_flag, modrank);

%---------------------------------------------------------
% Create an OFDM preamble:
script_ofdm_reference_signal;

% --------------------------------------------------------
%% Apply the Unified modulator:
% apply_modulator;
total_sig2 = apply_modulator(DataFrame, filter_params);
% normalize power to unity:
P = mean(abs(total_sig2).^2); 
total_sig2 = total_sig2/sqrt(P);

if exist('preamble_signal.mat', 'file')==0
    preamble_params = configuration_input(0, filter_params.Lpreamble);
    preambles_only = apply_modulator([DataFrame(1:filter_params.Lpreamble,:); DataFrame(filter_params.N1+1:filter_params.N1+filter_params.Lpreamble,:)], preamble_params);
    preambles_only = preambles_only/sqrt(P);
    save('preamble_signal.mat', 'preambles_only', 'filter_params');
else
    load('preamble_signal.mat', 'preambles_only', 'filter_params');
end

total_sig = [total_sig1; zeros(2*filter_params.l1, 1); total_sig2];
total_sig = 0.9*total_sig/max(abs(total_sig));
total_sig = [total_sig; zeros(10000-length(total_sig),1)];

% Write signal to binary file:
fileID = fopen('tx_waveform.bin','w');
sig_to_write = zeros(2*length(total_sig), 1);
sig_to_write(1:2:end) = real(total_sig);
sig_to_write(2:2:end) = imag(total_sig);
fwrite(fileID,sig_to_write,'double');