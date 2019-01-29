function [CR_rx_sig cr_ofdm_out]=mdft_filtered_ofdm_rx(h_pr,CR_sig , Nfft, numOfSubchannels, cp)

%% Receiver
% This function uses Modified DFT filter in order to receive an OFDM signal
% through the System
% h_pr: The filter to be used... Must be Perfect Reconstruction filter to
% do the job with no errors.... We will create an mdft bank
% CR_sig: The received signal (not only cognitive but anything....)
% Nfft: the whole available channel subcarrier size
% numOfSubchannels: The subchannels that divide the channel
% cp: The cyclic prefix percentage
% guard: the guard subcarriers in each subchannel
% num_cr_subCh: The number of Subchannels occupied by the CR
% modRank: the modulation rank for QAM symbols (4=QPSK)
% cr_ch_ind is a vector of 1x num_cr_subCh with the indexes of the CR
% subchannels (0:numOfSubchannles -1)

% In this scheme, the signal is divided in the real and imaginary part and
% it is transmitted with a filter offset(=M=numOfSubchannels/2). This trick
% ensures that data will be transmitted orthogonally in time and frequency.

% Number of subcarriers per subchannel
NsubCh = Nfft/numOfSubchannels;

%% Slight demodulation to move from the the 1/numOfSubchannels/2 carrier to
%% baseband (split spectrum at the end)
%% to 
CR_sig = CR_sig.*exp(-2*pi*1i*(0:length(CR_sig)-1)/2/numOfSubchannels);

%% Seperation in the two banks
% the signal is lead to the two banks... In the second bank it comes
% delayed by M = numOfSubchannels/2 (Fig6 - mdft paper)
In_sig_1 = [CR_sig zeros(1,numOfSubchannels/2)];
In_sig_2 = [zeros(1,numOfSubchannels/2) CR_sig];


%% Commutation, decimation and Rx filtering

% Polyphase filter decomposition of 2nd Type (Type 2 polyphase)
r_poly=polyphaseFIR2ndType(h_pr,numOfSubchannels);

% initialization of the vectors which will store the signal after filtering
filt_sig_1=zeros(numOfSubchannels,size(In_sig_1,2)/numOfSubchannels+size(r_poly,2)-1);
filt_sig_2=zeros(numOfSubchannels,size(In_sig_2,2)/numOfSubchannels+size(r_poly,2)-1);

% initialization of the vectors which will store the final signal after
% filtering for each bank
final_sig_1=zeros(size(filt_sig_1));
final_sig_2=zeros(size(filt_sig_2));

% Commutation-Decimation (by numOfSubchannels) and filtering of the signal
for n = 1:numOfSubchannels
    filt_sig_1(n,:) = numOfSubchannels*conv(r_poly(n,:), In_sig_1(n:numOfSubchannels:end));
    filt_sig_2(n,:) = numOfSubchannels*conv(r_poly(n,:), In_sig_2(n:numOfSubchannels:end));
end

%% FFT
% This stage does the OFDM-type modulation in OFDM-OQAM
% terminology...Otherwise the DFT in the polyphase bank
fft_sig_1=fft(filt_sig_1,[],1);
fft_sig_2=fft(filt_sig_2,[],1);

%% Multiplying with groupdelay phase change (?)
% the filtering group delay
gD=(length(h_pr)-1)/2;

% equalize the gd phase change (Fig6 of m-dft paper)
for k=0:2:numOfSubchannels-1
    final_sig_1(k+1,:) = real(exp(2*pi*1i*(gD)*k/numOfSubchannels)*fft_sig_1(k+1,:));
    final_sig_2(k+1,:) = 1i*imag(exp(2*pi*1i*(gD)*k/numOfSubchannels)*fft_sig_2(k+1,:));
end
for k=1:2:numOfSubchannels-1
    final_sig_1(k+1,:) = 1i*imag(exp(2*pi*1i*(gD)*k/numOfSubchannels)*fft_sig_1(k+1,:));
    final_sig_2(k+1,:) = real(exp(2*pi*1i*(gD)*k/numOfSubchannels)*fft_sig_2(k+1,:));
end

%% The final signal occures as the summation of the 1-bank output and
% 2-bank output (throw away the first sample because of the total delay
% induced by the procedure in 2-bank
CR_rx_sig=final_sig_1(:,1:end-1)+final_sig_2(:,2:end);

%% OFDM Demodulation
cr_ofdm_out = cell(1, numOfSubchannels);
time_sync_offset = (2*gD+1)/numOfSubchannels + cp*NsubCh -1;
for k = 1:numOfSubchannels
    %% this is done because the filter is centered in 0 and the OFDM signal
    % is centered in NsubCh/2....In order to keep it like it meant to be
    CR_rx_sig(k,:) = CR_rx_sig(k,:).*exp(-2*pi*1i*(0:length(CR_rx_sig(k,:))-1)/2);
    cr_ofdm_out{k} = ofdm_rx(CR_rx_sig(k,:), NsubCh, cp, time_sync_offset);
end

