function I=cost_func2_meth2(theta,M,m,ws,resol,eps)
% Cost function of minimization of the maximum stopband response of the
% filter according to eq(36)
% theta: the under optimization parameters (M/2,m) size.... They are phases
% that create the lattice for the filter implementation and combined
% properly ensures PR
% M: decimation factor of the cosine bank
% m: 2*m*M is the filter length
% ws: the stopband cyclic frequency of the filter under investigation
% resol: the frequency axis resolution. It is a measure of accuracy of the
% minimax algorithm
% eps : if zero it starts the stopband region of investigation in
% ws..otherwise it gives a margin and it starts from ws+eps

% the filter length
N=2*m*M;
% the function that from theta extracts the filter coefficients
h = create_filt(theta,M,m);
% we keep  the half filter (no need for more due to symmetry)
h = h(1:m*M)';
% we normalize to 1
h = h./(sqrt(2*M)*2);

k=1;
I=zeros(1,length(ws:pi/resol:pi));
% The stopband energy value in a given frequency for filter h is given the
% inner product 2*(h')*cos(w.*(N/2-(0:N/2-1)-1/2)).'
%(see notes and "Eigenfilters:A New Approach to Least-Squares FIR filter 
% design" by Vaidyanathan, Nguyen
for w=ws+eps:pi/resol:pi
    I(k)=2*abs((h')*cos(w.*(N/2-(0:N/2-1)-1/2)).');
    k=k+1;
end

% We created a big vector of frequency values.. This vector is inserted in
% the minimax optimization procedure of Matlab... More values better
% accuracy - better results (ok...don't overdoit)