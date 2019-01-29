function [z, x] = iota_pulse2(M,N,K,alpha,L)

M = 64;
N = 32;
K = 2;
alpha = 0.2;

n = -N:N-1;

% definition of the initial gaussian pulse
x = ((2*alpha)^(1/4))*exp(-pi*alpha*(2*n.^2)/(M^2));
Lg = M/2*K;
g = zeros(Lg,1); g(K*M/4-N+1: K*M/4+N) = x;


G = reshape(g, M/2, K).';
Z = fft(G,[], 1);
Zo = zeros(size(Z));

for nn = 0 : M/2-1
    for kk = 0 : K-1
%         if (kk-K/2+1>0)
%             Zo(kk+1, nn+1) = 2*Z(kk+1, nn+1)./sqrt(M*abs(Z(kk+1, nn+1)).^2 + M*abs(Z(kk-K/2+1, nn+1)).^2);
%         else
%             Zo(kk+1, nn+1) = 2*Z(kk+1, nn+1)./sqrt(M*abs(Z(kk+1, nn+1)).^2);
%         end
         Zo(kk+1, nn+1) = 2*Z(kk+1, nn+1)./sqrt(M*abs(Z(kk+1, nn+1)).^2 + M*abs(Z(mod(kk-K/2,K)+1, nn+1)).^2);
    end
end
f = K*ifft(Zo,[],1).';

