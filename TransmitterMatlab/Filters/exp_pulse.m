function [t,g] = exp_pulse(M,K,a,Ts)

b = pi*a/log(2);

t = linspace(-M/2, M/2, M*K+1);
t = t(1:end-1);
t = t';

g = sinc(t/Ts).*( ( (2*b*t/Ts).*(sin(pi*a*t/Ts)) + 2*cos(pi*a*t/Ts) - 1 )./(((b*t)/Ts).^2 + 1) );

g(K+1:K:end) = 0;
g(M*K/2+1)=1;
g = g / sqrt(sum(g.*g));

