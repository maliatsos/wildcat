for k = [1 2 25]
    load(strcat('C:\Documents and Settings\Kostas\Desktop\Matlab inside\WorkingMatlab\my_win_psd_0.',num2str(k),'.mat'));
    plot(10*log10(PSD2))
    hold all
end