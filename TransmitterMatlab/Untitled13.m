xx =zeros(size(Stage5));
for p = 1 : P
    for ll = 1 : M1
        tmp = Stage4(1+(p-1)*size(Stage4,1)/2:p*size(Stage4,1)/2,ll).*exp(-2i*pi*(0:size(Stage4,1)/2-1)'*(ll-1)/M1);
        xx(1+(p-1)*size(Stage4,1)/2:p*size(Stage4,1)/2,ll) = tmp;
    end
end

yy =zeros(size(Stage5,1), size(Stage5,2));
for p = 1 : P
    for ll = 1 : M1
        tmp = conv(h1(end-1:1),xx(1+(p-1)*size(Stage4,1)/2:p*size(Stage4,1)/2,ll));
        yy(1+(p-1)*size(Stage5,1)/2:p*size(Stage5,1)/2,ll) = tmp(1:size(Stage5,1)/2);
    end
end
