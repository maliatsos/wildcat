function yp = resampleSINC(y,m)
%   TIME-DOMAIN SINC INTERPOLATION (RESAMPLING)
u = linspace(0,length(y),length(y)*m); 

x = (0:length(y)-1)';

if size(y,1)==1
    yp = zeros(1, size(y,2)*m); 
else
    yp = zeros(size(y,1)*m,1); 
end
    
for i=1:length(u)
    yp(i) = sum(y(:).*sinc(x-u(i)));
end

