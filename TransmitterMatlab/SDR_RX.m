
Fs = 3125000;
fc = 1.8e9;
RxGain = 27;
Nsamples_per_USRP_packet = 10000;
num_blocks = 60;

hrx = comm.SDRuReceiver();

%B210
% hrx.Platform            = 'B210';
% hrx.SerialNum           = 'F571D7';
% hrx.MasterClockRate     = 50e6;
% hrx.CenterFrequency     = fc;
% hrx.DecimationFactor    = htx.MasterClockRate/fs;
% hrx.Gain                = RxGain;

% N210
hrx.Platform            = 'N200/N210/USRP2';
hrx.IPAddress           = '192.168.10.3';
hrx.CenterFrequency     = fc;
hrx.DecimationFactor    = 100e6/Fs;
hrx.Gain                = RxGain;

hrx.SamplesPerFrame     = Nsamples_per_USRP_packet;
hrx.OutputDataType      = 'double';

hrx.info()

% store captured signal
rx_signal = complex( zeros(hrx.SamplesPerFrame*num_blocks,1),zeros(hrx.SamplesPerFrame*num_blocks,1) );

blockIX = 0;
while blockIX<num_blocks
    
    [data, len] = step(hrx);
    if len>0
        rx_signal(blockIX*hrx.SamplesPerFrame+1:(blockIX+1)*hrx.SamplesPerFrame) = data;
        blockIX = blockIX + 1;
    end
end
release(hrx);
rx_signal = rx_signal(end/2:end);

save('USRP_FBMC_Capture.mat','rx_signal');