function [sync_point, freq_offset] = synchronize_ref_preamble(R)

P = zeros(size(R,1), 1);
for ll = 2 : size(R,2)
    P = P + R(:,ll);
end
[val, sync_point] = max(abs(P)./R(:,1));

freq_offset = angle(R(sync_point, 2))/2/pi;


