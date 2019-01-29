%% Apply Demodulator:

% First Rx (Third Tx) CP tier:
sampl_offset = -1; % Aligns the sampling between the synthesis and analysis band

% corr_synchronizer(RxSignal, Lpreamble, M1, 0, 0);
channel = [1+0.87i 0.2+0.1i 0.1+0.2i];
% channel = [0.5i-0.8i -0.2i 0.2+0.1i 0.1+0.2i 0.01i-0.01];
CC = fft(channel,64);
RxSignal = conv(RxSignal, channel);

%---------------------------------------------------------
%% Used for Equlization - Manipulation of Reference Signals:
RefSignal = [XX(1:Lpreamble, :); XX(N1+1:N1+Lpreamble, :)];
InSignal = calculate_oqam_preamble_at_Tx(RefSignal, h1, e1, L1, Q1, M1, P, o1, bconj1, bcas1);
OutSignal = calculate_oqam_preamble_at_Rx(RefSignal, h1, e1, L1, Q1, M1, P, o1, bconj1, bcas1, sampl_offset);
%----------------------------------------------------------
%% Synchronizer:
P = crosscorr_synchronizer(RxSignal, InSignal);
[PP,RR] = corr_synchronizer(RxSignal, Lpreamble, M1, 0, 0);
[~,sync_point] = max(abs(P)); %max(abs(PP(1:length(P))).*abs(P));

%% DEMODULATOR START:
RxStage1 = RxSignal(sync_point + 1 + sampl_offset: sync_point + 1 + sampl_offset + Ns3+Ncp3+Nzp3+Ncs3+Nzp3-1);
% Add Zero Prefix back:
RxStage1(end-Nzp2+1:end) = RxStage1(end-Nzp2+1:end) + RxStage1(1:Nzp2);
% Then throw it away:
RxStage1 = RxStage1(Nzp2+1:end);
% Add Zero Prefix in front:
RxStage1(1:Nzs2) = RxStage1(end-Nzs2+1:end) + RxStage1(1:Nzs2);
% Then throw it away:
RxStage1 = RxStage1(1:end-Nzs2);
% Cyclic Prefix - Cyclic Suffix removal:
guard = 0;
RxStage1 = RxStage1(Ncp2+1-guard:Ncp2+Ns2-guard);

sig_length = Nout2; % At this point signal size should be Nout2

%% FILTER STAGE 1 RX (2 FOR TX - 2 USED AS NOTATION)
%% Sending input to all filters:
E2 = ones(1, M2);
RxStage2 = RxStage1*E2;

%% Phase Shifts:
c2 = diag(exp(-2i*pi*(l2-1)/2/M2*(0:M2-1)));
RxStage2a = exp(1i*pi*bconj2/2)*RxStage2*c2;

%% FILTERING 2 - all in one:
U2 = sparse(upsampling_mtx(sig_length, dec2, 0));
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
c1 = diag(exp(-2i*pi*(l1-1)/2/M1*(0:M1-1)));
RxStage5 = exp(1i*pi*bconj1/2)*RxStage4*c1;

U1 = upsampling_mtx(sig_length, Q1, 0);
Z1 = zerostuffing_mtx(sig_length, sig_length + length(h1) - 1);
sig_length = sig_length + length(h1)-1;
F1 = dftlike_mtx(sig_length, M1, bconj1);
H1 = sparse(filter_mtx(h1, sig_length));
RxStage6a = F1.*(H1*(conj(F1).*(Z1*U1*RxStage5)));

%% Channel Estimator @ this Point:
starting_point_stage2 = floor((length(h2)-1)/M2) + 1; % Signal starting point after filter 2
starting_point = length(h1) +sampl_offset + (starting_point_stage2-1) + 1; % Signal starting point after filter 1

signal_for_FEQ = RxStage6a(1:(Lpreamble+1)*M1,:);
[all_channel, Channel_estimate, channel_estimate]  = tmp_channel_estimation(signal_for_FEQ, OutSignal,M1, M1, 4*M1, M1, 0, 0, 0);

err = [err mean((abs(all_channel) - abs(CC)').^2)];

%% Return to Start of Filter stage 2 to apply the equalizer:
% e = 2:M1;
% newSignal  = FEQ(RxSignal, sync_point, N1, M1, l1, all_channel, e, 0);
% 
% RxStage3 = newSignal; sig_length = N1*M1;
% RxStage4 = RxStage3*E1;
% 
% %% Phase Shifts:
% c1 = diag(exp(-2i*pi*(l1-1)/2/M1*(0:M1-1)));
% RxStage5 = exp(1i*pi*bconj1/2)*RxStage4*c1;
% 
% sig_size = length(RxStage4);
% U1 = upsampling_mtx(sig_length, Q1, 0);
% Z1 = zerostuffing_mtx(sig_length, sig_length);
% F1 = dftlike_mtx(sig_length, M1, bconj1);
% H1 = filter_mtx(h1, sig_length);
% RxStage6a = F1.*(H1*(conj(F1).*(Z1*U1*RxStage5)));
% RxStage7a = circshift(RxStage6a, -sampl_offset);
% 
% %% Channel Equalization:
% D11 = (downsampling_mtx(sig_length, L1, o1(1)));
% D12 = (downsampling_mtx(sig_length, L1, o1(2)));
% 
% RxStage6b = D11*RxStage7a;
% RxStage6c = D12*RxStage7a;
% sig_length = floor(sig_length/L1);
% 
% %% Seperate symbols for OQAM:
% X1 = zeros(sig_length-Lpreamble+1, M1);
% X2 = zeros(sig_length-Lpreamble+1, M1);
% for ll = 0 : M1-1
%     if ll~=M1/2+1 % The outer channel remains unused
%         if mod(ll,2)==0
%             X1(:, ll+1) = real(RxStage6b(Lpreamble:end,ll+1));
%             X2(:, ll+1) = 1i*imag(RxStage6c(Lpreamble:end,ll+1));
%         else
%             X1(:, ll+1) = 1i*imag(RxStage6b(Lpreamble:end,ll+1));
%             X2(:, ll+1) = real(RxStage6c(Lpreamble:end,ll+1));
%         end
%     end
% end
% output = X1(2:end,:)+X2(2:end,:); output = output(:);
% scatterplot(output);
% 
% % Not Applicable in OQAM example:
% % %% 2nd Tier (for both Tx and Rx) Removal of Cyclic Prefix:
% % signal_size = Ns2 + Ncp2 + Nzp2 + Ncs2 + Nzp2;
% % % Add Zero Prefix back:
% % RxStage3(end-Nzp2+1:end) = RxStage2b(end-Nzp2+1:end) + RxStage2b(1:Nzp2);
% % % Then throw it away:
% % RxStage3 = RxStage3(Nzp2+1:end);
% % % Add Zero Prefix in front:
% % RxStage3(1:Nzs2) = RxStage3(end-Nzs2+1:end) + RxStage3(1:Nzs2);
% % % Then throw it away:
% % RxStage3 = RxStage3(1:end-Nzs2);
% % % Cyclic Prefix - Cyclic Suffix removal:
% % guard = 0;
% % RxStage4 = RxStage3(Ncp2+1-guard:Ncp2+Ns2-guard);