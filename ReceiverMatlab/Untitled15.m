% load('C:\Users\Revolver Republic\Desktop\OrcaMatlab\unified\Unification\PR_design_Koilpillai\pr_filt_64_1_0.023438_1e-06_1e-06_2.2204e-16.mat')
load('phydias64.mat')
h_pr = g;
y11 = zeros(size(X1,1)*M1+length(h_pr)-1,1);
y22 = zeros(size(X2,1)*M1+length(h_pr)-1,1);

Y1 = X1*E1; Y2 = X2*E1;
for kk = 1:M1
    if mod(kk,2)==1
        tt1 = upsample(Y1(:,kk), M1);
        tt2 = upsample(Y2(:,kk), M1, M1/2);
        tmp1 = conv(exp(2i*pi*(0:length(h_pr)-1)*(kk-1)/M1).*h_pr, tt1);
        tmp1 = exp(-2i*pi*(l1-1)/2/M1*(kk-1))*tmp1;
        tmp2 = conv(exp(2i*pi*(0:length(h_pr)-1)*(kk-1)/M1).*h_pr, tt2);
        tmp2 = exp(-2i*pi*(l1-1)/2/M1*(kk-1))*tmp2;
    end
    y11 = y11 + tmp1;
    y22 = y22 + tmp2;
end
y = y11 + y22;


rx_signal = y11 + y22;
Pavg =  mean(abs(rx_signal).^2);


xx1 = [];
xx2 = [];

for kk = 1 : M1
    for xx = 0:M1-1
        xx = 0;
        tt = conv(h_pr.*exp(2i*pi*(0:length(h_pr)-1)*(kk-1)/M1), rx_signal)*exp(-2i*pi*bcas1*(l1-1)/2/M1*(kk-1));
        tt1 = tt(xx+1:M1:end);
        tt2 = tt(M1/2+xx+1:M1:end);
    end
    if mod(kk-1,2)==0
        tt1 = real(tt1);
        tt2 = imag(tt2);
    else
        tt2 = real(tt2);
        tt1 = imag(tt1);
    end
    
    xx1 = [xx1; tt1];
    xx2 = [xx2; tt2];
end