addpath('./Tools');
addpath('./Filters');


create_some_random_channels;
%% Configuration of the Unified modulator (parameters):
configuration_input_test;

num_tests = 1000; resultsOOB = zeros(num_tests,1); resultsUse = zeros(num_tests,1); 
for ii =1 : num_tests
    %% Create OFDM test signal:
    [DataFrame, X1, X2] = create_mc_data_frame(N1, 1:M1, 0, 0);
    DataFrame(:, M1/4+1:end-M1/4+1) = 0;
    
    ofdm_sig = (1/sqrt(M1))*ifft(DataFrame,M1,2);
    ofdm_sig = [ofdm_sig(:,end-M1/8+1:end) ofdm_sig].';
    ofdm_sig = ofdm_sig(:); tmp_length = length(ofdm_sig);
    ofdm_sig = conv(ofdm_sig, channels1(ii, :)); ofdm_sig = ofdm_sig(1:length(ofdm_sig));
    % Upsample with SINC in order to view the PSD:
%     upsamp = 2; ofdm_sig = ofdm_sig/sqrt(mean(abs(ofdm_sig).^2));
%     yp = resampleSINC(ofdm_sig,upsamp);

    yp = ofdm_sig;
    yp = yp./sqrt(mean(abs(yp).^2));
    yyp = [yp; zeros(15*length(yp), 1);];
    upsize = 16*length(ofdm_sig);
    signal_index = zeros(upsize, 1);
    signal_index(1:16*length(ofdm_sig)/4) = 1;
    signal_index(end-16*length(ofdm_sig)/4+1:end) = 1;
    
%     freq = (0:length(yyp)-1)/length(yyp);
%     plot(freq, 20*log10(abs(fft(yyp))))
    [OOB, UsefulPwr] = OOB_calculation(yyp, logical(signal_index));
    resultsOOB(ii) = OOB; resultsUse(ii) = UsefulPwr;
    if mod(ii,50)==0
        ii
    end
end
% hold all

num_tests = 1000; resultsOOB2 = zeros(num_tests,1); resultsUse2 = zeros(num_tests,1); 
for ii =1 : num_tests
    %% Create OFDM test signal:
    [DataFrame, X1, X2] = create_mc_data_frame(N1, 1:M1, 0, 0);
    DataFrame(:, M1/4+1:end-M1/4+1) = 0;
    
    ofdm_sig = (1/sqrt(M1))*ifft(DataFrame,M1,2);
    ofdm_sig = [ofdm_sig(:,end-M1/8+1:end) ofdm_sig].';
    ofdm_sig = ofdm_sig(:); tmp_length = length(ofdm_sig);
    ofdm_sig = conv(ofdm_sig, channels2(ii, :)); ofdm_sig = ofdm_sig(1:length(ofdm_sig));
    % Upsample with SINC in order to view the PSD:
%     upsamp = 2; ofdm_sig = ofdm_sig/sqrt(mean(abs(ofdm_sig).^2));
%     yp = resampleSINC(ofdm_sig,upsamp);

    yp = ofdm_sig;
    yp = yp./sqrt(mean(abs(yp).^2));
    yyp = [yp; zeros(15*length(yp), 1);];
    upsize = 16*length(ofdm_sig);
    signal_index = zeros(upsize, 1);
    signal_index(1:16*length(ofdm_sig)/4) = 1;
    signal_index(end-16*length(ofdm_sig)/4+1:end) = 1;
    
%     freq = (0:length(yyp)-1)/length(yyp);
%     plot(freq, 20*log10(abs(fft(yyp))))
    [OOB, UsefulPwr] = OOB_calculation(yyp, logical(signal_index));
    resultsOOB2(ii) = OOB; resultsUse2(ii) = UsefulPwr;
    if mod(ii,50)==0
        ii
    end
end

for ii =1 : 1
    %% Create OFDM test signal:
    [DataFrame, X1, X2] = create_mc_data_frame(N1, 1:M1, 0, 0);
    DataFrame(:, M1/4+1:end-M1/4+1) = 0;
    
    ofdm_sig = (1/sqrt(M1))*ifft(DataFrame,M1,2);
    ofdm_sig = [ofdm_sig(:,end-M1/8+1:end) ofdm_sig].';
    ofdm_sig = ofdm_sig(:); tmp_length = length(ofdm_sig);
    ofdm_sig = conv(ofdm_sig, channels2(ii+98, :)); ofdm_sig = ofdm_sig(1:length(ofdm_sig));
    % Upsample with SINC in order to view the PSD:
%     upsamp = 2; ofdm_sig = ofdm_sig/sqrt(mean(abs(ofdm_sig).^2));
%     yp = resampleSINC(ofdm_sig,upsamp);

    yp = ofdm_sig;
    yp = yp./sqrt(mean(abs(yp).^2));
    yyp = [yp; zeros(15*length(yp), 1);];
    upsize = 16*length(ofdm_sig);
    signal_index = zeros(upsize, 1);
    signal_index(1:16*length(ofdm_sig)/4) = 1;
    signal_index(end-16*length(ofdm_sig)/4+1:end) = 1;
    
     freq = (0:length(yyp)-1)/length(yyp) - 0.5;
     noise = sqrt(1/20000)*(randn(size(yyp)) + randn(size(yyp)));
     plot(freq, 20*log10(fftshift(abs(fft(yyp+noise)))))
%     [OOB, UsefulPwr] = OOB_calculation(yyp, logical(signal_index));
%     resultsOOB(ii) = OOB; resultsUse(ii) = UsefulPwr;
    if mod(ii,50)==0
        ii
    end
end
hold all
plot(freq, fftshift(50*signal_index))