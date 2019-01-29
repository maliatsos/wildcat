function channel_estimate = generic_estimator(RxSignal, preambles, chan_length, l1)

% RxSignal: received Signal,
% preambles: the preambles,
% chan_length: the maximum channel length
% l1: the filter(s) length

Xpre = zeros(length(preambles), chan_length);
% Add some zeros in order to make easier the construction of the Xpre matrix:
preambles = [zeros(chan_length-1,1); preambles];
for ii = 1 : length(preambles)-chan_length+1
    Xpre(ii,:) = preambles(ii-1+chan_length:-1:ii);
end
gd = floor(l1/2);
Xpre = Xpre(gd+1:end-l1, :);
cond(Xpre'*Xpre)
y = RxSignal(gd+1:gd+size(Xpre,1));
equalizer = (Xpre'*Xpre)^-1*Xpre';
channel_estimate = equalizer*y;
