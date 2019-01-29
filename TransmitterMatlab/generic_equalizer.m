function equalized_signal = generic_equalizer(RxSignal, channel, start_point, end_point)

% RxSignal: received Signal,
% channel: the channel estimate,
% l1: the filter(s) length
lag = end_point - start_point +1;
sig_out_size = lag; sig_in_size = lag;
C = zeros(sig_out_size, sig_in_size);

% Add some zeros in order to make easier the construction of the Xpre matrix:
channel = [zeros(sig_in_size-1,1); channel; zeros(sig_in_size,1)]; 
[~,ind] = max(abs(channel));
for ii = 1 : sig_out_size
    C(ii,:) = channel(ii-1+ind:-1:ii+ind-sig_in_size);
end

y = RxSignal(start_point:end_point );
equalizer = (C'*C)^-1*C';
equalized_signal = equalizer*y;
