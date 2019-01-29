function out = generate_chest_error(in)

snr = [25 22.3 15 12 10 7];
channel_estimate_error = [0.0001 0.0002 0.001 0.002 0.03 0.01];

out = interp1(snr, channel_estimate_error, in, 'pchip', 'extrap');