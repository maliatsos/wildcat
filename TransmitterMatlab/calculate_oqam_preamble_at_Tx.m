function OutSignal = calculate_oqam_preamble_at_Tx(RefSignal, h1, e1, L1, Q1, M1, P, o1, bconj1, bcas1)

E1 = commutator_mtx(e1, M1);

rtmp = RefSignal*E1; RefSignal = zeros(L1*size(rtmp,1), M1);
for p = 1 : P
    R = rtmp((p-1)*round(size(rtmp,1)/P)+1: p*round(size(rtmp,1)/P), :);
    R = upsample(R,L1,o1(p));
    RefSignal(1 + (p-1)*L1*round(size(rtmp,1)/P) : (p-1)*L1*round(size(rtmp,1)/P) + size(R,1), :) = R;
end

rtmp = RefSignal; RefSignal = zeros(size(rtmp, 1)+ length(h1)-1, M1);
sig_size= round(size(rtmp,1)/P);
for p = 1 : P
    for ll = 1 : M1
        RefSignal ((p-1)*(sig_size+length(h1)-1)+1:p*(sig_size+length(h1)-1),ll) = conv(rtmp((p-1)*sig_size+1:p*sig_size,ll), h1.*exp(2i*pi*(0:length(h1)-1)*(ll-1)/M1));
    end
end

l1 = length(h1);
c1 = diag(exp(-2i*pi*(l1-1)/2/M1*(0:M1-1)*bcas1));
RefSignal = exp(1i*pi*bconj1/2)*RefSignal*c1;

rtmp = RefSignal; RefSignal = zeros(ceil(size(rtmp,1)/Q1), M1);
sig_size = ceil(size(rtmp,1)/Q1/P); sig_size2=round(size(rtmp,1)/P);
for p = 1 : P
    RefSignal(1 + (p-1)*sig_size:(p-1)*sig_size + length(rtmp(1 + (p-1)*sig_size : Q1 : p*sig_size, :)), :) = rtmp(1 + (p-1)*sig_size2 : Q1 : p*sig_size2, :);
end
E2 = ones(M1, 1);

OutSignal = RefSignal*E2;
OutSignal = OutSignal(1:length(OutSignal)/2) + OutSignal(length(OutSignal)/2+1:end);
