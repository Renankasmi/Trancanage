//delog fichier .ttc crée par trancannage_pc5.exe

nb_data=1662;
u=file('open','D:\dataPIC\treuil\log_9.tct','unknown');
data=read(u,nb_data,9);
eepr=read(u,12,1);
file('close',u);
tour_bob=data(:,1);
vit_bob=data(:,2);
cons_theta=data(:,3);
pos_theta=data(:,4);
courant=data(:,5);//mA
tension=data(:,6);//1/10ème V
Ep0=data(:,7);
Epu=data(:,8);
charge_uc=data(:,9);

version=eepr(1,1);
flags=eepr(2,1);//b0: 0:rotation constante/1:mouvement linéaire
offset_aeat6600=eepr(3,1);
larg_bob=eepr(4,1);
freq_boucle=eepr(5,1);
Kp_I=eepr(6,1);
Ki_I=eepr(7,1);
I_lim=(eepr(8,1)-512)*39;
Kp=eepr(9,1);
Ki=eepr(10,1);
Kd=eepr(11,1);
pas=eepr(12,1);

dt=1/freq_boucle;
t=0:0.1:(nb_data-1)*0.1;
clf;

if (1) then
//plot2d(t,tour_bob,style=color("black"));
plot2d(t,vit_bob,style=color("blue"));
plot2d(t,cons_theta,style=color("red"));
plot2d(t,pos_theta,style=color("dark green"));
plot2d(t,courant/5,style=color("green"));
plot2d(t,tension,style=color("grey"));
//  plot2d(t,Ep0,style=color("yellow"));
 // plot2d(t,Epu,style=color("brown"));
 // plot2d(t,charge_uc,style=color("purple"));
// hl=legend(['vitesse bobine(rpm)';'consigne';'position';'courant/5(mA)';'tension*10(V)'],a=1);

//find(courant==max(courant)) , pour récupérer l'index 
i=find(courant==max(courant));
disp(courant(i(1)),"max courant");
i=find(tour_bob==max(tour_bob));
disp(tour_bob(i(1)),"tours bobine");
i=find(vit_bob==max(vit_bob));
disp(vit_bob(i(1)),"vitesse_bobine");
i=find(tension==max(tension));
disp(tension(i(1)),"max tension");
i=find(tension==min(tension));
disp(tension(i(1)),"min tension");
end;
if (1) then

nb_data=23;
u=file('open','D:\dataPIC\treuil\4BFGPO14.IGC','unknown');
data=read(u,nb_data,1,'(a)');
file('close',u);
h = eval(part(data,2:3));
m= eval(part(data,4:5));
s= eval(part(data,6:7));
t=h*3600+m*60+s;
alt= eval(part(data,31:35));

offset_t=89;
t=t-t(1)+offset_t;
plot2d(t,alt,style=color("orange"));
 hl=legend(['vitesse bobine(rpm)';'consigne';'position';'courant/5(mA)';'tension*10(V)';'altitude gps(m)'],a=1);
 i=find(alt==max(alt));
 delta_alt=alt(i(1));
 i=find(alt==min(alt));
 delta_alt=-alt(i(1))+delta_alt;
disp(delta_alt,"max altitude");
end;
//BMP export
//xs2bmp(0,'D:\dataPIC\treuil\log.bmp');
