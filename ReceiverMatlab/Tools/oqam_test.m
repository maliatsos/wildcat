%% OQAM TEST:

clear all

%% ------
M1 = 32;
N1 = 300;
M2 = 1;

%% ------
Ncp1 = 0;
Nzp1 = 0;
Ncs1 = 0;
Nzs1 = 0;
Ncp2 = 0;
Nzp2 = 0;
Ncs2 = 0;
Nzs2 = 0;
Ncp3 = 0;
Nzp3 = 0;
Ncs3 = 0;
Nzs3 = 0;

%% ------
L1 = M1;
Q1 = 1;
L2 = 1;
Q2 = 1;
o1 = [0; M1/2];
o2 = 0;

%% ------
e1 = 1:32;


%% -----
load('pr_filt_16_8_0.039063_1e-012_1e-012_2.2204e-016.mat');
h1 = h_pr;
clear m M theta_2 max_iter2 tol_1 tol_2 e_ps Fstop
h2 = 1;
l1 = length(h1);
l2 = length(h2);

%% ------ Calculate others:
Ns1 = N1;
Nc1 = L1*Ns1 + length(h1)  - (L1-max(o1));
Nout = floor(Nc1/Q1);
Ns2 = Nout + (Ncp2 + Nzp2 + Ncs2 + Nzp2);
Nw = Ns2;
Nc2 = L2*Ns2 + length(h2)  - L2;

%% -----
w = ones(1, Nw);

%% -----
bcas1 = 1;
bconj1 = 0;
bcas2 = 0;
bconj2 = 0;

%% Create Data:
Mprime1 = length(e1);
X = randi(4, N1, Mprime1)-1;
X = qammod(X,4);
X1 = zeros(size(X));
X2 = zeros(size(X));
counter = 1;
for nn = e1-1
    if mod(nn,2)==0
        X1(:,counter) = real(X(:,counter));
        X2(:,counter) = 1i*imag(X(:,counter));
    else
        X2(:,counter) = real(X(:,counter));
        X1(:,counter) = 1i*imag(X(:,counter));
    end
    counter = counter + 1;
end
XX = [X1; X2];

%% Create Matrices 1st stage:
C1 = cyclic_extension_mtx(N1, Ncp1, Nzp1, Ncs1, Nzp1);
Cext = kron(eye(2), C1);

%%
U1 = upsampling_mtx(Ns1, L1, o1(1));
U2 = upsampling_mtx(Ns1, L1, o1(2));
Uext = [U1 zeros(size(U1));zeros(size(U2)) U2];
E1 = commutator_mtx(e1, M1);
Z1 = zerostuffing_mtx(L1*Ns1, Nc1);
Zext = kron(eye(2), Z1);
H1 = filter_mtx(h1, Nc1);
Hext = kron(eye(2), H1);
F1 = dftlike_mtx(Nc1, M1, bconj1);
Fext = kron([1;1], F1);
D1 = downsampling_mtx(Nc1, 1, 0);
Dext = kron(eye(2), D1);
c1 = diag(exp(-2i*pi*(l1-1)/2/M1*(0:M1-1)));
E2 = ones(M1, 1);
%%

C2 = sparse(cyclic_extension_mtx(Ns2, Ncp2, Nzp2, Ncs2, Nzp2));
Cext2 = kron(eye(2), C2);
U12 = sparse(upsampling_mtx(Ns2, L2, 0));
Uext2 = sparse([U12 zeros(size(U12)); zeros(size(U12)) U12]);
E12 = eye(M2);
E22 = eye(M2);
Z2 = sparse(zerostuffing_mtx(L2*Ns2, Nc2));
Zext2 = sparse(kron(eye(2), Z2));
H2 = sparse(filter_mtx(h2, Nc1));
Hext2 = sparse(kron(eye(2), H2));
F2 = dftlike_mtx(Nc2, M2, bconj2);
Fext2 = kron([1;1], F2);
D2 = sparse(downsampling_mtx(Nc2, 1, 0));
Dext2 = sparse(kron(eye(2), D2));
c12 = diag(exp(-2i*pi*(l2-1)/2/M2*(0:M2-1)));


E3 = sparse([sparse(eye(length(F1))) sparse(eye(length(F1)))]);

sig_out2 = Dext*((Fext.*(Hext*(conj(Fext).*(Zext*Uext*Cext*XX*E1))))*c1)*E2;
sig_out2 = Dext2*((Fext2.*(Hext2*(conj(Fext2).*(Zext2*Uext2*Cext2*sig_out2*E12))))*c12)*E22;
y11 = zeros(length(X1)*M1+length(h_pr)-1,1);
y22 = zeros(length(X2)*M1+length(h_pr)-1,1);
for kk = 1:32
    tt = upsample(X1(:,kk), M1);
    tmp1 = conv(exp(2i*pi*(0:length(h_pr)-1)*(kk-1)/M1).*h_pr, tt);
    tmp1 = exp(-2i*pi*(l1-1)/2/M1*(kk-1))*tmp1;
    y11 = y11 + tmp1;
    tt = upsample(X2(:,kk), M1, M1/2);
    tmp2 = conv(exp(2i*pi*(0:length(h_pr)-1)*(kk-1)/M1).*h_pr, tt);
    tmp2 = exp(-2i*pi*(l1-1)/2/M1*(kk-1))*tmp2;
    y22 = y22 + tmp2;
end
total_sig2 = E3*sig_out2;

xx1 = [];
xx2 = [];
for kk = 1 : M1
     for xx = 0:M1-1
        tt = conv(h_pr.*exp(2i*pi*(0:length(h_pr)-1)*(kk-1)/M1), total_sig2)*exp(-2i*pi*bcas1*(l1-1)/2/M1*(kk-1));
        tt1 = tt(xx+1:M1:end);
        tt2 = tt(M1/2+xx+1:M1:end);
     end
     if mod(kk-1,2)==0
         tt1 = real(tt1);
         tt2 = imag(tt2);
     else
         tt2 = real(tt2);
         tt1 = imag(tt1);
     end
     
     xx1 = [xx1; tt1];
     xx2 = [xx2; tt2];
end
keyboard