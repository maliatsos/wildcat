function E = commutator_mtx(e, M)

% elements of e indexed one-based.

Mprime = length(e);
E = zeros(Mprime, M);

for kk = 1 : Mprime
   E(kk, e(kk)) = 1; 
end
