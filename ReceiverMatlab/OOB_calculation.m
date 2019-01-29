function [OOB, UsefulPwr] = OOB_calculation(signal, signal_freq_index)

Signal = 1/sqrt(length(signal))*fft(signal);
Df = 1/length(signal);

PowerSignal = abs(Signal).^2;
UsefulPwr = sum(PowerSignal(signal_freq_index))/length(signal);
OOB = sum(PowerSignal(~signal_freq_index))/length(signal);