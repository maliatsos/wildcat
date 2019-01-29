%% main file
clear all
close all
clc

for num_test = 1:20
    %% initialization
    % number of Subcarriers of the Primary system
    Nfft = 1024;
    
    % number of Subchannels of the Primary System
    numOfSubchannels = 4;
    
    % Cyclic Prefix length percentage of the Primary System
    cp = 0.25;
    
    % Cells that contains the interference results
    PU_error = cell(1,Nfft*cp+1);
    CR_error = cell(1,Nfft*cp+1);
    
    for sync_pnt = cp*Nfft: -1 : 0
        
        % Guard subcarriers for the Primary System in each side (Total guard = 2*guard)
        guard = 16;
        
        % The subcarriers for each subchannel
        NsubCh = Nfft / numOfSubchannels;
        
        % Num of primary users
        pu_num = 1;
        
        % Num of Cognitive Radios to use the channels
        cr_num = 1;
        
        % Size of Primary User data (per user):
        size_of_pu_data = 500*256;
        
        % Size of Cognitive User data (per user):
        size_of_cr_data = 500*256;
        
        % The subchannels that will be occupied by the CR(s)
        num_cr_subCh = 1;
        
        % The subchannel(s) dedicated to CRs
        cr_subCh_ind = 0;
        
        % The modulation Rank of the Cognitive Radio(s)
        pu_modRank = 4;
        
        % The modulation Rank of the Cognitive Radio(s)
        cr_modRank = 4;
        
        %%  the M-DFT filter to be used by the Cognitive Radio System
        % It must be chosen so that:
        % M = numOfSubchannels/2
        % trans_bw = guard or guard/2 (even better);
        % groupdelay = cp/4
        
        % load('D:\Maliatsos_keep_out!\Matlab\PR_design_Koilpillai\pr_filt_2_32_0.28696_1e-015_1e-018_2.2204e-016.mat')
        load('D:\Maliatsos_keep_out!\Matlab\PR_design_Koilpillai\pr_filt_2_34_0.27094_1e-016_1e-018_2.2204e-016.mat')
        h_pr = h_pr/sqrt(M)/2;
        clear M e_ps tol_1 tol_2 Fstop theta_2 max_iter2
        
        
        %% COGNITIVE RADIO TRANSMITTER(S)
        CR_tx_sig = cell(1,cr_num);
        CR_ofdm_data = cell(1,cr_num);
        CR_ofdm_sig = cell(1,cr_num);
        numOfSymbols = zeros(1,cr_num);
        
        for k=1:cr_num
            [CR_tx_sig{k} CR_ofdm_data{k} CR_ofdm_sig{k} numOfSymbols(k)]=mdft_filtered_ofdm_tx(h_pr, size_of_cr_data, Nfft, numOfSubchannels, cp, 2*guard, num_cr_subCh, cr_modRank, cr_subCh_ind);
        end
        
        %% OFDM PRIMARY TRANSMITTER
        PU_tx_sig = cell(1,pu_num);
        PU_ofdm_data = cell(1,pu_num);
        PU_ofdm_sig = cell(1,pu_num);
        
        for k=1:pu_num
            subCh_ind = 1;
            [PU_tx_sig{k} PU_ofdm_data{k} PU_ofdm_sig{k}] = ofdma_tx(size_of_pu_data, Nfft, cp, pu_modRank, 2*guard, numOfSubchannels, subCh_ind);
        end
        %% CHANNEL + ADDITION OF SIGNALS...
        
        
        %% Adding Delay
        
        % define the total_sig length
        tot_sig_length = 0;
        for k =1:pu_num
            tot_sig_length = max([tot_sig_length length(PU_tx_sig{k})]);
        end
        for k =1:cr_num
            tot_sig_length = max([tot_sig_length length(CR_tx_sig{k})]);
        end
        
        total_sig = zeros(1,tot_sig_length);
        for k = 1:pu_num
            total_sig(1:length(PU_tx_sig{k})) = total_sig(1:length(PU_tx_sig{k})) + PU_tx_sig{k};
        end
        for k = 1:cr_num
            total_sig(1:length(CR_tx_sig{k})) = total_sig(1:length(CR_tx_sig{k})) + CR_tx_sig{k};
        end
        
        %% COGNITIVE RADIO RECEIVER(S)
        CR_rx_sig = cell(1,cr_num);
        CR_ofdm_out = cell(1,cr_num);
        for k=1:cr_num
            [CR_rx_sig{k} CR_ofdm_out{k}]=mdft_filtered_ofdm_rx(h_pr,total_sig , Nfft, numOfSubchannels, cp);
        end
        
        %% OFDM PRIMARY RECEIVER
        pu_time_sync_offset = zeros(1,pu_num);
        for k=1:pu_num
            pu_time_sync_offset(k) = sync_pnt; %cp*Nfft-1;
        end
        
        PU_ofdm_out = cell(1, pu_num);
        for k=1:pu_num
            PU_ofdm_out{k} = ofdm_rx(total_sig, Nfft, cp, pu_time_sync_offset(k));
        end
        
        % the number of symbols to be tested in interference analysis by the
        % routine
        num_of_symbols_tested = min([size(PU_ofdm_data{1},1) size(CR_ofdm_data{1}{cr_subCh_ind+1},1)]);
        
        for k = 1: num_of_symbols_tested
            PU_error{sync_pnt+1}(k,:) = abs(exp(2*(Nfft*cp - sync_pnt)*pi*1i*(subCh_ind*NsubCh+guard:NsubCh*(subCh_ind+1)-guard-1)/Nfft).*PU_ofdm_out{1}(k,subCh_ind*NsubCh+guard+1:NsubCh*(subCh_ind+1)-guard)-PU_ofdm_data{1}(k,subCh_ind*NsubCh+guard+1:NsubCh*(subCh_ind+1)-guard)).^2;
            CR_error{sync_pnt+1}(k,:) = abs(CR_ofdm_out{1}{cr_subCh_ind+1}(k,guard+1:NsubCh-guard)+CR_ofdm_data{1}{cr_subCh_ind+1}(k,guard+1:NsubCh-guard)).^2;
        end
        display(sync_pnt)
    end
    save(strcat('interference_test_',num2str(num_test)));
    clear PU_error CR_error
end

% for k=257:-1:0
%     subplot(2,1,1), plot(20*log10(mean(PU_error{k})))
%     subplot(2,1,2), plot(20*log10(mean(CR_error{k})))
%     pause
% end