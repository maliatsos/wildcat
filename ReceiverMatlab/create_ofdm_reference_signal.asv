function rep_sig = create_ofdm_reference_signal(Nref, Lref, pattern_ref)

% Create random preamble - if exist do not do anything:
if exist('ofdm_preamble.mat', 'file')>0
    load('ofdm_preamble.mat');
else 
    guard = 32;
    allocation = ones(Nref,1); allocation(1) = 0; allocation(Nref/2-guard+1:Nref/2+guard) = 0;
    REF_sig = zeros(Nref,1); 
    REF_sig(logical(allocation)) = qammod(randi([0,3], sum(allocation), 1), 4);
    ref_sig = (Nref/sqrt(sum(allocation))/sqrt(2))*ifft(REF_sig, Nref);
    save('ofdm_preamble.mat', 'ref_sig', 'Nref', 'Lref', 'pattern_ref');
end

rep_sig = zeros(Lref*size(ref_sig,1), 1);
for ll = 1 : Lref
    rep_sig((ll-1)*Nref + 1: ll*Nref) = pattern_ref(ll)*ref_sig;
end


