function [X, varargout] = create_mc_data_frame(N1, e1, Lpreamble, oqam_flag, modrank)

% inputs:
% N1: number of symbols to be created (time axis)
% e1: the commutator vector - it practically defines the number of inputs
% to be created.
% Lpreamble: Number of preambles
% oqam_flag: Do you want to produce oqam? This means that we must separate
% qam to real-valued symbols 
% modrank: qpsk modulation rank

varargout = [];
%% Create Data:
Mprime1 = length(e1);                                               % Mprime1 should be less or equal to M1
if exist('preamble_symbols.mat', 'file')==0
    Xpre = repmat(randi([0 3], 1, Mprime1), Lpreamble, 1);          % Preambles - repeated qpsk symbols
%     Xpre = randi([0 3], Lpreamble, Mprime1);
    Xpre = qammod(Xpre,4);
    save('preamble_symbols.mat', 'Xpre');
else
    load('preamble_symbols.mat', 'Xpre');
end
X = randi([0 modrank-1], N1, Mprime1);                          % And the rest of the data....
X = [Xpre; qammod(X,modrank)];                                  % Modulate to qam and also add the preamble

% Matrices to host real-valued oqam symbols, if needed:
X1 = zeros(size(X));
X2 = zeros(size(X));

if (oqam_flag== 1)
    counter = 1;
    for nn = e1-1
        if mod(nn,2)==0
            X1(:,counter) = real(X(:,counter));
            X2(:,counter) = 1i*imag(X(:,counter));          % yes it should be real valued and add the 1i later in the procedure... but I do it here
        else
            X2(:,counter) = real(X(:,counter));
            X1(:,counter) = 1i*imag(X(:,counter));          % yes it should be real valued and add the 1i later in the procedure... but I do it here
        end
        counter = counter + 1;
    end
    X = [X1; X2];  
    
    % Send it also to the function output:
    varargout{1} = X1;
    varargout{2} = X1;
end
