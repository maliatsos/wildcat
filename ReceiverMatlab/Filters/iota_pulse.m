function [z, x] = iota_pulse(M,N,alpha,L)

n = -N:N-1;

% definition of the initial gaussian pulse
x = ((2*alpha)^(1/4))*exp(-pi*alpha*(2*n.^2)/(M^2));

% orthogonalization of x 
k = 1;
y = zeros(size(x));
I = zeros(size(x));
for n = -N:N-1
    for l = -N/2:N/2-1
        I(k) = I(k) + (((2*alpha)^(1/4))*exp(-pi*alpha*(n*sqrt(2)/M - (n - l)/sqrt(2)).^2))^2;
    end
    if I(k)>1e-12
        y(k) = (2^(1/4))*x(k)/sqrt(I(k));
    else
        y(k) = 0;
    end
    k=k+1;
end

Y = zeros(M,size(y,2));
for k = 0:M-1
   Y(k+1,:) = fft(exp(1i*2*pi*k*(-N:N-1)/M).*y);
end
Z = (2^(1/4))*Y(1,:)./(sqrt(sum(abs(Y.^2))));
z = ifft(Z);
% 
if mod(L,2)==0
    z = z(-L/2+N+1:N+1+L/2 -1);
else
    z = z(-(L-1)/2+N+1:N+1+(L-1)/2 );
end