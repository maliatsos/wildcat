function H = filter_matrx(h, Nc)

L0 = length(h)-1;
H = zeros(Nc);
line1 = zeros(1, Nc);
line1(1) = h(1);
line1(end:-1:end-L0+1) = h(2:end);

for kk = 1 : Nc
    H(kk, :) = circshift(line1, [0, kk-1]);
end