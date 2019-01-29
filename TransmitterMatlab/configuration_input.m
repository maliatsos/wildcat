function filter_params = configuration_input(N1, Lpreamble)
% clear all

%% ------
Lpreamble;              % Number of Preambles inserted in the begining of the data frame
M1 = 32;                % Number of subchannels - first filtering stage
N1 = N1 + Lpreamble;    % Number of symbols per subchannel to be created - first filtering stage input in time axis
M2 = 1;                 % Number of subchannels - second filtering stage
P = 2;                  % Number of P-parallel streams according to paper 
Ip = eye(P);            % Parallel stream Identity matrix - used to kronecker productst in order to produce matrices

%% ------
Ncp1 = 0;               % Cyclic prefix size (in samples) - first extension tier
Nzp1 = 0;               % Zero prefix size (in samples) - first extension tier
Ncs1 = 0;               % Cyclic suffix size (in samples) - first extension tier
Nzs1 = 0;               % Zero suffix size (in samples) - first extension tier
Ncp2 = 0;               % Cyclic prefix size (in samples) - second extension tier
Nzp2 = 0;               % Zero prefix size (in samples) - second extension tier
Ncs2 = 0;               % Cyclic suffix size (in samples) - second extension tier
Nzs2 = 0;               % Zero suffix size (in samples) - second extension tier
Ncp3 = 0;               % Cyclic prefix size (in samples) - third extension tier
Nzp3 = 0;               % Zero prefix size (in samples) - third extension tier
Ncs3 = 0;               % Cyclic suffix size (in samples) - third extension tier
Nzs3 = 0;               % Zero suffix size (in samples) - second extension tier

%% ------
L1 = M1;                % Upsampling factor for filtering 1
L2 = 1;                 % Upsampling factor for filtering 2
Q1 = 1;                 % downsampling for filtering 1
Q2 = 1;                 % downsampling for filtering 2
% Filtering offsets 
o1 = [0; M1/2];         % per P parallel streams - seting up for FBMC
o2 = 0;                 % No offset for all parallel streams.

%% ------
% e1 = [2:M1/2-3 M1/2+4:M1];    % Commutator - leading created data streams to specific filter inputs.
e1 =1:M1;
%% ----- 
load('phydias32.mat')   % Load prototype filter
clear m M theta_2 max_iter2 tol_1 tol_2 e_ps Fstop      % Clear possible trash included in the loaded mat file
h1 = g;                 % The first filter impulse response (from the file)
h2 = 1;                 % Dirac impulse response (no filtering actually)

l1 = length(h1);        % Filter lengths (stage 1)
l2 = length(h2);        % Filter lengths (stage 2)

%% ------ Calculate other vector lengths and sizes:
Ns1 = N1+ (Ncp1 + Nzp1 + Ncs1 + Nzp1);
Nc1 = L1*Ns1 + length(h1)  - 1; % Nc1 = L1*Ns1 + length(h1)  - (L1-max(o1));
Nout1 = floor(Nc1/Q1);
Ns2 = Nout1 + (Ncp2 + Nzp2 + Ncs2 + Nzp2);
Nw = Ns2;
Nc2 = L2*Ns2 + length(h2)  - L2;
Nout2 = floor(Nc2/Q2);
Ns3 = Nout2 + (Ncp3 + Ncs3 + Nzs3 + Nzp3);

%% -----
w = ones(Nw,1);         % Definition of windowing function between filtering stages

%% -----
bcas1 = 1;              % compensate phase shift caused due to filter causality (1 yes, 0 no/don't care) - filtering stage 1
bconj1 = 0;             % flag indicating if exp(1i*phi) or exp(-1i*phi) will be used 
bcas2 = 0;              % compensate phase shift caused due to filter causality (1 yes, 0 no/don't care) - filtering stage 2
bconj2 = 0;             % flag indicating if exp(1i*phi) or exp(-1i*phi) will be used 

%% ------
oqam_flag = 1;          % Are you trying to do fbmc-oqam?

%% load all parameters to a parameter structure:
filter_params = struct('P', P, 'h1', h1, 'h2', h2, 'l1', l1, 'l2', l2, 'M1', M1, 'M2', M2, 'L1', L1, 'L2', L2,...
    'Q1', Q1, 'Q2', Q2, 'o1', o1, 'o2', o2, 'bcas1', bcas1, 'bcas2', bcas2, 'bconj1', bconj1, 'bconj2', bconj2,...
    'N1', N1, 'Lpreamble', Lpreamble, 'w', w, 'Ncp1', Ncp1, 'Ncp2', Ncp2, 'Ncp3', Ncp3, 'Ncs1', Ncs1, 'Ncs2', Ncs2, 'Ncs3', Ncs3, ...
    'Nzp1', Nzp1, 'Nzp2', Nzp2, 'Nzp3', Nzp3, 'Nzs1', Nzs1, 'Nzs2', Nzs2, 'Nzs3', Nzs3,...
    'Ns1', Ns1, 'Ns2', Ns2, 'Ns3', Ns3, 'Nc1', Nc1, 'Nc2', Nc2, 'Nout1', Nout1, 'Nout2', Nout2, 'Nw', Nw, 'e1', e1, 'oqam_flag', oqam_flag);