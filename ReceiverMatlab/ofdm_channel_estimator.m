function ofdm_channel_estimate = ofdm_channel_estimator(signal, ofdm_params)

%% Estimate from the small parts...
Preamble = fft(ofdm_params.preamble); ind = abs(Preamble)>1e-6;
channel_estimate = zeros(ofdm_params.N,1);
tmp = fft(signal(ofdm_params.Ncp+1:ofdm_params.Ncp+ofdm_params.N));
channel_estimate(ind) = (sqrt(ofdm_params.N)/sum(ind))*tmp(ind)./Preamble(ind);

for ii = 2 : ofdm_params.L
    if ofdm_params.pattern(ii-1)==ofdm_params.pattern(ii)
        tmp1  = fft(signal(ofdm_params.Ncp+(ii-1)*ofdm_params.N+1:ofdm_params.Ncp+ii*ofdm_params.N));
        tmp = zeros(ofdm_params.N,1);
        tmp(ind) = (sqrt(ofdm_params.N)/sum(ind))*tmp1(ind)./Preamble(ind);
        channel_estimate = [channel_estimate tmp]; %#ok<AGROW>
    end
end

% Zero all paths less than 30 dB:
% for ii = 1 : size(channel_estimate,2)
%     channel_estimate(:,ii) = sqrt(ofdm_params.N)*ifft(channel_estimate(:,ii));
%     C = 20*log10(abs(channel_estimate(:,1)));
%     ind = C<-30;
%     channel_estimate(ind, ii) = 0;
% end
ofdm_channel_estimate =channel_estimate;
