function total_sig2 = apply_modulator(DataFrame, filter_params)
h1 =filter_params.h1;
h2 =filter_params.h2;
M1 = filter_params.M1;
M2 = filter_params.M2;
L1 = filter_params.L1;
L2 = filter_params.L2;
Q1 = filter_params.Q1;
Q2 = filter_params.Q2;
o1 = filter_params.o1;
o2 = filter_params.o2;
N1 = filter_params.N1;
l1 = filter_params.l1;
l2 = filter_params.l2;
P = filter_params.P;
oqam_flag = filter_params.oqam_flag;
Ncp1 = filter_params.Ncp1;
Ncp2 = filter_params.Ncp2;
Ncp3 = filter_params.Ncp3;
Ncs1 = filter_params.Ncs1;
Ncs2 = filter_params.Ncs2;
Ncs3 = filter_params.Ncs3;
Nzp1 = filter_params.Nzp1;
Nzp2 = filter_params.Nzp2;
Nzp3 = filter_params.Nzp3;
Nzs1 = filter_params.Nzs1;
Nzs2 = filter_params.Nzs2;
Nzs3 = filter_params.Nzs3;
e1 = filter_params.e1;
Ns1 = filter_params.Ns1;
Ns2 = filter_params.Ns2;
Ns3 = filter_params.Ns3;
Nc1 = filter_params.Nc1;
Nc2 = filter_params.Nc2;
Nout1 = filter_params.Nout1;
Nout2 = filter_params.Nout2;
N2 = filter_params.Nw;
bcas1 = filter_params.bcas1;
bcas2 = filter_params.bcas2;
bconj1 = filter_params.bconj1;
bconj2 = filter_params.bconj2;
w = filter_params.w;

%% Create Matrices 1st stage:

%% Step 1: Commute elements to the M1 channels:
E1 = commutator_mtx(e1, M1);
Stage1 = DataFrame*E1;
Ip = eye(P);

%% Step 2: Introduce the Cyclic or Zero extension:
% Method 1: Mathematical / compatible with the paper:
C1 = cyclic_extension_mtx(N1, Ncp1, Nzp1, Ncs1, Nzs1);
Cext = kron(Ip, C1);
Stage2 = Cext*Stage1;

% Method 2: Faster/more efficient:
Stage2b = zeros(P*(N1+Ncp1+Nzp1+Ncs1+Nzs1), M1);
current_size = N1+Nzp1+Nzs1+Ncs1+Ncp1; Y = zeros(current_size,M1);
for p = 1 : P
    Y(Nzp1+Ncp1+1:Nzp1+Ncp1+N1, :) = Stage1((p-1)*N1+1:p*N1, :);
    Y(Nzp1+1:Nzp1+Ncp1,:) = Y(Nzp1+N1+1:Nzp1+N1+Ncp1, :);
    Y(Nzp1+N1+Ncp1+1: Nzp1+N1+Ncp1+Ncs1, :) = Y(Nzp1+Ncp1+1:Nzp1+Ncp1+Ncs1, :);
    Stage2b(1 + (p-1)*current_size:p*current_size, :) = Y;
end

%% Step 3: Upsampling:
% Method 1: Mathematical:
U1 = upsampling_mtx(Ns1, L1, o1(1)); 
U2 = upsampling_mtx(Ns1, L1, o1(2));
Uext = [U1 zeros(size(U2));zeros(size(U1)) U2];     % Create an extended upsampling matrix in case of oqam
% Upsampling with use of matrix:
Stage3 = Uext*Stage2;

% Method 2: Faster/more efficient:
Stage3b = zeros(L1*current_size, M1);
for p = 1 : P
    Y = Stage2b((p-1)*current_size+1:p*current_size, :);
    Y = upsample(Y,L1,o1(p));
    Stage3b(1 + (p-1)*L1*current_size: (p-1)*L1*current_size + size(Y,1), :) = Y;
end
current_size = L1*current_size;

%% Step4: Zerostuffing to reach desired size - which is the signal + filter size... 
Z1 = zerostuffing_mtx(L1*Ns1, Nc1);
Zext = kron(Ip, Z1);
Stage4 = Zext*Stage3;

%% Step5: Modulate data into subchannels:
% Method 1: Mathematical:
F1 = dftlike_mtx(Nc1, M1, bconj1);
Fext = kron([1;1], F1);
Stage5 = conj(Fext).*Stage4;

%% Step5: Filter:
% Method 1: Mathematical:
H1 = filter_mtx(h1, Nc1);% H1 = filter_matrx(h1, Nc1);
Hext = kron(Ip, H1);
Stage6 = Hext*Stage5;

% Method 2: Convolutions:
Stage6b = zeros(size(Stage3b, 1)+ 2*length(h1)-2, M1);
for p = 1 : P
    for ll = 1 : M1
        Stage6b((p-1)*Nc1+1:p*Nc1, ll) = conv(h1.*exp(2i*pi*(0:l1-1)*(ll-1)/M1), Stage3b((p-1)*current_size+1:p*current_size,ll));
    end
end
%% Step6: Back to the correct subchannel:
Stage7 = Fext.*Stage6;

%% Step 7: Phase shifts
% Method 1: Mathematical:
c1 = diag(exp(-2i*pi*(l1-1)/2/M1*(0:M1-1)*bcas1));
Stage8 = Stage7*c1;
% Method 2: Same thing...
Stage8b = Stage6b*c1;

%% Step 8: Downsampling if any
% Method 1: Mathematical:
D1 = downsampling_mtx(Nc1, Q1, 0);
Dext = kron(Ip, D1);
Stage9 = Dext*Stage8;

Stage9b = zeros(Nout1, M1); 
% Method 2: Faster:
for p = 1 : P
    Stage9b(1 + (p-1)*Nout1:(p-1)*Nout1 + length(Stage8b(1 + (p-1)*Nc1 : Q1 : p*Nc1, :)), :) = Stage8b(1 + (p-1)*Nc1 : Q1 : p*Nc1, :);
end

%% Second Stage of Cyclic Extension:
C2 = sparse(cyclic_extension_mtx(Ns2, Ncp2, Nzp2, Ncs2, Nzp2));
Cext2 = kron(Ip, C2);
Stage10 = Cext2*Stage9;
E2 = ones(M1, 1);

%% Windowing:
Stage11 = diag(repmat(w,P,1))*Stage10*E2;

%% FILTERING 2 - all in one: // Dp nothing in FBMC scenario...
U12 = sparse(upsampling_mtx(Ns2, L2, 0));
Uext2 = sparse([U12 zeros(size(U12)); zeros(size(U12)) U12]);
E12 = eye(M2);
E22 = eye(M2);
Z2 = sparse(zerostuffing_mtx(L2*Ns2, Nc2));
Zext2 = sparse(kron(Ip, Z2));
H2 = sparse(filter_mtx(h2, Nc1));
Hext2 = sparse(kron(Ip, H2));
F2 = dftlike_mtx(Nc2, M2, bconj2);
Fext2 = kron([1;1], F2);
D2 = sparse(downsampling_mtx(Nc2, 1, 0));
Dext2 = sparse(kron(Ip, D2));
c12 = diag(exp(-2i*pi*(l2-1)/2/M2*(0:M2-1)));
E3 = sparse([sparse(eye(length(F1))) sparse(eye(length(F1)))]);


sig_out2 = Dext2*((Fext2.*(Hext2*(conj(Fext2).*(Zext2*Uext2*Stage11*E12))))*c12)*E22;
total_sig2 = E3*sig_out2;

