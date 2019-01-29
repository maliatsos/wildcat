function [Xout Xsymbols Xofdm] =create_OFDM_Data(Nfft,modRank,guard,sizeOfData,cp)

X=randint(1,sizeOfData,modRank);

if modRank==2 || modRank==4
    X=pskmod(X,modRank);
elseif modRank==8
    X=qamMapper(X,modRank,'Rectangular');
elseif modRank>8
    X=qamMapper(X,modRank,'Symmetrical');
end

numOfSymbols=ceil(sizeOfData/(Nfft-guard));
X=[X zeros(1,Nfft-guard-mod(sizeOfData,(Nfft-guard)))];

Xsymbols=zeros(numOfSymbols,Nfft);
for k=1:numOfSymbols
    Xsymbols(k,:)=[zeros(1,fix(guard/2)) X(1+(k-1)*(Nfft-guard):k*(Nfft-guard)) zeros(1,fix(guard/2)+mod(guard,2))];
end
Xofdm=ifft(Xsymbols,[],2);

%% insert the cyclic prefix
Xofdm=[Xofdm(:,end-cp*Nfft+1:end) Xofdm];

Xout= reshape(Xofdm.',1,numOfSymbols*Nfft*(1+cp));
