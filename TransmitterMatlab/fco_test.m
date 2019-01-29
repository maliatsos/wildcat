addpath('./Tools');
addpath('./Filters');

%% Configuration of the Unified modulator (parameters):
configuration_input;

%% Create Multi-Carrier modulation data frame:
% Lpreabmle = 4 at the begining of the frame are preambles.
[DataFrame, X1, X2] = create_mc_data_frame(N1-Lpreamble, e1, Lpreamble, oqam_flag);
cc = X1 + X2;
XX = DataFrame;

% --------------------------------------------------------
%% Apply the Unified modulator:
apply_modulator;

% corr_synchronizer(RxSignal, Lpreamble, M1, 0, 0);
% % channel = [1+0.87i 0.2+0.1i 0.1+0.2i];
% channel = [0.5i-0.8i -0.2i 0.2+0.1i 0.1+0.2i 0.01i-0.01];
% 
% RxSignal = conv(RxSignal, channel);

RxSignal = [zeros(500,1); total_sig2];
apply_demodulator;
