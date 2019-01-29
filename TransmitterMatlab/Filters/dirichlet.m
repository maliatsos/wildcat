function g = dirichlet(M, K)

% M samples
% K Subcarriers

o = ones(1, M);
z = zeros(1, K*M-M);

G = [o z];
G = circshift(G, [0, -floor(M/2)]);

g = ifft(G);
g = g / sqrt(sum(abs(g).^2));
g = g';
g = ifftshift(g);