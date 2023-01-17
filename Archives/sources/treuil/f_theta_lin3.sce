//génération tableau consigne_theta=f(consigne_lin)
//offset theta : extrémité bobine , au plus proche, 
//      càd bras moteur à l'opposé du bras de trancannage
// mouvement theta : 0 -> 1023
// mouvement linéaire : 0 -> 280mm
theta=2*%pi*(0:1:1024)/1024;
theta1=2*%pi*(0:1:511)/1024;
theta2=2*%pi*(512:1:1024)/1024;

R=70;
L=250;
Pas=5;
//si L et R de même ordre de grandeur
lineaire=R*(1-cos(theta))+sqrt(L^2-R^2*sin(theta)^2)-L;
lineaire1=R*(1-cos(theta1))+sqrt(L^2-R^2*sin(theta1)^2)-L;
lineaire2=-(R*(1-cos(theta2))+sqrt(L^2-R^2*sin(theta2)^2))+4*R+L;

//si  L >> R
lineaireb=R*(1-cos(theta));
lineaire1b=R*(1-cos(theta1));
lineaire2b=-R*(1-cos(theta2))+4*R;

clf;
plot2d(lineaire,theta*512/%pi,style=color("grey"));
plot2d(lineaireb,theta*512/%pi,style=color("magenta"));


if (0)  then
plot2d(theta1*512/%pi,lineaire1,style=color("black"));
plot2d(theta2*512/%pi,lineaire2,style=color("black"));
else
plot2d(lineaire1,(theta1*512/%pi),style=color("black"));
plot2d(lineaire2,(theta2*512/%pi),style=color("black"));
plot2d(lineaire1b,(theta1*512/%pi),style=color("red"));
plot2d(lineaire2b,(theta2*512/%pi),style=color("red"));

end;

if (1)  then


// on cherche les valeurs de theta correspondantes à lineaire* div 5mm
//  
j=1;
bound1=floor(lineaire1(512)/Pas)*Pas;
for i=0:Pas:bound1,
    [m,k]=min(abs(lineaire1-i));
    sol(j)=k-1;
    j=j+1;
 end;
for i=(bound1+Pas):Pas:4*R,
    [m,k]=min(abs(lineaire2-i));
    sol(j)=k+511;
    j=j+1;
 end;
sol=1024-gsort(sol,'r','d');
s='{';
 for i=1:57,
 s=s+string(sol(i))+',';
end;
s=s+'}';
disp(s);

plot2d(0:Pas:4*R,sol,style=color("green"));
//plot2d(0:5:280,sol,style=color("green"));

plot2d(0:5:280,0:5*1024/280:1024,style=color("grey"));

//x=[0:Pas:4*R];
//yi=smooth([x;sol'],1);
//plot2d(yi(1,:)',yi(2,:)',style=color("orange"));

//réduction vitesse aux points (0,0) ,(140,512) et (280,1024)
sol_1=sol;
sol_1(2)=sol_1(5)/4;
sol_1(3)=2*(sol_1(5)/4);
sol_1(4)=3*(sol_1(5)/4);

sol_1(28)=512+(sol_1(25)-512)/4;
sol_1(27)=512+2*(sol_1(25)-512)/4;
sol_1(26)=512+3*(sol_1(25)-512)/4;

sol_1(30)=512+(sol_1(33)-512)/4;
sol_1(31)=512+2*(sol_1(33)-512)/4;
sol_1(32)=512+3*(sol_1(33)-512)/4;

sol_1(56)=1024+(sol_1(53)-1024)/4;
sol_1(55)=1024+2*(sol_1(53)-1024)/4;
sol_1(54)=1024+3*(sol_1(53)-1024)/4;

sol_1=round(sol_1);
plot2d(0:Pas:4*R,sol_1,style=color("orange"));
 
 
s='{';
 for i=1:57,
 s=s+string(sol_1(i))+',';
end;
s=s+'}';
disp(s);

end;