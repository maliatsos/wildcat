function sync_point = generic_synchronizer(RxSignal, InSignal, Lpreamble, M, l1, varargin)

% RxSignal: received signal vector;
% InSignal: Preamble at the transmitter output (after all processing).
% Lpreamble: Number of preambles:
% M: Number of samples per wideband symbol (no extensions).
% l1: Filter length (as a sum of all filter lengths).
% varargin{1} = prefix: Cyclic prefix or Zero prefix (if any together)
% varargin{2} = suffix: Cyclic suffix or Zero suffix (if any together)
prefix = 0; suffix = 0;
if ~isempty(varargin)
    prefix = varargin{1};
    if length(varargin) == 2
        suffix = varargin{2};
        if isempty(prefix)
           prefix = 0; 
        end
    end
end

%% Synchronizer:
P = crosscorr_synchronizer(RxSignal, InSignal);
% [PP,RR] = corr_synchronizer(RxSignal, Lpreamble, M, prefix, suffix);
% PP = PP(floor(l1/2)+1:end);
PP = ones(length(P),1);
[~,sync_point] = max(abs(PP(1:length(P))).*abs(P));