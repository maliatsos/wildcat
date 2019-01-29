function [t,g] = Gaussian_pulse(M,K,a)

t = linspace(-M/2, M/2, M*K+1);
t = t(1:end-1);
t = t';

%  Equality must hold: a = (1/(B*Ts))*sqrt(ln(2)/2)
g = (sqrt(pi)/a)*exp(-(pi^2)*(t.^2)/(a^2));
g = g / sqrt(sum(g.*g));

