SNR = [25 20 15 10 7]
estimation_error_fbmc = [7.5867e-04 0.0017 0.0093 0.1279 0.4359];
estimation_error_fbmc2 =[8.8712e-05 3.3960e-04 9.2516e-04 0.0029 0.0053]*1.12;
estimation_error_gfdm =[8.8712e-05 3.3960e-04 9.2516e-04 0.0029 0.0053];

xx = interp1(SNR, estimation_error_fbmc, 25:-1:7, 'pchip');
xx1 = interp1(SNR, estimation_error_fbmc2, 25:-1:7, 'pchip');
xx2 = interp1(SNR, estimation_error_gfdm, 25:-1:7, 'pchip');

plot(25:-1:7, xx)

