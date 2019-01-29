function U = upsampling_mtx(dim1, L, o)

if o>=L
    error('o should be from 0 to L-1');
end

U = zeros(L*dim1, dim1);
for kk = 1 : dim1
    U((kk-1)*L+1 + o, kk) = 1;
end