

% clear all

%% ------
Lpreamble = 6;
M1 = 64;
N1 = 20 + Lpreamble;
M2 = 1;
P = 2;     % Number of P-parallel streams according to paper 
Ip = eye(P); % Parallel stream Identity matrix

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
dec1 = 1; % downsampling for filtering 1
dec2 = 1; % downsampling for filtering 2

%% ------
e1 = 1:M1;


%% -----
% load('pr_filt_16_8_0.039063_1e-012_1e-012_2.2204e-016.mat');
% load('mdft_iter_filt_64_128_fstop0.023438.mat')
% load('mdft_iter_filt_128_128_fstop0.0117.mat')
% load('beaulieu_bands64_coefs128_alpha0.35.mat')
% load('dirichlet_bands64_coefs128.mat')
load(fname);
if exist('g', 'var')
    if size(g,1)>1
        h1 = g.';
    else
        hi = g;
    end
else 
    h1 = h_pr;
end
% load('pr_filt_64_1_0.015625_1e-06_1e-06_2.2204e-16.mat');
% h1 = h_pr;
clear m M theta_2 max_iter2 tol_1 tol_2 e_ps Fstop
h2 = 1;
l1 = length(h1); 
l2 = length(h2);

%% ------ Calculate others:
Ns1 = N1+ (Ncp1 + Nzp1 + Ncs1 + Nzp1);
Nc1 = L1*Ns1 + length(h1)  - 1; % Nc1 = L1*Ns1 + length(h1)  - (L1-max(o1));
Nout1 = floor(Nc1/Q1);
Ns2 = Nout1 + (Ncp2 + Nzp2 + Ncs2 + Nzp2);
Nw = Ns2;
Nc2 = L2*Ns2 + length(h2)  - L2;
Nout2 = floor(Nc2/Q2);
Ns3 = Nout2 + (Ncp3 + Ncs3 + Nzs3 + Nzp3);

%% -----
w = ones(Nw,1);

%% -----
bcas1 = 1;
bconj1 = 0;
bcas2 = 0;
bconj2 = 0;
%% ------
oqam_flag = 1;