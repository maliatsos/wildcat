function C = cyclic_extension_mtx(N, Ncp, Nzp, Ncs, Nzs)

C1 = zeros(Nzp, N);
C21 = zeros(Ncp, N-Ncp);
C22 = eye(Ncp);
C3 = eye(N);
C41 = eye(Ncs);
C42 = zeros(Ncs, N-Ncs);
C5 = zeros(Nzs, N);

C = [C1; C21 C22; C3; C41 C42; C5];