function f= ps_ccal(a, b)

if (a == b || a + b == 0)
    f = (251*pi)/512 + (sin(2*pi*b)/4 - sin((5*pi*b)/128)/4)/b;
%     f = (63*pi)/128 + (sin(2*pi*b)/4 - sin((pi*b)/32)/4)/b;
%     f = (251*pi)/512 + (sin(2*pi*b)/4 - sin((5*pi*b)/128)/4)/b;
%     f = (123*pi)/256 + (sin(2*pi*b)/4 - sin((5*pi*b)/64)/4)/b;
%     f =(61*pi)/128 + (sin(2*pi*b)/4 - sin((3*pi*b)/32)/4)/b;
%     f = (31*pi)/64 + (sin(2*pi*b)/4 - sin((pi*b)/16)/4)/b;
    %     f = (63*pi)/128 + (sin(2*pi*b)/4 - sin((pi*b)/32)/4)/b;
    %     f = (125*pi)/256 + (sin(2*pi*b)/4 - sin((3*pi*b)/64)/4)/b;
else
    f = sin(pi*(a + b))/(2*(a + b)) - sin((5*pi*(a + b))/256)/(2*(a + b)) + sin(pi*(a - b))/(2*(a - b)) - sin((5*pi*(a - b))/256)/(2*(a - b));
    %     f = sin(pi*(a + b))/(2*(a + b)) - sin((5*pi*(a + b))/128)/(2*(a + b)) + sin(pi*(a - b))/(2*(a - b)) - sin((5*pi*(a - b))/128)/(2*(a - b));
%     f = sin(pi*(a + b))/(2*(a + b)) - sin((3*pi*(a + b))/64)/(2*(a + b)) + sin(pi*(a - b))/(2*(a - b)) - sin((3*pi*(a - b))/64)/(2*(a - b));
%     f =sin(pi*(a - b))/(2*a - 2*b) - sin((pi*(a - b))/32)/(2*a - 2*b) + sin(pi*(a + b))/(2*a + 2*b) - sin((pi*(a + b))/32)/(2*a + 2*b);
%    f = sin(pi*(a - b))/(2*a - 2*b) - sin((pi*(a - b))/64)/(2*a - 2*b) + sin(pi*(a + b))/(2*a + 2*b) - sin((pi*(a + b))/64)/(2*a + 2*b);
%    f = sin(pi*(a + b))/(2*(a + b)) - sin((3*pi*(a + b))/128)/(2*(a + b)) + sin(pi*(a - b))/(2*(a - b)) - sin((3*pi*(a - b))/128)/(2*(a - b)); 
end
