function ofdm_out = ofdm_rx(sig_in, Nfft, cp, time_sync_offset)

sig_size = size(sig_in, 2);
numOfSymbols = ceil(sig_size/(Nfft*(1+cp)));
ofdm_out = zeros(numOfSymbols, Nfft);

counter = 1;
k = 1;
while counter<sig_size - Nfft - time_sync_offset
    tmp_sig = sig_in(counter + time_sync_offset  : counter + time_sync_offset + Nfft -1);
    tmp_ofdm = fft(tmp_sig, Nfft);
    ofdm_out(k,:) = tmp_ofdm;
    k = k+1;
    counter = counter + Nfft*(1+cp);
end
