
num_tests = 1000;
channel1 = [1+0.87i 0.2+0.1i 0.1+0.2i];
channel2 = [0.5i-0.8i -0.2i 0.2+0.1i 0.1+0.2i 0.01i-0.01];

channels1 = zeros(num_tests, length(channel1));
channels2 = zeros(num_tests, length(channel2));
for kk = 1 : num_tests
    channels1(kk,:) = channel1 + sqrt(0.05/2)*(randn(1,length(channel1)) + 1i*randn(1,length(channel1)));
    channels2(kk,:) = channel2 + sqrt(0.03/2)*(randn(1,length(channel2)) + 1i*randn(1,length(channel2)));
end

curve = [0.5 0.75 1 0.75 0.5];
ind = [-512 0 512 1023 1535];
tt= interp1(ind, curve, 0:1023, 'spline');

Channels1 = fft(channels1, 1024, 2);
Channels2 = fft(channels2, 1024, 2);

Channels1 = Channels1.*tt;
Channels2 = Channels2.*tt;

channels1 = ifft(Channels1, 1024, 2);
channels2 = ifft(Channels2, 1024, 2);
channels1 = [channels1(:,end) channels1(:,1:10)];
channels2 = [channels2(:,end) channels2(:,1:10)];


% channel = [0.5i-0.8i -0.2i 0.2+0.1i 0.1+0.2i 0.01i-0.01];