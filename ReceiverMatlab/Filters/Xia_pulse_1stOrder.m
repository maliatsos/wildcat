function [t,g] = Xia_pulse_1stOrder(M,K,a,Ts)

t = linspace(-M/2, M/2, M*K+1);
t = t(1:end-1);
t = t';
t_Ts = t/Ts;

g = (sin(pi*t_Ts).*cos(a*pi*t_Ts))./((pi*t_Ts).*(2*a*t+Ts));

g(K+1:K:end) = 0;
g(M*K/2+1)=1;
g = g / sqrt(sum(g.*g));





