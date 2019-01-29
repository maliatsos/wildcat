clear all
close all
clc
%% Simple OQAM

%% initialization
% Modulation Rank
modRank=4;
% Guard subs in each subchannel? guard is total. guard/2 in each ch.side
guard=0;
% Size of Data
sizeOfData=128;
% number of Subchannels
numOfSubchannels=8;


%% Creating Data
X=create_OQAM_Data(numOfSubchannels, sizeOfData, modRank);
numOfSymbols=size(X,1);

%% Filter initialization and Creation
Ncoef=120; % nummber of coefficients
Fnyq=1/numOfSubchannels; % Nyq frequency
RollOff=0.05; % rolloff factor
DT='sqrt'; % type of Nyquist filter, either Normal either sqrt

Num = filter_creation(Ncoef,Fnyq,RollOff,DT);

%% modulating the filter to center it in the first subchannels
% Num=Num.*exp(j*2*pi*(0:length(Num)-1)/2/numOfSubchannels);

%% Breaking real/imag for OQAM filtering and transimission
Xoqam=zeros(numOfSymbols,2*size(X,2));
for n=1:numOfSymbols
    if mod(n,2)~=0
        Xoqam(n,1:2:end)=real(X(n,:));
        Xoqam(n,2:2:end)=j*imag(X(n,:));
    else
        Xoqam(n,1:2:end)=j*imag(X(n,:));
        Xoqam(n,2:2:end)=real(X(n,:));
    end
end
Xoqam(1,:)=0;
Xoqam(3:numOfSymbols,:)=0;

%% OFDM-OQAM Modulation
Xoqam2=fft(Xoqam,[],1);
h_poly=polyphaseFIR([ 0 0 0 0 0 0 Num],numOfSubchannels);

for n=1:numOfSubchannels
    Y(n,:)=conv(h_poly(n,:),Xoqam2(n,:));
end
Yfinal=upsample(Y.',numOfSubchannels).';

Ytotal=zeros(1,numOfSubchannels+size(Yfinal,2));
for n=1:numOfSubchannels
    Ytotal(n:size(Yfinal,2)+n-1)=Ytotal(n:size(Yfinal,2)+n-1)+Yfinal(n,1:end);
end

%-------------------------------------
%% Receiver
%-------------------------------------

%% Commutating the input
Z=Yfinal;
% Z=zeros(numOfSubchannels,size(Ytotal,2));
% 
% for n=1:numOfSubchannels
%     Z(n,1:end-n+1)=Ytotal(n:end);
% end

%% Decimating the input
Zdec=zeros(numOfSubchannels,ceil(size(Z,2)/numOfSubchannels));
for n=1:numOfSubchannels
    Zdec(n,:)=Z(n,1:numOfSubchannels:end);
end

%% Filtering 
Znew=zeros(numOfSubchannels,size(Zdec,2)+size(h_poly,2)-1);
for n=1:numOfSubchannels
    Znew(n,:)=conv(Zdec(n,:),upsample(h_poly(n,:),1));
end
Znew=Zdec;
%% demod ifft

Znew2=ifft(Znew,[],1);

