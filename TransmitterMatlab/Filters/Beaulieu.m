function [t,g] = Beaulieu(M,K,a,Ts)

b = log(2)/(a/(2*Ts));
t = linspace(-M/2, M/2, M*K+1); 
t = t(1:end-1); 
t = t';

g = ( (1/Ts)*sinc(t/Ts).*( 4*b*pi.*t.*sin( (pi*a.*t)/Ts ) + 2*(b^2)*cos( (pi*a.*t)/Ts ) - b^2) )./( 4*(pi^2)*(t.^2)+ b^2 );
g = g / sqrt(sum(g.*g));
