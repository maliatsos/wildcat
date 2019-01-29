addpath('./Tools');
addpath('./Filters');

%% Configuration of the Unified modulator (parameters):
configuration_input_test;
create_some_random_channels;
num_tests = 20;

resultsOOB = zeros(num_tests, 1); resultsUse = zeros(num_tests, 1);
for ii = 1 : num_tests
    %% Create Multi-Carrier modulation data frame:
    % Lpreabmle = 4 at the begining of the frame are preambles.
    [DataFrame, X1, X2] = create_mc_data_frame(N1-Lpreamble, e1, Lpreamble, oqam_flag);
    cc = X1 + X2;
    XX = DataFrame;
    
    % --------------------------------------------------------
    %% Apply the Unified modulator:
    apply_modulator;
    total_sig2 = conv(total_sig2, channels1(ii,:));
    
    % %---------------------------------------------------------
    % % Upsample with SINC in order to view the PSD:
    % upsamp = 2; total_sig2 = total_sig2/sqrt(mean(abs(total_sig2).^2));
    % yp = resampleSINC(total_sig2,upsamp);
    yp = [total_sig2; 0];
    yp = yp./sqrt(mean(abs(yp).^2));
    yyp = [yp; zeros(15*length(yp), 1);];
    upsize = 16*length(yp);
    signal_index = zeros(upsize, 1);
    signal_index(1:16*length(yp)/4) = 1;
    signal_index(end-16*length(yp)/4+1:end) = 1;
    
    [OOB, UsefulPwr] = OOB_calculation(yyp, logical(signal_index));
    resultsOOB(ii) = OOB;
    resultsUse(ii) = UsefulPwr;
end

freq = (0:length(yyp)-1)/length(yyp);
noise = sqrt(1/20000)*(randn(size(yyp)) + randn(size(yyp)));
plot(freq, 20*log10(fftshift(abs(fft(yyp+noise)))));
hold all
plot(freq, fftshift(50*signal_index))