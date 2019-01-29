function D = downsampling_mtx(dim1, Q, o)

if o>=Q
    error('o should be from 0 to Q-1');
end
    
dim2 = floor(dim1/Q);
D = zeros(dim2, dim1);
tmp = upsampling_mtx(dim2, Q, o)';
D(:,1:size(tmp,2)) = tmp;