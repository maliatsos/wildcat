function [Xout Xsymbols Xofdm] = ofdma_tx(size_of_data, Nfft, cp, modRank, guard, numOfSubchannels, subCh_ind)

NsubCh = Nfft/numOfSubchannels;
samples_per_subchannel = length(subCh_ind)*NsubCh;

%% Create QAM data
X=randint(1,size_of_data,modRank);

if modRank==2 || modRank==4
    X=pskmod(X,modRank);
elseif modRank==8
    X=qamMapper(X,modRank,'Rectangular');
elseif modRank>8
    X=qamMapper(X,modRank,'Symmetrical');
end

%% identify the number of symbols needed for given data size
% The num of symbols is given by the size of data to the subcarriers used
% from the user to each symbol...If not perfect divide add one symbol with
% remaining data se to zero....
numOfSymbols=ceil(size_of_data/(samples_per_subchannel-guard));
X=[X zeros(1,samples_per_subchannel-guard-mod(size_of_data,(samples_per_subchannel-guard)))];


Xsymbols=zeros(numOfSymbols,Nfft);
counter = 0;
for k=1:numOfSymbols
    for m = 1: length(subCh_ind)
        Xsymbols(k,subCh_ind(m)*NsubCh+1:(subCh_ind(m)+1)*NsubCh)=[zeros(1,fix(guard/2)) X(1+counter:counter + (NsubCh-guard)) zeros(1,fix(guard/2)+mod(guard,2))];
        counter = counter + NsubCh-guard ;
    end
end
Xofdm=ifft(Xsymbols,[],2);
%% insert the cyclic prefix
Xofdm=[Xofdm(:,end-cp*Nfft+1:end) Xofdm];

Xout= reshape(Xofdm.',1,numOfSymbols*Nfft*(1+cp));




