function [CR_tx_sig CR_ofdm_data CR_ofdm_sig numOfSymbols]=mdft_filtered_ofdm_tx(h_pr, size_of_cr_data, Nfft, numOfSubchannels, cp, guard, num_cr_subCh, modRank, cr_ch_ind)

% This function uses Modified DFT filter in order to send an OFDM signal
% through the System
% h_pr: The filter to be used... Must be Perfect Reconstruction filter to
% do the job with no errors.... We will create an mdft bank
% size_of_cr_data: The amount of data to be sent by the CR (in bauds)
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



%% Creating Data

% Number of subcarriers per subchannel
NsubCh = Nfft/numOfSubchannels;

% depending on the number of CR subchannels, each subchannels takes the
% responsibility to transfer a specific number of data
size_of_ch_data = ceil(size_of_cr_data/num_cr_subCh);

% In CR_ofdm_sig we store the complete signal (all symbols) of the CR
% transmission... Each row has the signal for each subchannel
CR_ofdm_sig = zeros(num_cr_subCh,NsubCh*(1+cp)*ceil(size_of_ch_data/(NsubCh-guard)));

% In CR_ofdm_data we store the QAM symbols for each subcarrier in each 
% subchannel of the CR. Each cell of the variable contains the data
% transfered in each subchannel
CR_ofdm_data=cell(1,num_cr_subCh);

% Sequential creation (randomly) of the ofdm data and signal for each
% Cognitive Subchannels
for k=1:num_cr_subCh
    [CR_ofdm_sig(k,:) CR_ofdm_data{k}]=create_OFDM_Data(NsubCh,modRank,guard,size_of_ch_data,cp);
    
    %% this is done because the filter is centered in 0 and the OFDM signal
    %  is centered in NsubCh/2....In order to keep it like it meant to be
    CR_ofdm_sig(k,:) = CR_ofdm_sig(k,:).*exp(2*pi*1i*(0:length(CR_ofdm_sig(k,:))-1)/2); 
end

% the number of OFDM symbols needed to transfer this amount of data
numOfSymbols=size(CR_ofdm_sig,2)/NsubCh/(1+cp);

%% intialization of intermediate signal matrices

% The input signal in each of 2 filter banks (Check Fig6 in Modified DFT
% Filter Banks with Perfect Reconstruction or the Diagram in your notes)
in_sig_1=zeros(size(CR_ofdm_sig));
in_sig_2=zeros(size(CR_ofdm_sig));

% The input Signal in each bank 
CR_bank_1=zeros(numOfSubchannels,size(CR_ofdm_sig,2));
CR_bank_2=zeros(numOfSubchannels,size(CR_ofdm_sig,2));


%% Keeping real and imaginary interchangeably
% if the subchannel is even(start at 0) then 1->real 2->imag
for k=1:num_cr_subCh
    if mod(cr_ch_ind(k),2)==0
        in_sig_1(k,:)=real(CR_ofdm_sig(k,:));
        in_sig_2(k,:)=1i*imag(CR_ofdm_sig(k,:));
    else
        in_sig_1(k,:)=1i*imag(CR_ofdm_sig(k,:));
        in_sig_2(k,:)=real(CR_ofdm_sig(k,:));
    end
end

%% Multiplying with groupdelay phase change (?)
% the filtering group delay
gD=(length(h_pr)-1)/2;

% equalize the gd phase change (Fig6 of m-dft paper)
for k=1:num_cr_subCh
    CR_bank_1(cr_ch_ind(k)+1,:) = exp(-2*pi*1i*(gD)*cr_ch_ind(k)/numOfSubchannels)*in_sig_1(k,:);
    CR_bank_2(cr_ch_ind(k)+1,:) = exp(-2*pi*1i*(gD)*cr_ch_ind(k)/numOfSubchannels)*in_sig_2(k,:);
end


%% FFT
% This stage does the OFDM-type modulation in OFDM-OQAM
% terminology...Otherwise the DFT in the polyphase bank
prefilt_sig_1=numOfSubchannels*ifft(CR_bank_1,[],1);
prefilt_sig_2=numOfSubchannels*ifft(CR_bank_2,[],1);

%% Filtering

% Polyphase representation (type-1) of the filter in the Tx
h_poly=polyphaseFIR(h_pr,numOfSubchannels);

% The output signal for each bank 1 and 2 (equals the signal+ polyphase
% filter length -1)
out_sig_1=zeros(numOfSubchannels,round(2*gD/numOfSubchannels)+size(CR_ofdm_sig,2)-1);
out_sig_2=zeros(numOfSubchannels,round(2*gD/numOfSubchannels)+size(CR_ofdm_sig,2)-1);

%filtering procedure for each polyphase component
for n = 1:numOfSubchannels
    out_sig_1(n,:) = conv(h_poly(n,:), prefilt_sig_1(n,:));
    out_sig_2(n,:) = conv(h_poly(n,:), prefilt_sig_2(n,:));
end

%% The Commutator

% the parallel to serial conversion.... 
Tx_sig_1=reshape(out_sig_1,1,size(out_sig_1,1)*size(out_sig_1,2));
Tx_sig_2=reshape(out_sig_2,1,size(out_sig_2,1)*size(out_sig_2,2));

%% Offset insertion between the banks
% The output of each bank is added with a delay offset between them equal
% to numOfSubchannels/2
CR_tx_sig = [ Tx_sig_1 zeros(1,numOfSubchannels/2)]+ [zeros(1,numOfSubchannels/2) Tx_sig_2];

%% Slight modulation to move from the baseband (split spectrum at the end)
%% to the 1/numOfSubchannels/2 carrier
CR_tx_sig = CR_tx_sig.*exp(2*pi*1i*(0:length(CR_tx_sig)-1)/2/numOfSubchannels);

