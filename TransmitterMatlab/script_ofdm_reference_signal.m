% number of OFDM samples:
Nref = 256;
% symbol repetition:
Lref = 4;
% Repetition pattern:
pattern_ref = [1 1 -1 1];
% Create ref signal:
total_sig1 = create_ofdm_reference_signal(Nref, Lref, pattern_ref);
% Insert cyclic prefix only for the first preamble:
Ncp = Nref*0.25;
total_sig1 = [total_sig1(end-Ncp+1:end); total_sig1];

ofdm_params = struct('N', Nref, 'L', Lref, 'pattern', pattern_ref, 'preamble', total_sig1(Ncp+1:Nref+Ncp), 'Ncp', Ncp, 'Fs', Fs);
save('ofdm_signal.mat', 'ofdm_params');