load('C:\Users\Revolver Republic\Desktop\OrcaFBMC\Filters\mdft_iter_filt_128_256_fstop0.01117.mat')
h1 = h_pr;
%h1 =g(:).';
N1 = 40;
M1 = 128;

create_some_random_channels;

b1 = zeros(M1, N1*M1);
for ii = 1 : M1
        b1(ii, 1:length(h1)) = h1.*exp(2i*pi*(0:length(h1)-1)*(ii-1)/M1);
end
G = zeros(N1*M1);
for kk = 1 : N1
    for ii = 1 : M1
        G(:,ii + (kk-1)*M1) = circshift(b1(ii,:).', M1*(kk-1));
    end
end

num_tests = 1000;
resultsOOB = zeros(num_tests, 1); resultsUse = zeros(num_tests, 1);
for mm =1 : num_tests
    Data = randi([0,3], M1, N1);
    Data = qammod(Data, 4);
    Data(M1/4+1:end-M1/4+1,:)=0;
    
    d = Data(:);
    x = G*d; y_size = length(x);
    x = [x(end-640+1:end); x];
    
    y = conv(channels1(mm,:), x);
    y = y(1:y_size);

    yp = y./sqrt(mean(abs(y).^2));
    yyp = [yp; zeros(15*length(yp), 1);];
    upsize = 16*length(yp);
    signal_index = zeros(upsize, 1);
    signal_index(1:16*length(yp)/4) = 1;
    signal_index(end-16*length(yp)/4+1:end) = 1;
    
    [OOB, UsefulPwr] = OOB_calculation(yyp, logical(signal_index));
    resultsOOB(mm) = OOB;
    resultsUse(mm) = UsefulPwr;

end

keyboard
freq = (0:length(yyp)-1)/length(yyp);
noise = sqrt(1/20000)*(randn(size(yyp)) + randn(size(yyp)));
plot(freq, 20*log10(fftshift(abs(fft(yyp+noise)))));
hold all
plot(freq, fftshift(50*signal_index))
