function p = mdft_filt_iterative_design(M, N, f_stop, alpha, tau, eps)

% 22 April 2011
% Design of an mdft lowpass prototype filter as proposed in "Efficient Iterative Design Method for Cosine Modulated QMF Banks" from 
% Hua Xu and Wu-Sheng Lu and Andreas Antoniou - ALGORITHM 1 - No Low delay design. 
% Design of Cosine Modulated bank of M/2 subchannels
% Input variables:
% M : The Mdft bank rank - subchannels
% N : The number of filter coefficients% init_filter_path : The path to load a filter for algorithm initialization
% f_stop : The cutoff frequency in Normalized Frequency as used in fdatool (only one half from 0 to 1)

% alpha : algorithm parameter - usually large (in paper is 200, 100 or smthing)
% tau : algorithm parameter (passband, stopband weight from 0 to 1)
% eps : error in the perfect reconstruction sense... 

% In the cosine modulated filter bank, the number of subchannels are the half -> 1/M filter is used for M/2-cos-Fbank
M = M/2;

% Going to cyclic frequency domain as in algorithm (0:2*pi)
w_stop = f_stop*pi;
w_step = 2*pi/N;

% Design the filter for initialization:

f_pass = 1/(2*M) - (f_stop - 1/(2*M))/2;  % Passband Frequency
Wpass = 1;      % Passband Weight
Wstop = 1;      % Stopband Weight16
dens  = 20;     % Density Factor
% plot(0:w_step:2*pi-w_step,20*log10(abs(fft([p; p(end:-1:1)]))))
% hold all
% plot(0:w_step:2*pi-w_step,20*log10(abs(fft(p_init))))
% stem(ws,0)
% keyboard
b  = firpm(N-1, [0 f_pass f_stop 1], [1 1 0 0], [Wpass Wstop], {dens});  % Calculate the coefficients using the FIRPM function.
Hb = dfilt.dffir(b);
p = Hb.Numerator;

% Store the whole filter in p_all and keep in p the half filter for N even or the (18a) for N odd
p_all = p.';

if mod(N,2) == 0
    p = p_all(1:N/2);
else
    p = 2*p_all(1: (N+1)/2);
    p(end) = p_all((N+1)/2);
end
p_init = p_all;

% Computation of Us matrix based on (15d) and (18b):

if mod(N,2) == 0
    
    Us = zeros(N/2);
    for ii = 1 : N/2
        for jj = 1 : N/2
            
            if ii==jj
                Us(ii,jj) = 0.5*(pi-w_stop) - sin((2*ii - N -1)*w_stop)/2/(2*ii-N-1);
            else
                Us(ii,jj) = sin((ii-jj)*w_stop)/2/(jj-ii) - sin((ii+jj-N-1)*w_stop)/2/(ii+jj-N-1);
            end
            
        end
    end
    Us = 4*Us;        
       
    
else
    
    Us = zeros((N+1)/2);
    for ii = 1 : (N+1)/2
        for jj = 1 : (N+1)/2
            
            if (ii == (N+1)/2) && (ii == jj)
                Us(ii, jj) = pi - w_stop;
            elseif (ii == jj) && (ii ~= (N+1)/2)
                Us(ii, jj) = 0.5*(pi - w_stop) - sin((2*ii - N -1)*w_stop)/(2*(2*ii - N - 1));
            else
                Us(ii, jj) = sin((ii - jj)*w_stop)/(2*(jj - ii)) - sin((ii + jj - N -1)*w_stop)/(2*(ii + jj - N -1));
            end
            
        end
    end
         
       
end


% Definition of cyc.freq vector:
w = 0 :w_step:2*pi-w_step;

% Isolation of w_pk vector used in metrics:
if mod(N,2) == 0 
    w_pk = w(1: floor(N/2/M)+1);
else
    w_pk = w(1: floor((N+1)/2/M)+1);
end

% Computation of Ut matrix and its delayed version:

if mod(N,2) == 0
    Ut = zeros(size(w_pk,2),N/2);
    Ut_shift = zeros(size(w_pk,2),N/2);
    for ii = 1 : floor(N/2/M)+1
        tmp = 2*cos(((N/2-1:-1:0)+1/2)*w(ii));
        Ut(ii,:) = tmp;
        tmp = 2*cos(((N/2-1:-1:0)+1/2)*(w(ii)-pi/M));
        Ut_shift(ii,:) = tmp;
    end
else
    Ut = zeros(size(w_pk,2),(N+1)/2);
    Ut_shift = zeros(size(w_pk,2),(N+1)/2);
    for ii = 1 : floor((N+1)/2/M)+1
        
        tmp = cos(((N-1)/2:-1:0)*w(ii));
        Ut(ii,:) = tmp;
        
        tmp = cos(((N-1)/2:-1:0)*(w(ii)-pi/M));
        Ut_shift(ii,:) = tmp;
    end
end


% Iteration Counter and initialization of other loop variables
iter = 1;
err = [];
q = zeros(size(p));

% Loop:
while sum(abs(p-q).^2)>eps  % While loop error is less than eps
    
    Mp = zeros(size(w_pk));
    c = zeros(1, length(p));
        
    for ii = 1 : size(Mp,2)
        c = cos(((N-1)/2:-1:0)*w_pk(ii));       
        Mp(ii) = 2*p'*c';
    end
    H = diag(Mp);
    
    Mp_shift = zeros(size(w_pk));
    for ii = 1 : size(Mp,2)
        tmp = cos(((N/2-1/2):-1:1/2)*(w_pk(ii)-pi/M));
        if mod(N,2) == 0
            c = tmp;
        else
            c(1:end-1) = tmp;
            c(end) = 1;
        end
       
        Mp_shift(ii) = 2*p'*c';
    end
    H_shift = diag(Mp_shift);
    
    U = H*Ut + H_shift*Ut_shift;
    
    % Computation of q
    q = (U'*U + alpha*Us)^(-1)*(U'*ones(size(U,1),1));
    % Update p filter with use of tau and q
    p_new = (1-tau)*p + tau*q;
    
    iter = iter + 1;
    p = p_new;
    
    if mod(N,2) == 0
        p_all(1:length(p)) = p; 
        p_all(length(p)+1:end) = p(end:-1:1);
    else
        p_all(1:length(p)) = p;
        p_all(length(p)+1:end) = p(end-1:-1:1);
        p_all(length(p)) = p_all(length(p)) + p(end);
    end
    %     err = [err sum(abs(p-q).^2)];
end


p = p_all;

% plot(0:w_step:2*pi-w_step,20*log10(abs(fft(p))))
% hold all
% plot(0:w_step:2*pi-w_step,20*log10(abs(fft(p_init))))
% stem(w_stop,0)