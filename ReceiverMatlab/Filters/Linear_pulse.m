function [t,g] = Linear_pulse(M,K,a,Ts)

t = linspace(-M/2, M/2, M*K+1);
t = t(1:end-1);
t = t';

g = sinc(t/Ts).*sinc((a*t)/Ts);

g(K+1:K:end) = 0;
g(M*K/2+1)=1;
g = g / sqrt(sum(g.*g));