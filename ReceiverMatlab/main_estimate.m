clear all
addpath('./Tools');
addpath('./Filters');

err = [];
for pp = 1 : 10
    
    %% Configuration of the Unified modulator (parameters):
    configuration_input;
    
    %% Create Reference OFDM signal for synchronization (time/frequency) reference:
    % script_ofdm_reference_signal;
    
    %% Create Multi-Carrier modulation data frame:
    % Lpreabmle = 4 at the begining of the frame are preambles.
    [DataFrame, X1, X2] = create_mc_data_frame(N1-Lpreamble, e1, Lpreamble, oqam_flag);
    cc = X1 + X2;
    XX = DataFrame; XX(:,M1/2) = 0; % Zeroing the outer channel.
    
    % --------------------------------------------------------
    %% Apply the Unified modulator:
    apply_modulator;
    
    %% Normalize amplitude for USRP
%     target_max_output_ampl = 0.9;
%     [total_sig2, Pavg] = normalize_for_usrp(total_sig2, target_max_output_ampl);
    Pavg = mean(abs(total_sig2).^2);

    % Target SNR:
    SNR = 700; noise_pwr = Pavg/10^(SNR/10);
    
    sync_point = 500;
    RxSignal = sqrt(1/2*noise_pwr)*(randn(size(total_sig2,1)+sync_point+50, size(total_sig2,2)) + 1i*randn(size(total_sig2,1)+sync_point+50, size(total_sig2,2)));
    RxSignal(sync_point+1:sync_point+length(total_sig2)) = RxSignal(sync_point+1:sync_point+length(total_sig2)) + total_sig2;
    
    %---------------------------------------------------------
    % Upsample with SINC in order to view the PSD:
%     upsamp = 2;
%     yp = resampleSINC(RxSignal,upsamp);
    
%     normalized_freq_stop = (M1/2-1)/(upsamp*M1);
%     normalized_freq_start = (-M1/2+1)/(upsamp*M1);
%     OOB = OOB_calculation(yp(sync_point*upsamp+1:end), normalized_freq_start, normalized_freq_stop);
    
    
    apply_demodulator_estimate;
end