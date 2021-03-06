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
% add some zeros
RxSignal = [zeros(500,1); total_sig];
ferr = 800;
RxSignal = RxSignal.*exp(2i*pi*(0:length(RxSignal)-1).'*ferr/Fs);

%% Apply the channel:
channel = [0.5-0.8i -0.2i 0.2+0.1i 0.1+0.2i 0.01i-0.01];
RxSignal = conv(channel, RxSignal);

%% Receiver:
receiver(RxSignal, filter_params, preambles_only, ofdm_params);
