function [signal, Pavg] = normalize_for_usrp(signal, target_max_output_ampl)


%% Normalize for usrp
max_out = max(max(max(real(signal))),max(max(imag(signal))));
signal = (target_max_output_ampl/max_out)*signal;

% optional printouts
Pavg = mean(abs(signal).^2);
