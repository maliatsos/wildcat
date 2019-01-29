 function g = PHYDYAS(K)

% Overlappng factor = 4 (Default)

H1=0.971960;
H2=sqrt(2)/2;
H3=0.235147;

norm = 1+2*(H1+H2+H3);

g(1:4*K)=0;

for i=1:4*K-1
    g(1+i)=1-2*H1*cos(pi*i/(2*K))+2*H2*cos(pi*i/K)-2*H3*cos(pi*i*3/(2*K));
end
g = g/norm;



