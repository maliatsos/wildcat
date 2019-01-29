function [P, R] =  corr_synchronizer(signal, Lpreamble, M, prefix, suffix)

% Autocorrelation synchronization:
% prefix: Cyclic prefix or Zero prefix (if any)
% suffix: Cyclic suffix or Zero suffix (if any)

Mall = M + prefix + suffix;
P1 = zeros(length(signal) - Lpreamble*Mall + 1, 1);
P2 = zeros(length(signal) - Lpreamble*Mall + 1, 1);
R = zeros(length(signal) - Lpreamble*Mall + 1, 1);
R(1) = sum(abs(signal(1:Lpreamble*Mall).^2));


for ll = 1 : Lpreamble-1
    P1(1) = P1(1) + sum(signal((ll-1)*Mall + 1: ll*Mall).*conj(signal(ll*Mall+1: (ll+1)*Mall)));
end
P2(1) = sum(signal(1:Lpreamble*Mall/2).*conj(signal(Lpreamble*Mall/2+1:Lpreamble*Mall)));


for nn = 2 : length(R)
    R(nn) = R(nn-1) + abs(signal(Lpreamble*Mall + nn -1))^2 -  abs(signal(nn -1))^2; 
    P1(nn) = P1(nn-1);
    for ll = 1 : Lpreamble-1
        P1(nn) = P1(nn) - signal((ll-1)*Mall + nn -1).*conj(signal(ll*Mall + nn-1)) +  signal(ll*Mall+nn-1).*conj(signal((ll+1)*Mall + nn - 1));
    end
    P2(nn) = P2(nn-1) - signal(nn-1).*conj(signal(Lpreamble*Mall/2+nn-1)) + signal(Lpreamble*Mall/2+ nn-1).*conj(signal(Lpreamble*Mall+nn-1));
end
P = P1+P2;
