%% DOULEVEI!!!!!!!!!!!!!!!!!!!!!!!!!!!!

clear all
close all
clc
%% Simple OQAM

%% initialization
load('pr_filt_4_8_0.175_1e-010_1e-016_2.2204e-016.mat')
h_pr=h_pr/sqrt(2*M)/2;
clear M e_ps tol_1 tol_2 Fstop theta_2 max_iter2


% Modulation Rank
modRank=4;
% Guard subs in each subchannel? guard is total. guard/2 in each ch.side
guard=0;
% Size of Data
sizeOfData=8*16;
% number of Subchannels
numOfSubchannels=8;

%% modulating the filter by half....
% h_pr=h_pr.*exp(2*pi*1i*(-length(h_pr)/2+1/2:length(h_pr)/2-1/2)/numOfSubchannels/2);

%% Creating Data
Nfft=16;
cp=0.25;
guard=0;
sizeOfChData=ceil(sizeOfData/numOfSubchannels);

X=zeros(numOfSubchannels,Nfft*(1+cp)*ceil(sizeOfChData/(Nfft-guard)));
for k=1:numOfSubchannels
    [X(k,:) Xsymbols(k,:)]=create_OFDM_Data(Nfft,modRank,guard,sizeOfChData,cp);
end
numOfSymbols=size(X,2)/Nfft/(1+cp);


X1=zeros(size(X));
X2=zeros(size(X));
in_sig1=zeros(size(X));
in_sig2=zeros(size(X));

%% Keeping real and imaginary enallaks
for k=1:2:numOfSubchannels
    X1(k,:)=real(X(k,:));
    X2(k,:)=1i*imag(X(k,:));
end
for k=2:2:numOfSubchannels
    X1(k,:)=1i*imag(X(k,:));
    X2(k,:)=real(X(k,:));
end
X1(2:8,:)=0;
X2(2:8,:)=0;
%% Multiplying with groupdelay phase change (?)
gD=(length(h_pr)-1)/2;
for k=0:numOfSubchannels-1
    in_sig1(k+1,:) = exp(-2*pi*1i*(gD)*k/numOfSubchannels)*X1(k+1,:);
    in_sig2(k+1,:) = exp(-2*pi*1i*(gD)*k/numOfSubchannels)*X2(k+1,:);
end

%% FFT
prefilt_sig1=numOfSubchannels*ifft(in_sig1,[],1);
prefilt_sig2=numOfSubchannels*ifft(in_sig2,[],1);

%% Filtering
h_poly=polyphaseFIR(h_pr,numOfSubchannels);

out_sig1=zeros(numOfSubchannels,round(2*gD/numOfSubchannels)+size(X,2)-1);
out_sig2=zeros(numOfSubchannels,round(2*gD/numOfSubchannels)+size(X,2)-1);
for n = 1:numOfSubchannels
    out_sig1(n,:) = conv(h_poly(n,:), prefilt_sig1(n,:));
    out_sig2(n,:) = conv(h_poly(n,:), prefilt_sig2(n,:));
end

%% Commutator

Tx_sig1=reshape(out_sig1,1,size(out_sig1,1)*size(out_sig1,2));
Tx_sig2=reshape(out_sig2,1,size(out_sig2,1)*size(out_sig2,2));

Tx_sig= [ Tx_sig1 zeros(1,numOfSubchannels/2)]+ [zeros(1,numOfSubchannels/2) Tx_sig2];

%% Receiver
In_sig1 = [Tx_sig zeros(1,numOfSubchannels/2)];
In_sig2 = [zeros(1,numOfSubchannels/2) Tx_sig];


%% Rx filtering
r_poly=polyphaseFIR2ndType(h_pr,numOfSubchannels);
Rx_sig1=zeros(numOfSubchannels,size(In_sig1,2)/numOfSubchannels+size(r_poly,2)-1);
Rx_sig2=zeros(numOfSubchannels,size(In_sig2,2)/numOfSubchannels+size(r_poly,2)-1);
final_sig1=zeros(size(Rx_sig1));
final_sig2=zeros(size(Rx_sig2));

for n = 1:numOfSubchannels
    Rx_sig1(n,:) = numOfSubchannels*conv(r_poly(n,:), In_sig1(n:numOfSubchannels:end));
    Rx_sig2(n,:) = numOfSubchannels*conv(r_poly(n,:), In_sig2(n:numOfSubchannels:end));
end
z_sig1=fft(Rx_sig1,[],1);
z_sig2=fft(Rx_sig2,[],1);

for k=0:2:numOfSubchannels-1
    final_sig1(k+1,:) = real(exp(2*pi*1i*(gD)*k/numOfSubchannels)*z_sig1(k+1,:));
    final_sig2(k+1,:) = 1i*imag(exp(2*pi*1i*(gD)*k/numOfSubchannels)*z_sig2(k+1,:));
end
for k=1:2:numOfSubchannels-1
    final_sig1(k+1,:) = 1i*imag(exp(2*pi*1i*(gD)*k/numOfSubchannels)*z_sig1(k+1,:));
    final_sig2(k+1,:) = real(exp(2*pi*1i*(gD)*k/numOfSubchannels)*z_sig2(k+1,:));
end
final_sig=final_sig1(:,1:end-1)+final_sig2(:,2:end);

%% plain OFDM signal 
Xofdm = Xsymbols(1,:);
Xofdm = circshift([Xofdm zeros(1,7*Nfft)].',-7).';
x_ofdm=ifft(Xofdm);

