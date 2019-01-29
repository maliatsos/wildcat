function receiver(RxSignal, filter_params, preambles_only, ofdm_params)

%% OFDM Synchronization:
[ofdm_sync_point, ferr] = ofdm_synchronizer(RxSignal, ofdm_params);
% based on the OFDM Synchronization, the waveform synchronization point should be in:
sync_point_est = ofdm_sync_point + ofdm_params.N*ofdm_params.L + ofdm_params.Ncp + 2*filter_params.l1;

%% Compensate the frequency offset:
RxSignal = RxSignal.*exp(-2i*pi*(0:length(RxSignal)-1).'*ferr/ofdm_params.Fs);

dc_offset = mean(RxSignal(ofdm_sync_point: ofdm_sync_point+ofdm_params.N*ofdm_params.L + ofdm_params.Ncp-1));
RxSignal = RxSignal - dc_offset;
%% OFDM channel estimation:
ofdm_channel_estimate = ofdm_channel_estimator(RxSignal(ofdm_sync_point:ofdm_sync_point-1+ofdm_params.N*ofdm_params.L+ofdm_params.Ncp), ofdm_params);
x = mean(ifftshift(ifft(ofdm_channel_estimate)));

%% Waveform processing:
sync_point = generic_synchronizer(RxSignal, preambles_only, filter_params.Lpreamble, filter_params.M1, filter_params.l1);
% Synchronize:
RxSignal = RxSignal(sync_point:end);

%% Generic Equalizer:
chan_length =  filter_params.M1;
% channel_estimate = generic_estimator(RxSignal, preambles_only, chan_length, filter_params.l1);

xx = RxSignal(129:160); pre = preambles_only(129:160);
cc1 = fft(xx)./fft(pre);
cc2 = fft(RxSignal(161:192))./fft(preambles_only(161:192));

channel_estimate = ifft(cc1);
RxSignal = [zeros(filter_params.l1, 1); RxSignal]; flag = true;
EqualizedSignal = zeros(size(RxSignal)); start_point = 1; end_point = 4*filter_params.M1;

while flag
    tmp = generic_equalizer(RxSignal, channel_estimate, start_point, end_point);
    EqualizedSignal(start_point+filter_params.M1:end_point) = tmp(filter_params.M1+1:end);
    start_point = start_point + filter_params.M1;
    end_point = start_point -1 + 2*filter_params.M1; 
    if end_point > length(RxSignal)
        flag = false;
    end
end
EqualizedSignal = EqualizedSignal(filter_params.l1-filter_params.M1+1:end); 

%% Apply the Unified de-modulator:
apply_demodulator_test(EqualizedSignal, filter_params);

