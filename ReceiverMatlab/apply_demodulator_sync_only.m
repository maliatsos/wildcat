%% Apply Demodulator:

% First Rx (Third Tx) CP tier:
sampl_offset = -1; % Aligns the sampling between the synthesis and analysis band

% corr_synchronizer(RxSignal, Lpreamble, M1, 0, 0);
% channel = [1+0.87i 0.2+0.1i 0.1+0.2i];
channel = [0.5i-0.8i -0.2i 0.2+0.1i 0.1+0.2i 0.01i-0.01];

RxSignal = conv(RxSignal, channel);

%---------------------------------------------------------
%% Used for Equlization - Manipulation of Reference Signals:
RefSignal = [XX(1:Lpreamble, :); XX(N1+1:N1+Lpreamble, :)];
InSignal = calculate_oqam_preamble_at_Tx(RefSignal, h1, e1, L1, Q1, M1, P, o1, bconj1, bcas1);
OutSignal = calculate_oqam_preamble_at_Rx(RefSignal, h1, e1, L1, Q1, M1, P, o1, bconj1, bcas1, sampl_offset);
%----------------------------------------------------------
%% Synchronizer:
P = crosscorr_synchronizer(RxSignal, InSignal);
[PP,RR] = corr_synchronizer(RxSignal, Lpreamble, M1, 0, 0);
[~,sync_point] = max(abs(PP(1:length(P))).*abs(P));

sync_point
errorss = [errorss sync_point-501];