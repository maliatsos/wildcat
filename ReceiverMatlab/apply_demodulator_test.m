function apply_demodulator_test(RxSignal, filter_params)

%% Apply Demodulator:
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
Lpreamble = filter_params.Lpreamble;

% First Rx (Third Tx) CP tier:
sampl_offset = -1; % Aligns the sampling between the synthesis and analysis band

%% DEMODULATOR START:
sync_point = M1+1;
RxStage1 = RxSignal(sampl_offset + sync_point: sync_point + sampl_offset + Ns3 - 1);
% Add Zero Prefix back:
RxStage1(end-Nzp3+1:end) = RxStage1(end-Nzp3+1:end) + RxStage1(1:Nzp3);
% Then throw it away:
RxStage1 = RxStage1(Nzp3+1:end);
% Add Zero Suffix in front:
RxStage1(1:Nzs3) = RxStage1(end-Nzs3+1:end) + RxStage1(1:Nzs3);
% Then throw it away:
RxStage1 = RxStage1(1:end-Nzs3);
% Cyclic Prefix - Cyclic Suffix removal:
guard = 0;
RxStage1 = RxStage1(Ncp3+1-guard:end-Ncs3-guard);

sig_length = Nout2; % At this point signal size should be Nout2

%% FILTER STAGE 1 RX (2 FOR TX - 2 USED AS NOTATION)
%% Sending input to all filters:
E2 = ones(1, M2);
RxStage2 = RxStage1*E2;

%% Phase Shifts:
c2 = diag(exp(-2i*pi*(l2-1)/2/M2*(0:M2-1)));
RxStage2a = exp(1i*pi*bconj2/2)*RxStage2*c2;

%% FILTERING 2 - all in one:
U2 = sparse(upsampling_mtx(sig_length, Q2, 0));
sig_length = (sig_length-1)*Q2 + 1;
Z2 = sparse(zerostuffing_mtx(sig_length, sig_length + length(h2) - 1));
sig_length = sig_length + length(h2)-1;
F2 = dftlike_mtx(sig_length, M2, bconj2);
H2 = sparse(filter_mtx(h2, sig_length));
D2 = sparse(downsampling_mtx(sig_length, L2, 0));
sig_length = floor(sig_length/L2);
RxStage2 = D2*(F2.*(H2*(conj(F2).*(Z2*U2*RxStage2a))));

RxStage3 = RxStage2;

%% GOING TO SECOND STAGE OF FILTERING:
E1 = ones(1, M1);
RxStage4 = RxStage3*E1;

%% Phase Shifts:
c1 = diag(exp(-2i*pi*bcas1*(l1-1)/2/M1*(0:M1-1)));
RxStage5 = exp(1i*pi*bconj1/2)*RxStage4*c1;

U1 = upsampling_mtx(sig_length, Q1, 0);
Z1 = zerostuffing_mtx(sig_length, sig_length + length(h1) - 1);
sig_length = sig_length + length(h1)-1;
F1 = dftlike_mtx(sig_length, M1, bconj1);
H1 = filter_mtx(h1, sig_length);%filter_matrx(h1, sig_length);
RxStage6a = F1.*(H1*(conj(F1).*(Z1*U1*RxStage5)));

D11 = (downsampling_mtx(sig_length, L1, o1(1)));
D12 = (downsampling_mtx(sig_length, L1, o1(2)));

RxStage7b = D11*RxStage6a;
RxStage7c = D12*RxStage6a;
sig_length = floor(sig_length/L1);

%% Seperate symbols for OQAM:
X1 = zeros(sig_length-Lpreamble+1, M1);
X2 = zeros(sig_length-Lpreamble+1, M1);
for ll = 0 : M1-1
        if mod(ll,2)==0
            X1(:, ll+1) = real(RxStage7b(Lpreamble:end,ll+1));
            X2(:, ll+1) = 1i*imag(RxStage7c(Lpreamble:end,ll+1));
        else
            X1(:, ll+1) = 1i*imag(RxStage7b(Lpreamble:end,ll+1));
            X2(:, ll+1) = real(RxStage7c(Lpreamble:end,ll+1));
        end
end
output = X1(1:filter_params.N1-1,filter_params.e1)+ X2(1:filter_params.N1-1,filter_params.e1); output = output(:);
scatterplot(output);

