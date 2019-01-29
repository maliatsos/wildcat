function I=cost_func1_meth2(theta,M,m,P)

% Cost function of minimization of the stopband energy of PR filter 
% theta: the under optimization parameters (M/2,m) size.... They are phases
% that create the lattice for the filter implementation and combined
% properly ensures PR

% the function that from theta extracts the filter coefficients
h = create_filt(theta,M,m);
% we keep  the half filter (no need for more due to symmetry)
x_0=h(1:m*M)';
% Stopband energy is given by:
I=4*x_0'*P*x_0;
% Where P is a positive defined matrix that multiplied (quadratic) with
% filter coeffs give the stopband energy (see notes and "Eigenfilters: A
% New Approach to Least-Squares FIR filter design" by Vaidyanathan, Nguyen

