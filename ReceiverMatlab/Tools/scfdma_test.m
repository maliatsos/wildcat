%% OFDM TEST:

clear all

%% ------
M1 = 16;
N1 = 1;
M2 = 32;

%% ------
Ncp1 = 0;
Nzp1 = 0;
Ncs1 = 0;
Nzs1 = 0;
Ncp2 = 0;
Nzp2 = 0;
Ncs2 = 0;
Nzs2 = 0;
Ncp3 = 8;
Nzp3 = 0;
Ncs3 = 0;
Nzs3 = 0;

%% ------
e1 = 1:M1;
E2 = ones(M1, 1);

%% ------
L1 = M1;
Q1 = 1;
L2 = M2;
Q2 = M1;
o1 = 0;
o2 = 0;

%% -----
h1 = ones(M1,1);
h2 = ones(M2,1);
l1 = length(h1)-1;
l2 = length(h2)-1;

%% ------ Calculate others:
Ns1 = N1;
Nc1 = L1*Ns1 + length(h1)  - (L1-o1);
Nout = floor(Nc1/Q1);
Ns2 = Nout + (Ncp2 + Nzp2 + Ncs2 + Nzp2);
Nw = Ns2;
Nc2 = L2*Ns2 + length(h2)  - (L2-o1);

%% -----
w = ones(1, Nw);

%% -----
bcas1 = 0;
bconj1 = 1;
bcas2 = 0;
bconj2 = 0;

%% Create Data:
Mprime1 = length(e1);
X = randi(4, N1, Mprime1)-1;
X = qammod(X,4);

%% Create Matrices 1st stage:
C1 = cyclic_extension_mtx(N1, Ncp1, Nzp1, Ncs1, Nzp1);
U1 = upsampling_mtx(Ns1, L1, o1);
E1 = commutator_mtx(e1, M1);
Z1 = zerostuffing_mtx(L1*Ns1, Nc1);
H1 = filter_mtx(h1, Nc1);
F1 = dftlike_mtx(Nc1, M1, bconj1);
D1 = downsampling_mtx(Nc1, Q1, 0);
W = window_mtx(w);
c1 = diag(exp(-2i*pi*bcas1/2/M1*(0:M1-1)));
c2 = diag(exp(-2i*pi*bcas2/2/M2*(0:M2-1)));
E3 = ones(M2, 1);

%% Create Matrices 2nd stage:
C2 = cyclic_extension_mtx(Nout, Ncp2, Nzp2, Ncs2, Nzp2);
U2 = upsampling_mtx(Ns2, L2, o2);
D2 = downsampling_mtx(L2*Ns2, Q2, o2);
F2 = dftlike_mtx(Nc2, M2, bconj2);
Z2 = zerostuffing_mtx(L2*Ns2, Nc2);
H2 = filter_mtx(h2, Nc2);

%% Cyclic third:
C3 = cyclic_extension_mtx(floor(Nc2/Q2), Ncp3, Nzp3, Ncs3, Nzp3);


sig_out1 = D1*((F1.*(H1*(conj(F1).*(Z1*U1*C1*X*E1))))*c1)*E2;

sig_out1 = 
sig_out2 = D2*(F2.*(H2*conj(F2).*(Z2*U2*sig_out1*E2*c2)));

sig_out = C3*(sig_out2*E3);