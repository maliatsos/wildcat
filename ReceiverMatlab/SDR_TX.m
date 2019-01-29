%% Create signal:
main_tx_sdr;

%% USRP PARAMETERS
Fs = 3.125e6;
Fc = 1.8e9;
TxGain = 20;

%% setup USRP

% check connected boards;
htx = comm.SDRuTransmitter();

% B210
% htx.Platform            = 'B210';
% htx.SerialNum           = 'F571EC';
% htx.MasterClockRate     = 10e6;
% htx.CenterFrequency     = fc;
% htx.InterpolationFactor = htx.MasterClockRate/fs;
% htx.Gain                = TxGain;
% htx.UnderrunOutputPort  = true;

% N210
htx.Platform            = 'N200/N210/USRP2';
htx.IPAddress           = '192.168.10.3';
htx.CenterFrequency     = Fc;
htx.InterpolationFactor = 100e6/Fs;
htx.Gain                = TxGain;
htx.EnableBurstMode     = false;
htx.UnderrunOutputPort  = true;


htx.info();

%% Transmit! 

while 1
    htx(total_sig(:));
end