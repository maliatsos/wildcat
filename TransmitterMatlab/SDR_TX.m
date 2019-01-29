%% Create signal:
main_tx_sdr;

%% USRP PARAMETERS
Fs = 3.125e6;
Fc = 2.3e9;
TxGain = 70;

%% setup USRP

% check connected boards;
htx = comm.SDRuTransmitter();

% B210
htx.Platform            = 'B200';
htx.SerialNum           = '313191B';
htx.MasterClockRate     = 12.5e6;
htx.CenterFrequency     = Fc;
htx.InterpolationFactor = htx.MasterClockRate/Fs;
htx.Gain                = TxGain;
htx.UnderrunOutputPort  = true;

% N210
% htx.Platform            = 'N200/N210/USRP2';
% htx.IPAddress           = '192.168.10.3';
% htx.CenterFrequency     = Fc;
% htx.InterpolationFactor = 100e6/Fs;
% htx.Gain                = TxGain;
% htx.EnableBurstMode     = true;
% htx.UnderrunOutputPort  = true;


htx.info()

%% Transmit! 

while 1
    htx(total_sig(:));
end