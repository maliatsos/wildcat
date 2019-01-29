function [ofdm_sync_point, ferr] = ofdm_synchronizer(RxSignal, ofdm_params)

R = zeros(length(RxSignal) - ofdm_params.L*ofdm_params.N, 1);
PP = zeros(length(RxSignal) - ofdm_params.L*ofdm_params.N, 1); 
P1 = zeros(length(RxSignal) - ofdm_params.L*ofdm_params.N, 1);
Pcross = zeros(length(RxSignal) - ofdm_params.L*ofdm_params.N - ofdm_params.Ncp, 1); 

P = zeros(ofdm_params.L);
for ii = 1 : ofdm_params.L
    for jj = ii : ofdm_params.L
        P(ii,jj) = ofdm_params.pattern(ii)*ofdm_params.pattern(jj)*sum(conj(RxSignal((ii-1)*ofdm_params.N+1:ii*ofdm_params.N)).*RxSignal((jj-1)*ofdm_params.N+1:jj*ofdm_params.N));
        P(jj,ii) = conj(P(ii,jj));
    end
end
R(1) = sum(diag(P));
P1(1) = P(1,2) + P(2,3) + P(3,4);
PP(1) = P(1,2) + P(1,3) + P(1,4) + P(2,3) + P(2,4) + P(3,4);

for kk = 2 : length(RxSignal) - ofdm_params.L*ofdm_params.N
    for ii = 1 : ofdm_params.L
        for jj = ii : ofdm_params.L
            P(ii,jj) = P(ii,jj) + ofdm_params.pattern(ii)*ofdm_params.pattern(jj)*conj(RxSignal(ii*ofdm_params.N + kk-1)).*RxSignal(jj*ofdm_params.N + kk-1) -...
                ofdm_params.pattern(ii)*ofdm_params.pattern(jj)*conj(RxSignal((ii-1)*ofdm_params.N + kk-1)).*RxSignal((jj-1)*ofdm_params.N + kk-1);
        end
    end
    R(kk) = sum(diag(P));
    P1(kk) = P(1,2) + P(2,3) + P(3,4);
    PP(kk) = P(1,2) + P(1,3) + P(1,4) + P(2,3) + P(2,4) + P(3,4);
end

[~, ofdm_sync_point_coarse] = max(abs(PP(ofdm_params.Ncp+1:end)));
ferr = angle(P1(ofdm_sync_point_coarse+ofdm_params.Ncp))*ofdm_params.Fs/(2*pi*ofdm_params.N);

%% Compensate the frequency offset:
RxSignal_new = RxSignal.*exp(-2i*pi*(0:length(RxSignal)-1).'*ferr/ofdm_params.Fs);

all_preamble = zeros(ofdm_params.L*ofdm_params.N, 1);
for ii = 1 : ofdm_params.L
    all_preamble((ii-1)*ofdm_params.N + 1: ii*ofdm_params.N) = ofdm_params.pattern(ii)*ofdm_params.preamble;
end
all_preamble = [all_preamble(end-ofdm_params.Ncp+1:end); all_preamble];

for kk = 1 : length(RxSignal_new) - ofdm_params.L*ofdm_params.N - ofdm_params.Ncp
    Pcross(kk) = sum(conj(RxSignal_new(kk : kk-1+ofdm_params.L*ofdm_params.N+ofdm_params.Ncp)).*all_preamble);
end

[~, ofdm_sync_point] = max(abs(Pcross) + abs(PP(ofdm_params.Ncp+1:end)));

ferr = angle(P1(ofdm_sync_point+ofdm_params.Ncp))*ofdm_params.Fs/(2*pi*ofdm_params.N);
