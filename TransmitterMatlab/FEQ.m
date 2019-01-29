function newSignal  = FEQ(RxSignal, sync_point, N, M, l1, all_channel, e, noise_pwr)

% l1: filter length -1
% N number of time wideband symbols;
% M number of channels
% sync_point: synchronization point from start of RxSignal
% all_channel: the wideband channel estimate
% e: a vector with the indexes of used subchannels e.g. 1:M

interpChannel = interp1(e(:)-1, all_channel(e(:)), (0:1/N:M-1/N)', [], 'extrap');

% ZeroPrefix the frame:
end_point = sync_point + N*M + l1- 1;
if length(RxSignal)>end_point
    tmpSignal = RxSignal(sync_point: sync_point + N*M + l1- 1);
else
    tmpSignal = [RxSignal(sync_point : end); zeros(end_point-length(RxSignal),1)];
end
newSignal = tmpSignal(1:end-l1+1); newSignal(1:l1-1) = newSignal(1:l1-1) + newSignal(end-l1+2:end);
NewSignal = fft(newSignal, N*M);

newSignal = ifft(NewSignal.*conj(interpChannel)./(abs(interpChannel).^2+noise_pwr));