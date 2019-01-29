function h_pr = pr_filter_design(m, M, p_flag, Df, tol_1,tol_2, max_iter1,max_iter2)

% A PR filter Design algorithm ....
% The filter is a Cosine-Modulated FIR filter bank with perfect
% reconstruction property.
% The filter length is 2*M*m (an even integer multiplication of the
% decimation factor...

% Reminder : A cosine filter bank, though it decimates the signal by M, it
% uses 2M polyphase filters (as in the 2m-decimation DFT bank case) with
% specific properties.... Combined with a DCT in the end produce the final
% result

% Why I did it?? IT OCCURES THAT A PR COSINE BANK IS ALSO A PR MODIFIED DFT
% FILTER BANK!!!! SO I CAN USE IT FOR AS AN M-DFT BANK!!

% The design procedure is entirily based on the paper:
% "COSINE-MODULATED FIR FILTER BANKS SATISFYING PERFECT RECONSTRUCTION" by
% R. David Koilpillai and P.P. Vaidyanathan (IEEE Trans on Sig.Pr. 92)
% The refences to the equations is done for the specific paper!!


%% initialization of parameters

% M is the decimation factor for the Cosine FB.. Polyphase components are
% taken for 2M
% M = 4;

% m is the integer factor that defines the filter length. As stated N=2mM
% m = 8;

% max_iter: the maximum number of iterations and function evaluations for
% the optimization procedures

% tol_x: the tolerance needed for the optimization parameters for x
% procedure

% the filter length is given by:
N=2*m*M;

% Fstop is the desired stopband normalized frequency
Fstop = 1/M/2+Df;       % Df: the desired transition bandwidth
ws = Fstop*pi;          % ws the cyclic frequency

% p_flag: Calculation of P matrix is a very lengthy procedure, if set to 0
% the algorithm computes the P matrix... If set to 1 the P matrix is loaded
% by the specific folder in a specific syntax



%% Calculate P matrix / this might take a loooooong time

if p_flag == 0
    % if zero load from existing file
    load(strcat('Pmtx_', num2str(m), '_', num2str(M), '_', num2str(Fstop), '.mat'))
    
elseif p_flag == 1
    % if one create New  matrix...LONG TIME PROCEDURE (Use of symbolic
    % toolbox....
    display('New P matrix creation.... We may have long time ahead...Patience..')
%     [P Ps] = Pcalc(ws,N);
    P = Pcalc(ws,N);
%     save(strcat('Pmtx_', num2str(m), '_', num2str(M), '_', num2str(Fstop), '.mat'),'P','Ps');
    save(strcat('Pmtx_', num2str(m), '_', num2str(M), '_', num2str(Fstop), '.mat'),'P');

    clear Ps
    display('End of the P matrix calculation...Yupi!!')
else
    error('p_flag must be either 0 or 1 ... read function help')
end

%% Step 1: initialization of the filter according to eq.(34) resulting the filter presented in eq. (35)

% the connection between the under optimization parameters theta and the
% filter coefficients is presented in eq. (32 -33). It is based on the two
% channel lattice implementation of an FIR filter.

% theta parameters are 1. M/2 (the polyphases needed for optimization to
% ensure PR and m (the number of coeffs per polyphase 2mM/2M=m (see also
% Fig 2 and eq(32-33) and create_filt function)
theta_0 = zeros(M/2,m);

for k = 1:M/2
    theta_0(k,1) = pi/4;
    for p = 1:m-1
        theta_0(k,p+1) = pi/2;
    end
end
display('End of Step 1 of the filter design algorithm (initialization)')

%% Step 2: First optimization procedure... This involves the minimization of the stopband energy 
%  This is made according to the first Eq of eq.(36)... This is also equal
%  to 4*x'*P*x, where x is the filter coefficient vector cut in half!!
%  (even length of filter therefore the first half is repeated in the end
%  This is shown in my notes and paper "Eigenfilters: A new approach to
%  least-sqares FIR filter design and applications" (see Pcalc function)


% This optimization is Nonlinear and unconstrained optimization
% Done with Matlab's fminsearch

% Optimization toolbox parameter adjustments
% Start with the default options
options = optimset;
% Modify options setting
options = optimset(options,'Display' ,'off');
options = optimset(options,'MaxFunEvals' ,max_iter1);
options = optimset(options,'MaxIter' ,max_iter1);
options = optimset(options,'TolFun' ,tol_1);
options = optimset(options,'TolX' ,tol_1);
options = optimset(options,'LargeScale' ,'on');
[theta_1] = ...
    fminsearch(@(theta)cost_func1_meth2(theta,M,m,P),theta_0,options);
% theta_1 the parameters that define the optimum filter according to Step2
display('End of Step 2 of the filter design algorithm (stopband energy min)')

%% Step 2: First optimization procedure... This involves the minimization of the maximum stopband ripple of the filter transfer function
% It is a minimax optimization problem

% Start with the default options
options = optimset;
% Modify options setting
options = optimset(options,'Display', 'off');
options = optimset(options,'MaxFunEvals', max_iter2);
options = optimset(options,'MaxIter', max_iter2);
options = optimset(options,'TolFun', tol_2);
options = optimset(options,'TolX', tol_2);
options = optimset(options,'TolCon', tol_2);
resol = 5000; % frequency axis resolution for the minimax cost function (see the function for details)
e_ps = pi/40; % margin in the definition of the stopband region for the minimax algorithm (if not zero the algorithm finds maximum ripple in ws+eps:pi)
[theta_2,fval,maxfval,exitflag,output,lambda] = ...
    fminimax(@(theta)cost_func2_meth2(theta,M,m,ws,resol,e_ps),theta_1,[],[],[],[],[],[],[],options);
% theta_2 the parameters that define the optimum filter of the algorithm

% function create_filt (used also in the 2 cost functions) is the function
% that given the theta parameters, computes the coefficients of the
% estimated filter - IT ALSO ENSURES THAT THIS FILTER WILL BE A PR !!
x_2 = create_filt(theta_2,M,m);
display('End of Step 3 of the filter design algorithm (minimax of stopband ripple)')
% FILTER OUTPUT
h_pr=x_2;
save(strcat('pr_filt_',num2str(M),'_',num2str(m),'_',num2str(Fstop),'_',num2str(tol_1),'_',num2str(tol_2),'_',num2str(eps), '.mat'),'h_pr','M','m','tol_1','tol_2','max_iter2','theta_2','Fstop','e_ps');

%% to understand fully the procedure check out the cost functions and the
%% create_filt function!!


