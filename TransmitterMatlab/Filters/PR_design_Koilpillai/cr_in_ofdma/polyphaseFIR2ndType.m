function hpoly=polyphaseFIR2ndType2(h,M)

%polyphase partition of an FIR filter..
%works together with a properly commutated signal...

hpoly=zeros(M,floor(length(h)/M));
for i=1:M
    temp=h(i:M:end);
    hpoly(M+1-i,1:length(temp))=temp;
end
