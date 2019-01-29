function [all_channel, Channel_estimate, channel_estimate]  = tmp_channel_estimation(signal, RefSignal, M, symbol_size, guard_front, guard_back, Ncp, Ncs, noise_pwr, e1)

useful_signal = signal(guard_front+1:end-guard_back,:);
RefSignal = RefSignal(guard_front+1:end-guard_back,:);
useful_repetitions = floor(size(useful_signal,1)/symbol_size);

input_signal = zeros(symbol_size, M, useful_repetitions);
ref_signal = zeros(symbol_size, M, useful_repetitions);

for kk = 1 : useful_repetitions
    input_signal(:, :, kk) = useful_signal((kk-1)*symbol_size+1:kk*symbol_size, :);
    ref_signal(:,:,kk) = RefSignal((kk-1)*symbol_size+1:kk*symbol_size, :);
end

% Frequency Domain:
Input_signal = fft(input_signal(Ncp+1:end-Ncs,: , :), M, 1);
Ref_signal = fft(ref_signal(Ncp+1:end-Ncs,: , :), M, 1);

Channel_estimate = zeros(size(Input_signal));

for mm = 1 : useful_repetitions
   for ll = e1
        tmp1 = squeeze(Input_signal(:,ll,mm));
        tmp2 = squeeze(Ref_signal(:,ll,mm));
%         max_val = max(abs(squeeze(Ref_signal(:,ll,mm))).^2);
%         ind = abs(tmp1).^2>max_val/1000;
        ind = ll;
        tmp = zeros(size(tmp1));
        tmp(ind) = tmp1(ind).*conj(tmp2(ind))./( abs(tmp2(ind)).^2 + noise_pwr);
        Channel_estimate(:,ll,mm) = tmp;        
   end
end
Channel_estimate = mean(Channel_estimate,3);
all_channel = zeros(M, 1);
all_indexes = zeros(M, 1);
for ll = 1 : M
   all_channel = all_channel + Channel_estimate(:,ll);
   all_indexes = all_indexes + double(abs(Channel_estimate(:,ll))>0);
end
all_channel =all_channel./all_indexes;
channel_estimate = ifft(Channel_estimate, M, 1);
