load('pr_filt_16_8_0.039063_1e-012_1e-012_2.2204e-016.mat');

N1 = 200;
M1 = 32;

X = randi(4, N1, M1)-1;
X = qammod(X,4);
X1 = zeros(size(X));
X2 = zeros(size(X));
counter = 1;
for nn = 0:M1-1
    if mod(nn,2)==0
        X1(:,counter) = real(X(:,counter));
        X2(:,counter) = 1i*imag(X(:,counter));
    else
        X2(:,counter) = real(X(:,counter));
        X1(:,counter) = 1i*imag(X(:,counter));
    end
    counter = counter + 1;
end

y1 = zeros(length(X1)*M1+length(h_pr)-1,1);
y2 = zeros(length(X2)*M1+length(h_pr)-1,1);

l1 = length(h_pr);

for kk = 1:M1
    tmp1 = exp(-2i*pi*(l1-1)/2/M1*(kk-1))*conv(h_pr.*exp(2i*pi*(0:length(h_pr)-1)*(kk-1)/M1), upsample(X1(:,kk), M1));
    y1 = y1 + tmp1;
    tmp2 = exp(-2i*pi*(l1-1)/2/M1*(kk-1))*conv(h_pr.*exp(2i*pi*(0:length(h_pr)-1)*(kk-1)/M1), upsample(X2(:,kk), M1, M1/2));
    y2 = y2 + tmp2;
end


for kk = 1:M1
    for xx = 0 : M1-1
        tmp1 = exp(-2i*pi*(l1-1)/2/M1*(kk-1))*conv(h_pr.*exp(2i*pi*(0:length(h_pr)-1)*(kk-1)/M1), y1);
        xest1 = tmp1(1+xx:M1:end);
        tmp2 = exp(-2i*pi*(l1-1)/2/M1*(kk-1))*conv(h_pr.*exp(2i*pi*(0:length(h_pr)-1)*(kk-1)/M1), y2);
        xest2 = tmp2(1+M1/2+xx:M1:end);
        plot(real(xest1));
        pause;
    end
end


