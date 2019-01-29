% function [P Ps]=Pcalc(ws,N)
function P=Pcalc(ws,N)

% Calculation of P matrix for the calculation of the out-of-band filter
% energy, given the fact that the filter is a symmetric FIR filter of EVEN
% LENGTH!!!

% Method for calculation of P matrix presented in "Eigenfilters: A
% New Approach to least squares FIR fiter Design and Applications including
% Nyquist Filters" by Vaidyanathan, Nguyen page13....

% Actually to ensure that the calculation is correct, all the manipulation
% is made by me (check your notes!!) and the result is slightly different
% for that presented in the paper

% N,M the dimensions of Matrix P... It is in normal conditions a square
% matrix of length filter_length/2 (0:filter_length/2-1)

% I don't care for the passband error.... So let's say that alpha = 1


%% THE ESTIMATION OF P IS MADE ACCORDING TO MY WORK~!!!

w=sym('w');
a=sym('a');
b=sym('b');
c=cos(w.*(N/2-(0:N/2-1)-1/2)).';

cc = cos(w.*a)*cos(w.*b);
ps = int(cc, w, ws, pi);

CC = zeros(N/2);
counter1 = 1;
for aa = (N/2-(0:N/2-1)-1/2) 
    counter2 = 1;
    for bb = (N/2-(0:N/2-1)-1/2)
        CC(counter1, counter2) = ps_ccal(aa, bb);
        counter2 = counter2 + 1;
    end
    counter1 = counter1 + 1;
end
P = CC;

% C=c*c';
% Ps=int(C,w,ws,pi);
% P=double(Ps);


