function [t,g] = Double_Jump(M,K,a,Ts)


t = linspace(-M, M, M*K+1); 
t = t(1:end-1); 
t = t';

g = sinc(t/Ts).*( (1-a)*cos((pi*a*t)/Ts) +a*sinc((a*t)/Ts));
g = g / sqrt(sum(g.*g));
