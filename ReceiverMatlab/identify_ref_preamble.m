function R = identify_ref_preamble(signal, Nref, Lref, pattern_ref)

R = zeros(length(signal)-Lref*Nref, Lref);
% Identify the preamble reference signal:

sig = zeros(Nref,Lref);
for ii=1:length(signal)-Lref*Nref 
    for jj = 1 : Lref
        sig(:,jj) = signal(ii+(jj-1)*Nref:jj*Nref+ii-1);
    end
    
    for jj = 1 : Lref
        for kk = 1 : Lref
            if (kk+jj-1<=Lref)
                R(ii,jj) = R(ii,jj) + pattern_ref(kk)*pattern_ref(kk+jj-1)*sig(:,kk)'*sig(:,kk+jj-1);
            end
        end
    end
end