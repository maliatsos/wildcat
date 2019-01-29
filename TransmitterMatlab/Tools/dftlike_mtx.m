function F = dftlike_mtx(Nc, M, bconj)

F = zeros(Nc, M);
for nn = 1 : Nc
    for mm = 1 : M
        F(nn,mm) = exp(2i*pi*((-1)^(bconj)*(nn-1)*(mm-1)/M));
    end
end