num_tests = 20;
fnames = {'beaulieu_bands64_coefs128_alpha0.35.mat';
    'beaulieu_bands64_coefs256_alpha0.35.mat';
    'dirichlet_bands64_coefs128.mat';
    'dirichlet_bands64_coefs256.mat';
    'double_jump_band64_coefs128_a0.5.mat';
    'double_jump_band64_coefs256_a0.5.mat';
    'gaussian_band64_coefs128_a0.35.mat';
    'gaussian_band64_coefs256_a0.35.mat';
    'mdft_iter_filt_64_64_fstop0.023438.mat';
    'mdft_iter_filt_64_128_fstop0.023438.mat';
    'pr_filt_64_1_0.015625_1e-06_1e-06_2.2204e-16.mat';
    'phydias64.mat'
    }
num_filters = length(fnames);

resultsOOB = zeros(num_tests, num_filters);
resultsUSE = zeros(num_tests, num_filters);

for kk = 1 : num_filters
    fname = fnames{kk};
    for mm = 1 : num_tests
        
        %% Configuration of the Unified modulator (parameters):
        custom_configuration_input;
        
        %% Create Reference OFDM signal for synchronization (time/frequency) reference:
        
        %% Create Multi-Carrier modulation data frame:
        [DataFrame, X1, X2] = create_mc_data_frame(N1-Lpreamble, e1, Lpreamble, oqam_flag);
        cc = X1 + X2;
        XX = DataFrame; XX(:,M1/2) = 0; % Zeroing the outer channel.
        
        % --------------------------------------------------------
        %% Apply the Unified modulator:
        apply_modulator;
        
        %% Normalize amplitude for USRP
        target_max_output_ampl = 0.9;
        [total_sig2, Pavg] = normalize_for_usrp(total_sig2, target_max_output_ampl);
        
        % Target SNR:
        SNR = 700; noise_pwr = Pavg/10^(SNR/10);
        
        sync_point = 1;
        RxSignal = sqrt(1/2*noise_pwr)*(randn(size(total_sig2,1)+sync_point+50, size(total_sig2,2)) + 1i*randn(size(total_sig2,1)+sync_point+50, size(total_sig2,2)));
        RxSignal(sync_point+1:sync_point+length(total_sig2)) = RxSignal(sync_point+1:sync_point+length(total_sig2)) + total_sig2;
        
%         ---------------------------------------------------------
%         Upsample with SINC in order to view the PSD:
        upsamp = 4;
        yp = resampleSINC(RxSignal,upsamp);
        
        normalized_freq_stop = (M1/2-1)/(upsamp*M1);
        normalized_freq_start = (-M1/2+1)/(upsamp*M1);
        [OOB, UsefulPwr] = OOB_calculation(yp(sync_point*upsamp+1:end), normalized_freq_start, normalized_freq_stop);
        resultsOOB(mm, kk) = OOB;
        resultsUSE(mm, kk) = UsefulPwr;

    end
    mean(resultsOOB(:,1)./resultsUSE(:,1))
   keyboard
end
