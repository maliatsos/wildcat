function X=qamMapper(Data,modRank,strin)

% strin input concerns ONLY the odd-rank modulations
% it can be either 'Symmetrical' or 'Rectangular'
if ~strcmp(strin,'Symmetrical') && ~strcmp(strin,'Rectangular')
    error('strin must be either "Symmetrical" or "Rectangular"');
end

N=length(Data);
% Data: contains integer numbers from zero to modRank-1... 
if max(Data)>modRank-1 || min(Data)<0 || (sum(round(Data)==Data))~=N
    error('Data must be integer between zero and modRank')
end

%% Data from decimal to Binary

% Data may not contain the full number of bits represented in given
% modulation.. To ensure that the representation will contain log2(modRank)
% bits we add the maximum value at the end...and later we delete it
Data=[Data modRank-1];
y=dec2bin(Data);
y=y(1:end-1,:);


%% Due to the fact that binaries are saved as strings --> back to numbers
b=zeros(N,log2(modRank));
for k=log2(modRank):-1:1
    b(:,k)=str2num(y(:,k));
end


% tmp=rem(Data,modRank);
% 
% %% If even then ... Rectangular... want it or not
% if tmp==0
%     strin='Rectangular';
% end

%% we reshape data into a stream of bits
Data=reshape(b',1,N*log2(modRank));

%% definition of Bits per Symbol
bitsPsym=log2(modRank);

% %% add zeros (i don't remember why... :p )
% if tmp~=0
%     Data=[Data zeros(1,tmp)];
% end

%% I and Q component for each symbol... Contains a value -not bits
I=zeros(1,size(b,1));
Q=zeros(1,size(b,1));

%% if odd rank we add a virtual bit to make constallation...
if rem(bitsPsym,2)==0
    virBitsPsym=bitsPsym;
else
    virBitsPsym=bitsPsym+1;
end
%% If even then ... Rectangular... want it or not
if rem(bitsPsym,2)==0
    strin='Rectangular';
end

%% coefficients for the definition of the constallation
weights=2.^(0:(virBitsPsym)/2-1);

%% Procedure to create the constallation
i=1;
for k=1:bitsPsym:length(Data)
    
    %% data contains info in bits
    data=Data(k:k-1+bitsPsym);
    %% pskdata contains info in bpsk (-1,1)
    pskdata=data;
    pskdata(data==0)=-1;

    bits=zeros(2,ceil(virBitsPsym/2));
    psk=-ones(2,ceil(virBitsPsym/2));
    bits(1,:)=data(1:ceil(bitsPsym/2));
    bits(2,1:length(data(ceil(bitsPsym/2)+1:bitsPsym)))=data(ceil(bitsPsym/2)+1:bitsPsym);
    psk(1,:)=pskdata(1:ceil(bitsPsym/2));
    psk(2,1:length(data(ceil(bitsPsym/2)+1:bitsPsym)))=pskdata(ceil(bitsPsym/2)+1:bitsPsym);
    
    if rem(bitsPsym,2)==0
        n=bitsPsym/2-1;
    else
        n=floor(bitsPsym/2);
    end
    
    if bitcmp(bits(1,n),1)&& bits(1,n+1) && bits(2,n) && strcmp(strin,'Symmetrical')
        bits(1,n)=bitcmp(bits(1,n),1);
        bits(1,n+1)=bitcmp(bits(1,n+1),1);
        bits(2,n+1)=bitcmp(bits(2,n+1),1);
        psk(1,n)=-psk(1,n);
        psk(1,n+1)=-psk(1,n+1);
        psk(2,n+1)=-psk(2,n+1);
    elseif bitcmp(bits(1,n),1)&& bits(1,n+1) && bitcmp(bits(2,n),1) && strcmp(strin,'Symmetrical')
        bits(2,n)=bitcmp(bits(2,n),1);
        bits(1,n+1)=bitcmp(bits(1,n+1),1);
        bits(2,n+1)=bitcmp(bits(2,n+1),1);
        psk(2,n)=-psk(2,n);
        psk(1,n+1)=-psk(1,n+1);
        psk(2,n+1)=-psk(2,n+1);
    end

    for k=size(bits,2):-1:2
        I(i)=I(i)+weights(k-1).*psk(1,k).*((-1).^(sum(bits(1,size(bits,2):-1:k+1))));
        Q(i)=Q(i)+weights(k-1).*psk(2,k).*((-1).^(sum(bits(2,size(bits,2):-1:k+1))));
    end
    I(i)=-weights(end).*psk(1,1)+(-psk(1,1)).*(I(i));
    Q(i)=-weights(end).*psk(2,1)+(-psk(2,1)).*(Q(i));
    i=i+1;
end

%% Output ... complex sum of I and Q
X=I+j*Q;


%% If you want to do the scatterplot...uncomment
% scatterplot(X);
% hold all
% for i=1:size(b,1)
%     cc=mat2str(b(i,:));
%     text(real(X(i))-0.075,imag(X(i))+0.05,cc(2:length(b(i,:))+6),'Fontsize',5);
% end