function P=crosscorr_synchronizer(signal, ref_signal)

% Cross-correlation synchronization:
% prefix: Cyclic prefix or Zero prefix (if any)
% suffix: Cyclic suffix or Zero suffix (if any)
L = length(ref_signal);
P = zeros(length(signal)-L, 1);
for mm = 1 : length(P)
    P(mm) = sum(conj(ref_signal).*signal(mm:mm-1+L)); 
end