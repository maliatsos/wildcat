function H = create_filt(theta,M,m)

% This is maybe the most significant, crucial function in the PR filter
% desing procedure based on paper "Cosine modulated FIR filter Banks" by
% Koilpillai and Vaidyanathan... Part of the pr_filter_design function...

% It connects parameters theta with the filter coefficients and ensures
% that the cosine filter bank is indeed a PR !!

% A stable digital filter with real bounded coefficients P(z) can be
% implemented with a nonrecursive, cascaded two channel lossless lattice
% stracture together with its pair Q(z) if P*(-z)'*P(z)+Q*(-z)'*Q(z)=1

% In order to ensure PR it is given that (eq.20)
% G_k*(-z)G_k(z)+G_M+k*(-z)G_M+k(z) = 1/2/M (a constant anywayz)

% Therefore each pair can be implemented with the lattice

% According to eq(32) the lattice transfer functions can be initialized
% with:
G=cell(2*M,M/2);
for k=1:M/2
    G{k,1} = cos(theta(k,1));
    G{M+k,1} = sin(theta(k,1));
end
% In the cell matrix G we save the transfer function of the p-th stage of
% the lattice... For example G{k,p} is the transferfunction of the p-th
% stage of the lattice and the k-th polyphase.
% SEE Fig.2 FOR THE IMPLEMENTATION

% The other lattice stages are updated according to eq.(33). This equation
% says that the k-th polyphase is given by the k-th polyphase of the
% previous section multiplied by cosine(theta(k,p)) and a delayed by one
% delay version of k+M-th polyphase multiplied by the sine(theta(k,p)).
for k=1:M/2
    for p=1:m-1
        G{k,p+1}=[cos(theta(k,p+1))*G{k,p} 0]+[0 sin(theta(k,p+1))*G{k+M,p}];
        G{k+M,p+1}=[sin(theta(k,p+1))*G{k,p} 0]-[0 cos(theta(k,p+1))*G{k+M,p}];
    end
end
% G{k+M,p+1} is also extracted by eq(33);

% Now we create the filter by the polyphases........
H = zeros(1,2*m*M); % the length of the filter =2*m*M
for k = 1:M/2 
    H(k:2*M:end)=G{k,m};  % inserting the k-th polyphase
    H(end-k+1:-2*M:1)=G{k,m}; % The FIR filter is symmetric! Therefore we also know the 2M-k polyphase!!
    H(k+M:2*M:end)=G{k+M,m};  % inserting the M+k th polyphase (that was simultaneously extracted!)
    H(end-k-M+1:-2*M:1)=G{k+M,m}; % Same as above!!
end
% We see that we need to initialize and optimize M/2 polyphases as the M/2
% polyphases are simultaneously extracted and the others are defined by
% symmetry!!

