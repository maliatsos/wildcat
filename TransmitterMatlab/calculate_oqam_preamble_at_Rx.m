function OutSignal = calculate_oqam_preamble_at_Rx(RefSignal, h1, e1, L1, Q1, M1, P, o1, bconj1, bcas1, sampl_offset)

InSignal = calculate_oqam_preamble_at_Tx(RefSignal, h1, e1, L1, Q1, M1, P, o1, bconj1, bcas1);
% InSignal = InSignal/max(abs(InSignal));
if sampl_offset>=0
    InSignal = [zeros(sampl_offset,1); InSignal(1:end-1)];
else
    InSignal = [InSignal(-sampl_offset:end); zeros(-sampl_offset,1)];
end

E1 = ones(1, M1);

rtmp = InSignal*E1; RefSignal = zeros(size(rtmp, 1)+ length(h1)-1, M1);
for ll = 1 : M1
    RefSignal (:,ll) = conv(rtmp(:,ll), h1.*exp(2i*pi*(0:length(h1)-1)*(ll-1)/M1));
end

l1 = length(h1);
c1 = diag(exp(-2i*pi*(l1-1)/2/M1*(0:M1-1)*bcas1));
RefSignal = exp(1i*pi*bconj1/2)*RefSignal*c1;

% Careful... OutSignal is not downsampled
OutSignal = RefSignal;