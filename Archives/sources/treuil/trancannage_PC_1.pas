unit trancannage_PC_1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Grids, StdCtrls, Menus, ComCtrls, StrUtils, Gauges,
  Spin, Math;

type
  TForm1 = class(TForm)
    StringGrid1: TStringGrid;
    Timer_loop: TTimer;
    Timer_start: TTimer;
    TabControl1: TTabControl;
    connect: TButton;
    cb_port: TComboBox;
    rg_lin: TRadioGroup;
    V1: TProgressBar;
    V2: TProgressBar;
    V3: TProgressBar;
    V4: TProgressBar;
    V5: TProgressBar;
    V6: TProgressBar;
    V7: TProgressBar;
    V8: TProgressBar;
    prog_eep: TButton;
    Memo1: TMemo;
    tb_k1: TTrackBar;
    lb_k1: TLabel;
    tb_k2: TTrackBar;
    tb_k3: TTrackBar;
    tb_k4: TTrackBar;
    lb_k2: TLabel;
    lb_k3: TLabel;
    lb_k4: TLabel;
    btn_neutre: TButton;
    btn_store_offset: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    btn_inc_consigne: TButton;
    cb_v1: TComboBox;
    cb_v2: TComboBox;
    cb_v3: TComboBox;
    cb_v4: TComboBox;
    cb_v5: TComboBox;
    cb_v6: TComboBox;
    cb_v7: TComboBox;
    cb_v8: TComboBox;
    cb_reg1: TComboBox;
    cb_reg2: TComboBox;
    cb_reg3: TComboBox;
    lb_reg1: TLabel;
    lb_reg2: TLabel;
    lb_reg3: TLabel;
    rg_roll: TRadioGroup;
    rg_tilt: TRadioGroup;
    cb_reverse: TCheckBox;
    max_tk1: TSpinEdit;
    max_tk2: TSpinEdit;
    max_tk3: TSpinEdit;
    max_tk4: TSpinEdit;
    btn_limL: TButton;
    btn_raz_limites: TButton;
    btn_zero_as: TButton;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    Button1: TButton;
    Button2: TButton;
    btn_calibr_acc: TButton;
    Timer_ic: TTimer;
    cb1: TCheckBox;
    cb2: TCheckBox;
    cb3: TCheckBox;
    cb4: TCheckBox;
    cb5: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Timer_loopTimer(Sender: TObject);
    procedure Timer_startTimer(Sender: TObject);
    procedure connectClick(Sender: TObject);
    procedure TabControl1Change(Sender: TObject);
    procedure prog_eepClick(Sender: TObject);
    procedure affiche_eeprom(Sender: TObject);
    procedure init_grid(Sender: TObject);
    procedure init_tracks(Sender: TObject);
    procedure tb_k1Change(Sender: TObject);
    procedure tb_k2Change(Sender: TObject);
    procedure tb_k3Change(Sender: TObject);
    procedure tb_k4Change(Sender: TObject);
    procedure btn_store_offsetClick(Sender: TObject);
    procedure cb_reverseClick(Sender: TObject);
    procedure max_tk1Change(Sender: TObject);
    procedure max_tk2Change(Sender: TObject);
    procedure max_tk3Change(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Timer_icTimer(Sender: TObject);
    procedure btn_neutreClick(Sender: TObject);
    procedure rg_linClick(Sender: TObject);
    procedure btn_inc_consigneClick(Sender: TObject);
  private
    { Déclarations privées }
  public
    { Déclarations publiques }
  end;

//{$DEFINE DEBUG}


type
  TDataRec = record
    nb_data: Integer;
    data_size,data_type : array[0..7] of integer;
                   //0 pour entier non signé
                   //1 pour entier signé
                   //2 pour float ieee
                   //3 pour float microchip
                   //4 pour calcul particulier
                   //5 pour affichage hexa
    data_text: array[0..7] of string;
    data_curve: array[0..7] of Tcolor;
    data_scale : array[0..7] of real;
    data_zero : array[0..7] of integer;
  end;
  TConfig = record
        version : integer;
        flags : integer;
	offset_as5040 : integer;
	volts_manuel : integer;
	largeur_bobine : integer;
	freq_boucle : integer;
	idata1 : integer;
	idata2 : integer;
	idata3 : integer;
	idata4 : integer;
	idata5 : integer;
	idata6 : integer;
	idata7 : integer;
	idata8 : integer;
	idata9 : integer;
	idata10 : integer;
    //int d'abord , float après
	Kp : single;
	Ki : single;
	Kd : single;
	pas : single;
        fdata1 : single;
        fdata2 : single;
        fdata3 : single;
        fdata4 : single;
        fdata5 : single;
        fdata6 : single;
        fdata7 : single;
        fdata8 : single;
        fdata9 : single;
        fdata10 : single;
  end;

var
  Form1: TForm1;
  cmpt_ic : integer;
  cmpt_rx: integer;
  temp_dat: int64;//64bits signé
  reel : single; //float sur 4 octets
  ptr_i : ^byte;
  ptr_long : ^longword;
  ptr_r : ^single;
  pdata : ^TDataRec;
  buffer_rx : array[0..100] of integer;
  nb_total : integer;
  flag_efface_curve : boolean;
  cmpt_pixel : integer;
  old_data : array[0..100] of integer;
  no_comm,connected : boolean ;
  port : integer;
  Datas : TDataRec;
  eepr : TConfig;
  cmpt_timer : integer;
  sensor_list,reg_set_list : Tstrings;
  pilotage_list,gyro_fs_sel_list : Tstrings;
  as_sens_roulis_list,as_sens_tangage_list : Tstrings;
  filtre_list,rg_lin_list,rg_axes_list : Tstrings;
  old_cb_vx_index : array[0..7] of integer;
  modif_controls : boolean;
  old_max_tkx_value : array[0..3] of integer;
  g : textfile;
  cmpt_pointer : boolean;
  ordo,old_ordo : integer;
  state_calibr_acc : byte;

  simu_vitesse_bobine : integer;
  flag_reset : boolean;

const
  mid = 300; //v1.Top+v1.Height div 2;
  bot = mid+190;
  topf = mid-190;

  data_1 : TDataRec=(nb_data:4;data_size:(2,4,2,2,0,0,0,0);
    data_type:(0,4,6,0,0,0,0,0);data_text:('tours_bob','vitesse_bob','courant','pos_as5040','','','','');
    data_curve:(clBlack,clBlue,clRed,clGreen,clNone,clNone,clNone,clNone);
    data_scale:(4,4,0.1,4,0,0,0,0);data_zero:(bot,bot,mid,bot,0,0,0,0); );
  data_2 : TDataRec=(nb_data:5;data_size:(2,2,2,2,2,0,0,0);
    data_type:(0,1,0,0,0,0,0,0);data_text:('tours_bob','Ep0','Epu','consigne','pos_as5040','','','');
    data_curve:(clBlack,clBlue,clRed,clGreen,clLime,clNone,clNone,clNone);
    data_scale:(4,4,4,4,4,0,0,0);data_zero:(bot,mid,bot,bot,bot,0,0,0); );


  data_Sbus : TDataRec=(nb_data:8;data_size:(2,2,2,2,2,2,2,2);
    data_type:(0,0,0,0,0,0,0,0);data_text:('v1','v2','v3','v4','v5','v6','v7','v8');
    data_curve:(clNone,clNone,clNone,clNone,clNone,clNone,clNone,clNone);
    data_scale:(0,0,0,0,0,0,0,0);data_zero:(0,0,0,0,0,0,0,0); );
  data_raw_acc : TDataRec=(nb_data:3;data_size:(2,2,2,0,0,0,0,0);
    data_type:(1,1,1,0,0,0,0,0);data_text:('acc_x','acc_y','acc_z','','','','','');
    data_curve:(clBlack,clRed,clBlue,clNone,clNone,clNone,clNone,clNone);
    data_scale:(6,6,6,0,0,0,0,0);data_zero:(mid,mid,mid,0,0,0,0,0); );
  data_raw_gyr : TDataRec=(nb_data:3;data_size:(2,2,2,2,2,2,0,0);
    data_type:(1,1,1,0,0,0,0,0);data_text:('gyr_x','gyr_y','gyr_z','','','','','');
    data_curve:(clBlack,clRed,clBlue,clNone,clNone,clNone,clNone,clNone);
    data_scale:(2,2,2,0,0,0,0,0);data_zero:(mid,mid,mid,0,0,0,0,0); );
  data_raw_mag : TDataRec=(nb_data:3;data_size:(2,2,2,0,0,0,0,0);
    data_type:(1,1,1,0,0,0,0,0);data_text:('mag_x','mag_y','mag_z','','','','','');
    data_curve:(clBlack,clRed,clBlue,clNone,clNone,clNone,clNone,clNone);
    data_scale:(6,6,6,0,0,0,0,0);data_zero:(mid,mid,mid,0,0,0,0,0); );
  data_axe : TDataRec=(nb_data:5;data_size:(2,2,2,2,2,0,0,0);
    data_type:(1,1,1,1,0,0,0,0);data_text:('roll','tilt','acc','Epu','t_lect1','','','');
    data_curve:(clBlack,clBlue,clRed,clNone,clNone,clNone,clNone,clNone);
    data_scale:(0.5,0.5,0.5,0,0,0,0,0);data_zero:(mid,mid,mid,0,0,0,0,0); );
  data_as5040 : TDataRec=(nb_data:3;data_size:(2,2,2,0,0,0,0,0);
    data_type:(0,1,0,0,0,0,0,0);data_text:('pos_as5040','angle_svm','volts_svm','','','','','');
    data_curve:(clBlack,clNone,clNone,clNone,clNone,clNone,clNone,clNone);
    data_scale:(3,128,128,0,0,0,0,0);data_zero:(bot,mid,mid,0,0,0,0,0); );
  data_timer : TDataRec=(nb_data:8;data_size:(2,2,2,2,2,2,2,2);
    data_type:(4,4,4,4,4,4,4,4);data_text:('t_0','t_2','t_3','t_4','t_5','t_6','t_7','t_8');
    data_curve:(clNone,clNone,clNone,clNone,clNone,clGreen,clBlack,clRed);
    data_scale:(0,0,0,0,0,1,1,1);data_zero:(0,0,0,0,0,bot,bot,bot); );

    COMMAND_BASCULE_IC_BOBINE=48;

    COMMAND_VISU_DATA_1=1;
    COMMAND_STORE_OFFS=2;
    COMMAND_WRITE_EEP=3;
    COMMAND_RESET=4;
    COMMAND_CHANGE_FREQ_BOUCLE=5;
    COMMAND_VISU_DATA_2=6;
    COMMAND_NEUTRE=7;
    COMMAND_INC_CONSIGNE=8;
    COMMAND_GOTO=9;

{
    COMMAND_VISU_TANGAGE=5;
    COMMAND_VISU_POS_AS_TANGAGE=7;
    COMMAND_ALIGN_ROULIS=8;
    COMMAND_ALIGN_TANGAGE=9;
    COMMAND_STORE_OFFS_TANGAGE=11;
    COMMAND_TEST_ARMATURE_ROULIS=12;
    COMMAND_TEST_ARMATURE_TANGAGE=13;
    COMMAND_STOP_VISU=14;
    COMMAND_VISU_DELTA_XYZ=17;
    COMMAND_CHANGE_GYRO_FS_SEL=18;
    COMMAND_STORE_ZERO_YAW=19;
    COMMAND_TEST_ARMATURE_YAW=20;
    COMMAND_STORE_LIM_ROULIS=21;
    COMMAND_ALIGN_YAW=22;
    COMMAND_STORE_LIM_TANGAGE=23;
    COMMAND_STORE_OFFS_YAW=24;
    COMMAND_RAZ_LIM_ROULIS=25;
    COMMAND_RAZ_LIM_TANGAGE=26;
    COMMAND_STORE_ZERO_ROULIS=27;
    COMMAND_STORE_ZERO_TANGAGE=28;
    COMMAND_VISU_TIMER=29;
    COMMAND_STORE_MIN_ACC_X=31;
    COMMAND_STORE_MAX_ACC_X=32;
    COMMAND_STORE_MIN_ACC_Y=33;
    COMMAND_STORE_MAX_ACC_Y=34;
    COMMAND_STORE_MIN_ACC_Z=35;
    COMMAND_STORE_MAX_ACC_Z=36;
    COMMAND_STORE_MIN_MAG_X=37;
    COMMAND_STORE_MAX_MAG_X=38;
    COMMAND_STORE_MIN_MAG_Y=39;
    COMMAND_STORE_MAX_MAG_Y=40;
    COMMAND_STORE_MIN_MAG_Z=41;
    COMMAND_STORE_MAX_MAG_Z=42;
    COMMAND_VISU_YAW=43;
    COMMAND_VISU_POS_AS_YAW=44;
    COMMAND_VISU_ACC=45;
    COMMAND_VISU_GYR=46;
    COMMAND_VISU_MAG=47;
 }
    //int value
    COMMAND_INT_FLAGS=129;  //128+1
    COMMAND_INT_OFFSET_AS5040=130;  //128+2
    COMMAND_VOLTS_VALUE=131;  //128+3
    COMMAND_LARG_BOBINE=132;  //128+4
    COMMAND_FREQ_BOUCLE=133;  //128+5
    COMMAND_IDATA1=134;  //128+6
    //float value
    OFFSET_FLOAT=16;
    COMMAND_KP=128+OFFSET_FLOAT;
    COMMAND_KI=128+OFFSET_FLOAT+2;
    COMMAND_KD=128+OFFSET_FLOAT+4;
    COMMAND_PAS=128+OFFSET_FLOAT+6;

    speed=19200;
    nb_header=3;
    header: array[0..(nb_header-1)] of integer = ($F0,$F1,$F2);
    periode=10; //en ms
    endian=1; //0:little endian(lsb d'abord) , 1:big endian(msb d'abord)



implementation
function OPENCOM(COMnr,baud,parity,bits,stop,tout,buffer:integer):integer;
      stdcall;external 'RS232';
procedure CLOSECOM(ComNr:integer);stdcall;external 'RS232';
procedure SENDBYTE(ComNr,dat:integer);stdcall;external 'RS232';
function READBYTE(ComNr:integer):integer;stdcall;external 'RS232';
procedure DTR(ComNr,state:integer);stdcall;external 'RS232';
procedure RTS(ComNr,state:integer);stdcall;external 'RS232';
procedure TXD(ComNr,state:integer);stdcall;external 'RS232';
function CTS(ComNr:integer):integer;stdcall;external 'RS232';
function DSR(ComNr:integer):integer;stdcall;external 'RS232';
function RI(ComNr:integer):integer;stdcall;external 'RS232';
function DCD(COMnr: Integer):Integer; stdcall;external 'RS232';
procedure TIMEINIT();stdcall;external 'RS232';
function TIMEREAD():real;stdcall;external 'RS232';
procedure DELAY(DelayTime:real);stdcall;external 'RS232';
procedure REALTIME();stdcall;external 'RS232';
procedure NORMALTIME();stdcall;external 'RS232';

{$R *.dfm}

procedure send_int(s_int : integer;s_adr : integer);
begin
     sendbyte(port,s_adr);
     //on envoie les 2 octets de la valeur en int +2 dummies
     sendbyte(port,s_int shr 8);
     sendbyte(port,s_int and $FF);
     sendbyte(port,0);
     sendbyte(port,0);
end;
procedure send_float(s_float : single;s_adr : integer);
var s_temp : int64;
begin
     sendbyte(port,s_adr);
     //on envoie les 4 octets de la valeur en float
     ptr_long:=@s_float;
     s_temp:=ptr_long^;
     sendbyte(port,(s_temp shr 8)and $FF);
     sendbyte(port,s_temp and $FF); //word poids faible
     sendbyte(port,s_temp shr 24);
     sendbyte(port,(s_temp shr 16)and $FF);//word poids fort
end;


procedure TForm1.init_tracks(Sender: TObject);
var k:integer;
begin
if   modif_controls=true then
 begin
   modif_controls:=false;
    case tabcontrol1.TabIndex of
        0: begin   //installation
             Label1.Visible:=true;
             Label2.Visible:=true;
             Label3.Visible:=true;
             Label4.Visible:=true;
             label1.Caption:='volts_manuel';
             label2.Caption:='larg_bobine';
             label3.Caption:='Pas';
             label4.Caption:='F_loop';
             tb_k1.Visible:=true;
             tb_k2.Visible:=true;
             tb_k3.Visible:=true;
             tb_k4.Visible:=true;
             lb_k1.Visible:=true;
             lb_k2.Visible:=true;
             lb_k3.Visible:=true;
             lb_k4.Visible:=true;
             tb_k1.Position:=eepr.volts_manuel div 15;
             tb_k2.Position:=eepr.largeur_bobine div 2 ;
             tb_k3.Position:=round(eepr.pas * 10);
             tb_k4.Position:=(eepr.freq_boucle div 5)-10;
             lb_k1.Caption:=inttostr(tb_k1.Position * 15);
             lb_k2.Caption:=inttostr(tb_k2.Position*2);
             lb_k3.Caption:=format('%2.1f',[tb_k3.Position/10]);
             lb_k4.Caption:=inttostr((tb_k4.Position +10)*5)+'Hz';

           end;
        1: begin   //asserv
             max_tk1.Visible:=true;
             max_tk2.Visible:=true;
             //max_tk3.Visible:=true;
//             max_tk4.Visible:=true;
//             cb_reverse.Visible:=true;
             Label1.Visible:=true;
             Label2.Visible:=true;
             Label3.Visible:=true;
             Label4.Visible:=true;
             label1.Caption:='Kp';
             label2.Caption:='Ki';
             label3.Caption:='Goto';//'Kd';
             label4.Caption:='simu_bobine';
             tb_k1.Visible:=true;
             tb_k2.Visible:=true;
             tb_k3.Visible:=true;
             tb_k4.Visible:=true;
             lb_k1.Visible:=true;
             lb_k2.Visible:=true;
             lb_k3.Visible:=true;
             lb_k4.Visible:=true;

        //     if (eepr.flags and $0004)=$0004 then cb_reverse.Checked:=true
          //    else cb_reverse.Checked:=false;
              //on définit le coefficient tb_kx/valeur en fonction de la valeur actuelle
             if (eepr.Kp>=1) then  max_tk1.Value:=((round(eepr.Kp)div 10)+1)*10
              else max_tk1.Value:=1;
             if (eepr.Ki>=1) then  max_tk2.Value:=((round(eepr.Ki)div 10)+1)*10
              else max_tk2.Value:=1;
//             if (eepr.Kd>=1) then  max_tk3.Value:=((round(eepr.Kd)div 10)+1)*10
  //            else max_tk3.Value:=1;
             tb_k1.Position:=round(eepr.Kp*100/max_tk1.Value);
             tb_k2.Position:=round(eepr.Ki*100/max_tk2.Value);
             tb_k3.Position:=eepr.idata1 div 10;//round(eepr.Kd*100/max_tk3.Value);
             tb_k4.Position:=simu_vitesse_bobine*5;
             lb_k1.Caption:=format('%2.1f',[tb_k1.Position*max_tk1.value/100]);
             lb_k2.Caption:=format('%1.2f',[tb_k2.Position*max_tk2.value/100]);
             lb_k3.Caption:=inttostr(tb_k3.Position*10);//format('%2.1f',[tb_k3.Position*max_tk3.value/100]);
             lb_k4.Caption:=inttostr(tb_k4.Position div 5)+'Tr/s';
             old_max_tkx_value[0]:=max_tk1.Value;
             old_max_tkx_value[1]:=max_tk2.Value;
             old_max_tkx_value[2]:=max_tk3.Value;
    //         old_max_tkx_value[3]:=max_tk4.Value;
             rg_lin.ItemIndex:=eepr.flags and $01; //b0

           end;
        2: begin   //div1
          end;
        3: begin   //div2
           end;
        4: begin   //div3
           end;
     end;
    modif_controls:=true;
 end;

end;

procedure TForm1.init_grid(Sender: TObject);
var i:integer;
begin
    Stringgrid1.ColCount:=Datas.nb_data;
    Stringgrid1.Height:=2*Stringgrid1.DefaultRowHeight;
    Stringgrid1.Width:=Datas.nb_data*Stringgrid1.DefaultColWidth;
    nb_total:=nb_header;
    for i:=0 to (Datas.nb_data-1) do
    begin
       nb_total:=nb_total+Datas.data_size[i];
       Stringgrid1.Cells[i,0]:=Datas.data_text[i];
    end;
    flag_efface_curve:=true;
    cmpt_pixel:=0;
    stringgrid1.Visible:=true;
    if connected then timer_start.Enabled:=true;

end;

procedure TForm1.affiche_eeprom(Sender: TObject);
begin
        memo1.Lines.Add('version:'+inttostr(eepr.version));
        memo1.Lines.Add('flags:0x'+inttohex(eepr.flags,2));
        memo1.Lines.Add('offset_as5040:'+inttostr(eepr.offset_as5040));
        memo1.Lines.Add('volts_manuel:'+inttostr(eepr.volts_manuel));
        memo1.Lines.Add('largeur_bobine:'+inttostr(eepr.largeur_bobine));
        memo1.Lines.Add('freq_boucle:'+inttostr(eepr.freq_boucle));

        memo1.Lines.Add('Kp:'+floattostr(eepr.Kp));
        memo1.Lines.Add('Ki:'+floattostr(eepr.Ki));
        memo1.Lines.Add('Kd:'+floattostr(eepr.Kd));
        memo1.Lines.Add('pas:'+floattostr(eepr.pas));
   {$IF Defined(DEBUG) }
       memo1.Lines.Add('*********DEBUG***********');
   {$IFEND}

end;

function read_uint : integer;
var temp_int:integer;
begin
        temp_int:=readbyte(port);
        read_uint:= (temp_int shl 8) or readbyte(port);
end;
function read_int : integer;
var temp_int:integer;
begin
        temp_int:=read_uint;
        if temp_int>32767 then read_int:=temp_int-65536
        else read_int:=temp_int;
end;
function read_float : real;
var temp_dat,temp_ieee:int64;
begin
        temp_dat:=readbyte(port);
        temp_dat:= (temp_dat shl 8) or readbyte(port);
        temp_ieee:= readbyte(port);
        temp_ieee:= (temp_ieee shl 8) or readbyte(port);
        temp_ieee:= (temp_ieee shl 16) or temp_dat;
        ptr_r:=@temp_ieee;
        read_float:=ptr_r^;

end;
procedure read_eeprom;
begin
{$IF Defined(DEBUG) }
        eepr.version := 2;
        eepr.flags := 0;
        eepr.offset_as5040 := 227;
        eepr.volts_manuel := 455;
        eepr.largeur_bobine := 140;
        eepr.freq_boucle := 100;

        eepr.Kp := 5.1;
        eepr.Ki := 0.15;
        eepr.Kd := 4.7;
        eepr.pas := 5.0;

{$ELSE}
        eepr.version := read_int;
        eepr.flags := read_int;
        eepr.offset_as5040 := read_int;
        eepr.volts_manuel := read_int;
        eepr.largeur_bobine := read_int;
        eepr.freq_boucle := read_int;
        eepr.idata1 := read_int;
        eepr.idata2 := read_int;
        eepr.idata3 := read_int;
        eepr.idata4 := read_int;
        eepr.idata5 := read_int;
        eepr.idata6 := read_int;
        eepr.idata7 := read_int;
        eepr.idata8 := read_int;
        eepr.idata9 := read_int;
        eepr.idata10 := read_int;

        eepr.Kp := read_float;
        eepr.Ki := read_float;
        eepr.Kd := read_float;
        eepr.pas := read_float;
        eepr.fdata1 := read_float;
        eepr.fdata2 := read_float;
        eepr.fdata3 := read_float;
        eepr.fdata4 := read_float;
        eepr.fdata5 := read_float;
        eepr.fdata6 := read_float;
        eepr.fdata7 := read_float;
        eepr.fdata8 := read_float;
        eepr.fdata9 := read_float;
        eepr.fdata10 := read_float;

{$IFEND}

end;

procedure TForm1.FormCreate(Sender: TObject);

begin

modif_controls:=true;//false pour éviter l'exécution des routines de modification
                        // des contrôles par écriture de nouvelles propriétés

sensor_list := TStringList.Create;	{ construit la liste }
sensor_list.Add('sensor x');
sensor_list.Add('-sensor x');
sensor_list.Add('sensor y');
sensor_list.Add('-sensor y');
sensor_list.Add('sensor z');
sensor_list.Add('-sensor z');
reg_set_list := TStringList.Create;	{ construit la liste }
reg_set_list.Add('Rien');
reg_set_list.Add('Kp_roll');
reg_set_list.Add('Ki_roll');
reg_set_list.Add('Kd_roll');
reg_set_list.Add('Kp_tilt');
reg_set_list.Add('Ki_tilt');
reg_set_list.Add('Kd_tilt');
pilotage_list := TStringList.Create;	{ construit la liste }
pilotage_list.Add('position');
pilotage_list.Add('vitesse');
gyro_fs_sel_list := TStringList.Create;	{ construit la liste }
gyro_fs_sel_list.Add('+/-250°/s');
gyro_fs_sel_list.Add('+/-500°/s');
gyro_fs_sel_list.Add('+/-1000°/s');
gyro_fs_sel_list.Add('+/-2000°/s');
as_sens_roulis_list := TStringList.Create;	{ construit la liste }
as_sens_roulis_list.Add('incrément à droite');
as_sens_roulis_list.Add('incrément à gauche');
as_sens_tangage_list := TStringList.Create;	{ construit la liste }
as_sens_tangage_list.Add('incrément à cabré');
as_sens_tangage_list.Add('incrément à piqué');
filtre_list := TStringList.Create;	{ construit la liste }
filtre_list.Add('Mahoney');
filtre_list.Add('Madgwick');
rg_lin_list := TStringList.Create;	{ construit la liste }
rg_lin_list.Add('accéléros');
rg_lin_list.Add('gyros');
rg_lin_list.Add('magnétos');
rg_axes_list := TStringList.Create;	{ construit la liste }
rg_axes_list.Add('roulis');
rg_axes_list.Add('tangage');
rg_axes_list.Add('lacet');


ptr_i:=@eepr;
pdata := @eepr;
cmpt_pointer:=false;
old_ordo:=mid;
state_calibr_acc:=0;
simu_vitesse_bobine:=0;
flag_reset:=false;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
    if (connected) then closecom(port);
    //connectClick(nil);
    sensor_list.Free;	{ détruit l'objet liste }
    reg_set_list.Free;	{ détruit l'objet liste }
    pilotage_list.Free;	{ détruit l'objet liste }
    gyro_fs_sel_list.Free;	{ détruit l'objet liste }
    as_sens_roulis_list.Free;	{ détruit l'objet liste }
    as_sens_tangage_list.Free;	{ détruit l'objet liste }
    filtre_list.Free;	{ détruit l'objet liste }
    rg_lin_list.Free;{ détruit l'objet liste }
    rg_axes_list.Free; { détruit l'objet liste }

end;

procedure TForm1.Timer_loopTimer(Sender: TObject);
var i,j,k,d,range:integer;
    temp_ieee:int64;
    dessine : boolean;
begin
repeat
 d:=readbyte(port);
 if (d>-1) then
 begin
    buffer_rx[cmpt_rx]:=d;
    inc(cmpt_rx);
    timeinit;
 end;
 if ((cmpt_rx>0)and(cmpt_rx<(nb_header+1))) then //réception en-tête
 begin
    if (buffer_rx[cmpt_rx-1]<>header[cmpt_rx-1]) then cmpt_rx:=0;
 end;
 if (cmpt_rx=nb_total) then
 begin
     k:=nb_header;
     flag_efface_curve:=true;
//     cmpt_rx:=0;
     for i:=0 to (Datas.nb_data-1) do
     begin
        temp_dat:=0;
        for j:=0 to (Datas.data_size[i]-1) do
        begin
           if (endian=1) then  temp_dat:=(temp_dat shl 8)+buffer_rx[k]
           else temp_dat:=temp_dat+(buffer_rx[k] shl (j shl 3));
           inc(k);
        end;
               //mise en forme en fonction du type
                   //0 pour entier non signé
                   //1 pour entier signé
                   //2 pour float ieee
                   //3 pour float microchip
                   //4 pour calcul particulier
                   //5 pour affichage hexa
        case Datas.data_type[i] of
                 0 : begin
                        Stringgrid1.Cells[i,1]:=inttostr(temp_dat);
                     end;
                 1 : begin
                        range:=1 shl (Datas.data_size[i] shl 3);
                        if (temp_dat>=(range shr 1)) then temp_dat:=temp_dat-range;
                        Stringgrid1.Cells[i,1]:=inttostr(temp_dat);
    //                    s:=s+inttostr(temp_dat)+',';
                     end;
                 2 : begin
                        ptr_r:=@temp_dat;
                        reel:=ptr_r^;
                        Stringgrid1.Cells[i,1]:=floattostr(reel);
                        temp_dat:=round(reel); //pour les courbes
                     end;
                 3 : begin
                        //modif microchip->ieee
                        temp_ieee:=temp_dat and $FF000000;
                        temp_ieee:=temp_ieee shr 1;
                        if ((temp_dat and $800000)=$800000) then temp_ieee:=temp_ieee or $80000000;
                        temp_ieee:=temp_ieee or (temp_dat and $7FFFFF);
                        ptr_r:=@temp_ieee;
                        reel:=ptr_r^;
                        Stringgrid1.Cells[i,1]:=floattostr(reel);
                        temp_dat:=round(reel); //pour les courbes
                     end;
                  4 : begin
                       if temp_dat<>0 then  temp_dat:=6912000 div temp_dat;
                       Stringgrid1.Cells[i,1]:=inttostr(temp_dat);
                      end;
                  5 : begin
                        Stringgrid1.Cells[i,1]:='0x'+inttohex(temp_dat,2);
                     end;
                  6 : begin
                        // pour le courant
                       temp_dat:=temp_dat-512;
                       Stringgrid1.Cells[i,1]:=inttostr(temp_dat);
                      end;


        end;
                if (Datas.data_curve[i]<>clNone) then // on dessine la courbe correspondante
                begin
                  if flag_efface_curve then
                  begin
                      canvas.FillRect(rect(cmpt_pixel+11,topf-1,cmpt_pixel+31,bot+1));
                      flag_efface_curve:=false;
                  end;
                  canvas.Pen.Color:=Datas.data_curve[i];
                  ordo:=round(-temp_dat/Datas.data_scale[i])+Datas.data_zero[i];
                  old_ordo:=round(-old_data[i]/Datas.data_scale[i])+Datas.data_zero[i];
                  if ordo<topf then ordo:=topf;
                  if ordo>bot then ordo:=bot;
                  if old_ordo<topf then old_ordo:=topf;
                  if old_ordo>bot then old_ordo:=bot;
                  dessine:=false;
                  case i of
                      0 : if cb1.Checked then dessine:=true;
                      1 : if cb2.Checked then dessine:=true;
                      2 : if cb3.Checked then dessine:=true;
                      3 : if cb4.Checked then dessine:=true;
                      4 : if cb5.Checked then dessine:=true;
                  end;
                  if dessine then
                  begin
                          canvas.MoveTo(cmpt_pixel+10,old_ordo);
                          canvas.LineTo(cmpt_pixel+11,ordo);
                  end;
                  old_data[i]:=temp_dat;
                  if cmpt_pixel=700 then cmpt_pixel:=0;
                end;
     end;
     inc(cmpt_pixel);

 end;
until (cmpt_rx=nb_total) or (timeread>periode);//(d=-1);//
//
     cmpt_rx:=0;
end;

procedure TForm1.Timer_startTimer(Sender: TObject);
var i:integer;
begin
 for i:=0 to (Datas.nb_data-1) do
    begin
     if  (Datas.data_curve[i]<>clNone) then
       begin
            stringgrid1.Canvas.Brush.Color:=Datas.data_curve[i];
            stringgrid1.Canvas.Rectangle(48+i*Stringgrid1.DefaultColWidth,
                                          (Stringgrid1.DefaultRowHeight div 2+3),
                                         78+i*Stringgrid1.DefaultColWidth,
                                          (Stringgrid1.DefaultRowHeight div 2)+9 );
       end;
     end;
  timer_start.Enabled:=false;
  canvas.Pen.Color:=clRed;
 {               canvas.MoveTo(10,mid);
                canvas.LineTo(700,topf);
                canvas.MoveTo(10,mid);
                canvas.LineTo(700,mid);
                canvas.MoveTo(10,mid);
                canvas.LineTo(700,bot);
  }
end;

procedure TForm1.connectClick(Sender: TObject);
var d:integer;
begin
port:=strtoint(rightstr(cb_port.Text,1));

if connect.Caption='&Connect' then
  begin
    opencom(port,speed,0,8,1,100,1000);
    connect.Caption:='&Raz';
    cb_port.Enabled:=false;
    timer_loop.Interval:=periode;
    cmpt_rx:=0;
    memo1.Clear;
    memo1.Lines.Add('Démarrage...');
 {         rts(port,1);
          delay(50);
          rts(port,0);
          delay(50);
          delay(100);   }
    repeat d:=readbyte(port); until d=-1;
    delay(1000);
    sendbyte(port,$47); //"G"
    delay(1000);
    //on doit avoir reçu le "GO" et les données eeprom
    d:=readbyte(port);
    d:=readbyte(port);
{$IF Defined(DEBUG) }
       connected:=true;
       memo1.Lines.Add('Initialisation...');
       read_eeprom;
       affiche_eeprom(nil);
        delay(2500);
       tabcontrol1.OnChange(nil);//    init_tracks(nil);
       timer_loop.Enabled:=true;

 {$ELSE}
    if (d=79) then //"O"
     begin
       connected:=true;
       memo1.Lines.Add('Initialisation...');
       read_eeprom;
       affiche_eeprom(nil);
        delay(2500);
       tabcontrol1.OnChange(nil);//    init_tracks(nil);
       timer_loop.Enabled:=true;
     end
    else
     begin
       connected:=false;
       memo1.Lines.Add('Problème communication');
     end;
 {$IFEND}

   timeinit;
  end
else begin
    if connected then  sendbyte(port,COMMAND_RESET);
        flag_reset:=true;
            timer_ic.Enabled:=false;
            memo1.Clear;
            connect.Caption:='&Connect';
           cb_port.Enabled:=true;
           connected:=false;
           timer_loop.Enabled:=false;
           stringgrid1.Visible:=false;
{          delay(50);
          rts(port,1);
          delay(50);
          rts(port,0);
          delay(50);
          delay(100);                          }
          repeat d:=readbyte(port); until d=-1;
          closecom(port);
          canvas.FillRect(rect(10,0,932,600));

     end;

end;

procedure TForm1.TabControl1Change(Sender: TObject);
var //d:integer;
    fic : string;
    proceed_file : boolean;

begin
             btn_calibr_acc.Visible:=false;
             btn_limL.Visible:=false;
             btn_raz_limites.Visible:=false;
             max_tk1.Visible:=false;
             max_tk2.Visible:=false;
             max_tk3.Visible:=false;
             max_tk4.Visible:=false;
             cb_reverse.Visible:=false;
             btn_inc_consigne.Visible:=false;
             Label1.Visible:=false;
             Label2.Visible:=false;
             Label3.Visible:=false;
             Label4.Visible:=false;
             btn_neutre.Visible:=false;
             btn_store_offset.Visible:=false;
             btn_zero_as.Visible:=false;
             V1.Visible:=false;
             V2.Visible:=false;
             V3.Visible:=false;
             V4.Visible:=false;
             V5.Visible:=false;
             V6.Visible:=false;
             V7.Visible:=false;
             V8.Visible:=false;
             cb_v1.Visible:=false;
             cb_v2.Visible:=false;
             cb_v3.Visible:=false;
             cb_v4.Visible:=false;
             cb_v5.Visible:=false;
             cb_v6.Visible:=false;
             cb_v7.Visible:=false;
             cb_v8.Visible:=false;
             cb_reg1.Visible:=false;
             cb_reg2.Visible:=false;
             cb_reg3.Visible:=false;
             lb_reg1.Visible:=false;
             lb_reg2.Visible:=false;
             lb_reg3.Visible:=false;
             rg_roll.Visible:=false;
             rg_tilt.Visible:=false;
             rg_lin.Visible:=false;
             tb_k1.Visible:=false;
             tb_k2.Visible:=false;
             tb_k3.Visible:=false;
             tb_k4.Visible:=false;
             lb_k1.Visible:=false;
             lb_k2.Visible:=false;
             lb_k3.Visible:=false;
             lb_k4.Visible:=false;
             cb1.Visible:=false;
             cb2.Visible:=false;
             cb3.Visible:=false;
             cb4.Visible:=false;
             cb5.Visible:=false;
             Stringgrid1.DefaultColWidth:=80;
    canvas.FillRect(rect(10,topf-1,932,bot+1));
    old_ordo:=mid;
    case tabcontrol1.TabIndex of
        0: begin   //installation
            cmpt_rx:=0;
            btn_store_offset.Visible:=true;
            btn_store_offset.Caption:='store_offset';
             btn_inc_consigne.Visible:=true;
             btn_neutre.Visible:=true;
             cb1.Visible:=true;
             cb2.Visible:=true;
             cb3.Visible:=true;
             cb4.Visible:=true;
             Datas:=data_1;
             init_tracks(nil);
            init_grid(nil);
            if connected then  sendbyte(port,COMMAND_VISU_DATA_1);
           end;
        1: begin   //asservissement
             cmpt_rx:=0;
             rg_lin.Visible:=true;
             btn_neutre.Visible:=true;
             btn_inc_consigne.Visible:=true;
             btn_store_offset.Visible:=true;
             btn_store_offset.Caption:='Go To';
             cb1.Visible:=true;
             cb2.Visible:=true;
             cb3.Visible:=true;
             cb4.Visible:=true;
             cb5.Visible:=true;
             Datas:=data_2;
             init_tracks(nil);
            init_grid(nil);
             if connected then  sendbyte(port,COMMAND_VISU_DATA_2);
           end;
        2: begin   //div1
          end;
        3: begin   //div2
           end;
        4: begin   //div3
           end;
     end;

end;


procedure TForm1.prog_eepClick(Sender: TObject);

begin
   if (connected)
    then
    begin
       memo1.Lines.Add('-Enregistrement des données en EEPROM');
       sendbyte(port,COMMAND_WRITE_EEP);
    end;

end;

procedure TForm1.tb_k1Change(Sender: TObject);
//var temp_tx : integer;
begin
 if   modif_controls=true then
 begin
   modif_controls:=false;
   case tabcontrol1.TabIndex of
        0: begin   //installation
            lb_k1.Caption:=inttostr(tb_k1.Position * 15);
             if connected then
             begin
                sendbyte(port,COMMAND_VOLTS_VALUE);
                //on envoie les 2 octets de la valeur en int +2 dummies
                temp_dat:=(tb_k1.Position)*15;
                eepr.volts_manuel:=temp_dat;
                sendbyte(port,(temp_dat shr 8));
                sendbyte(port,temp_dat and $FF);
                sendbyte(port,0);
                sendbyte(port,0);
             end;
           end;
        1: begin   //asserv
             lb_k1.Caption:=format('%2.1f',[tb_k1.Position*max_tk1.value/100]);

             if connected then
             begin
                reel:=tb_k1.Position*max_tk1.value/100;
                sendbyte(port,COMMAND_KP);
                eepr.Kp:=reel;
                //on envoie les 4 octets de la valeur en float
                //memo1.Lines.Add(floattostr(reel));
                ptr_long:=@reel;
                temp_dat:=ptr_long^;
                sendbyte(port,(temp_dat shr 8)and $FF);
                sendbyte(port,temp_dat and $FF); //word poids faible
                sendbyte(port,temp_dat shr 24);
                sendbyte(port,(temp_dat shr 16)and $FF);//word poids fort
             end;

           end;
        2: begin   //div1
          end;
        3: begin   //div2
           end;
        4: begin   //div3
           end;
     end;
   modif_controls:=true;
 end;

end;

procedure TForm1.tb_k2Change(Sender: TObject);
begin
if   modif_controls=true then
 begin
   modif_controls:=false;
    case tabcontrol1.TabIndex of
        0: begin   //installation
             lb_k2.Caption:=inttostr(tb_k2.Position*2);
             if connected then
             begin
                sendbyte(port,COMMAND_LARG_BOBINE);
                //on envoie les 2 octets de la valeur en int +2 dummies
                temp_dat:=(tb_k2.Position)*2;
                eepr.largeur_bobine:=temp_dat;
                sendbyte(port,(temp_dat shr 8));
                sendbyte(port,temp_dat and $FF);
                sendbyte(port,0);
                sendbyte(port,0);
             end;
           end;
        1: begin   //asserv
             lb_k2.Caption:=format('%1.2f',[tb_k2.Position*max_tk2.value/100]);
             if connected then
             begin
                reel:=tb_k2.Position*max_tk2.value/100;
                sendbyte(port,COMMAND_KI);
                eepr.Ki:=reel;
                //on envoie les 4 octets de la valeur en float
                //memo1.Lines.Add(floattostr(reel));
                ptr_long:=@reel;
                temp_dat:=ptr_long^;
                sendbyte(port,(temp_dat shr 8)and $FF);
                sendbyte(port,temp_dat and $FF); //word poids faible
                sendbyte(port,temp_dat shr 24);
                sendbyte(port,(temp_dat shr 16)and $FF);//word poids fort
             end;
           end;
        2: begin   //div1
          end;
        3: begin   //div2
           end;
        4: begin   //div3
           end;
     end;
  modif_controls:=true;
 end;
end;

procedure TForm1.tb_k3Change(Sender: TObject);
begin
if   modif_controls=true then
 begin
   modif_controls:=false;
    case tabcontrol1.TabIndex of
        0: begin   //installation
             lb_k3.Caption:=format('%2.1f',[tb_k3.Position/10]);

             if connected then
             begin
                reel:=tb_k3.Position/10 ;
                sendbyte(port,COMMAND_PAS);
                eepr.pas:=reel;
                //on envoie les 4 octets de la valeur en float
                //memo1.Lines.Add(floattostr(reel));
                ptr_long:=@reel;
                temp_dat:=ptr_long^;
                sendbyte(port,(temp_dat shr 8)and $FF);
                sendbyte(port,temp_dat and $FF); //word poids faible
                sendbyte(port,temp_dat shr 24);
                sendbyte(port,(temp_dat shr 16)and $FF);//word poids fort
             end;
           end;
        1: begin   //asserv
             lb_k3.Caption:=inttostr((tb_k3.Position)*10);
             if connected then
             begin
                sendbyte(port,COMMAND_IDATA1);
                //on envoie les 2 octets de la valeur en int +2 dummies
                temp_dat:=(tb_k3.Position)*10;
                eepr.idata1:=temp_dat;
                sendbyte(port,(temp_dat shr 8));
                sendbyte(port,temp_dat and $FF);
                sendbyte(port,0);
                sendbyte(port,0);
             end;
           end;
        2: begin   //div1
          end;
        3: begin   //div2
           end;
        4: begin   //div3
           end;
     end;
   modif_controls:=true;
 end;
end;

procedure TForm1.tb_k4Change(Sender: TObject);
begin
if   modif_controls=true then
 begin
   modif_controls:=false;
    case tabcontrol1.TabIndex of
        0: begin   //installation
             lb_k4.Caption:=inttostr((tb_k4.Position +10)*5)+'Hz';
             if connected then
             begin
                sendbyte(port,COMMAND_FREQ_BOUCLE);
                //on envoie les 2 octets de la valeur en int +2 dummies
                temp_dat:=(tb_k4.Position+10)*5;
                eepr.freq_boucle:=temp_dat;
                sendbyte(port,(temp_dat shr 8));
                sendbyte(port,temp_dat and $FF);
                sendbyte(port,0);
                sendbyte(port,0);
                sendbyte(port,COMMAND_CHANGE_FREQ_BOUCLE);
             end;


           end;
        1: begin   //asserv
             lb_k4.Caption:=inttostr(tb_k4.Position div 5)+'Tr/s';
             if tb_k4.Position<>0 then
              begin
               timer_ic.Enabled:=true;
               timer_ic.Interval:=5000 div tb_k4.Position;
              end
             else timer_ic.Enabled:=false;
           end;
        2: begin   //div1
          end;
        3: begin   //div2
           end;
        4: begin   //div3
           end;
     end;
  modif_controls:=true;
 end;
end;

procedure TForm1.btn_store_offsetClick(Sender: TObject);
begin
 if connected then
 begin
    case tabcontrol1.TabIndex of
        0: begin   //installation
              memo1.Lines.Add('-Mémorisation offset as5040');
              sendbyte(port,COMMAND_STORE_OFFS);
           end;
        1: begin   //asservissement
              memo1.Lines.Add('-Go to : '+inttostr(eepr.idata1));
              sendbyte(port,COMMAND_GOTO);
           end;
    end;

 end;

end;

procedure TForm1.cb_reverseClick(Sender: TObject);
begin
if   modif_controls=true then
 begin
   modif_controls:=false;
    case tabcontrol1.TabIndex of
        0: begin   //installation
           end;
        1: begin   //imu
           end;
        2: begin   //s_bus
          end;
        3: begin   //roulis
             if connected then
             begin
                sendbyte(port,COMMAND_INT_FLAGS);
                //on envoie les 2 octets de la valeur en int +2 dummies
                if cb_reverse.Checked then temp_dat:=(eepr.flags or $0004) //b2=1
                else temp_dat:=(eepr.flags and $FFFB); //b2=0
                eepr.flags:=temp_dat;
                sendbyte(port,(temp_dat shr 8));
                sendbyte(port,temp_dat and $FF);
                sendbyte(port,0);
                sendbyte(port,0);
             end;
           end;
        4: begin   //tangage
             if connected then
             begin
                sendbyte(port,COMMAND_INT_FLAGS);
                //on envoie les 2 octets de la valeur en int +2 dummies
                if cb_reverse.Checked then temp_dat:=(eepr.flags or $0008) //b3=1
                else temp_dat:=(eepr.flags and $FFF7); //b3=0
                eepr.flags:=temp_dat;
                sendbyte(port,(temp_dat shr 8));
                sendbyte(port,temp_dat and $FF);
                sendbyte(port,0);
                sendbyte(port,0);
             end;
           end;
        5: begin   //capteurs mag
           end;
        9: begin   //lacet
             if connected then
             begin
                sendbyte(port,COMMAND_INT_FLAGS);
                //on envoie les 2 octets de la valeur en int +2 dummies
                if cb_reverse.Checked then temp_dat:=(eepr.flags or $0100) //b8=1
                else temp_dat:=(eepr.flags and $FEFF); //b8=0
                eepr.flags:=temp_dat;
                sendbyte(port,(temp_dat shr 8));
                sendbyte(port,temp_dat and $FF);
                sendbyte(port,0);
                sendbyte(port,0);
             end;
           end;

     end;
  modif_controls:=true;
 end;
end;

procedure TForm1.max_tk1Change(Sender: TObject);
begin
if   modif_controls=true then
 begin
   modif_controls:=false;
    if max_tk1.Value=0 then max_tk1.Value:=1;
    if max_tk1.Value=11 then max_tk1.Value:=10;
    case tabcontrol1.TabIndex of
      1: begin
           if max_tk1.Value<eepr.Kp then max_tk1.Value:=old_max_tkx_value[0];
           tb_k1.Position:=round(eepr.Kp*100/max_tk1.Value);
         end;
    end;
   old_max_tkx_value[0]:=max_tk1.Value;
   modif_controls:=true;
 end;
end;

procedure TForm1.max_tk2Change(Sender: TObject);
begin
if   modif_controls=true then
 begin
   modif_controls:=false;
    if max_tk2.Value=0 then max_tk2.Value:=1;
    if max_tk2.Value=11 then max_tk2.Value:=10;
    case tabcontrol1.TabIndex of
      1: begin
           if max_tk2.Value<eepr.Ki then max_tk2.Value:=old_max_tkx_value[1];
           tb_k2.Position:=round(eepr.Ki*100/max_tk2.Value);
         end;
    end;
   old_max_tkx_value[1]:=max_tk2.Value;
   modif_controls:=true;
  end;
end;

procedure TForm1.max_tk3Change(Sender: TObject);
begin
if   modif_controls=true then
 begin
   modif_controls:=false;
    if max_tk3.Value=0 then max_tk3.Value:=1;
    if max_tk3.Value=11 then max_tk3.Value:=10;
    case tabcontrol1.TabIndex of
      1: begin
           if max_tk3.Value<eepr.Kd then max_tk3.Value:=old_max_tkx_value[2];
           tb_k3.Position:=round(eepr.Kd*100/max_tk3.Value);
         end;
    end;
    old_max_tkx_value[2]:=max_tk3.Value;
   modif_controls:=true;
  end;
end;

procedure TForm1.Button1Click(Sender: TObject);
var
     temp_int  : integer;
     temp_real : single;
begin
 //  ptr_i:=@eepr;
   if (ptr_i = @eepr.Kp ) then  cmpt_pointer:=true;
    temp_int:=ptr_i^;
   inc(ptr_i);
   temp_int:=temp_int+ ptr_i^ shl 8;
   inc(ptr_i);
   temp_int:=temp_int+ ptr_i^ shl 16;
   inc(ptr_i);
   temp_int:=temp_int+ ptr_i^ shl 24;
   inc(ptr_i);


   if (cmpt_pointer) then
    begin
    ptr_r:=@temp_int;
   temp_real:=ptr_r^;
    memo1.Lines.Add(inttostr(temp_int));
    memo1.Lines.Add(floattostr(temp_real));
    {
 temp_int:=ptr_i^;
   memo1.Lines.Add(inttostr(temp_int));
   inc(ptr_i);
   temp_int:=ptr_i^;
   memo1.Lines.Add(inttostr(temp_int));
   inc(ptr_i);
   temp_int:=ptr_i^;
   memo1.Lines.Add(inttostr(temp_int));
   inc(ptr_i);
   temp_int:=ptr_i^;
   memo1.Lines.Add(inttostr(temp_int));
   inc(ptr_i);   }
    end
   else
    begin

   memo1.Lines.Add(inttostr(temp_int));
    end;


  { temp_int:=ptr_i^;
   memo1.Lines.Add(inttostr(temp_int));
   inc(ptr_i);
   inc(ptr_i);
   inc(ptr_i);
   inc(ptr_i);}
end;

procedure TForm1.Button2Click(Sender: TObject);
   var tab: array[0..3] of byte;
   temp_real: single;
   s:string;
    temp_val : int64;

begin
 temp_real:=0.15;
 ptr_i:=@temp_real;
 tab[3]:=ptr_i^;
 inc(ptr_i);
 tab[2]:=ptr_i^;
 inc(ptr_i);
 tab[1]:=ptr_i^;
 inc(ptr_i);
 tab[0]:=ptr_i^;
 temp_val:=65536*(tab[0]*256+tab[1])+tab[2]*256+tab[3];
 s:=inttohex(tab[0],2)+inttohex(tab[1],2)+inttohex(tab[2],2)+inttohex(tab[3],2);
 s:=s+','+inttostr(temp_val);
 memo1.Lines.Add(s);

//   temp_val:=10418655114;
    ptr_r:=@temp_val;
   temp_real:=ptr_r^;
    memo1.Lines.Add(floattostr(temp_real));
end;

procedure TForm1.Timer_icTimer(Sender: TObject);
begin
  if connected then  sendbyte(port,COMMAND_BASCULE_IC_BOBINE);
//  memo1.Lines.Add('ic_bobine'+inttostr(cmpt_ic));
//  inc(cmpt_ic);
end;

procedure TForm1.btn_neutreClick(Sender: TObject);
begin
    if connected then  sendbyte(port,COMMAND_NEUTRE);
end;

procedure TForm1.rg_linClick(Sender: TObject);
begin
 if connected then
 begin
    sendbyte(port,COMMAND_INT_FLAGS);
    if rg_lin.ItemIndex=0 then  temp_dat:=(eepr.flags and $FFFE) //b0=0
    else temp_dat:=(eepr.flags or $0001); //b0=1
    eepr.flags:=temp_dat;
    sendbyte(port,(temp_dat shr 8));
    sendbyte(port,temp_dat and $FF);
    sendbyte(port,0);
    sendbyte(port,0);
 end;
end;

procedure TForm1.btn_inc_consigneClick(Sender: TObject);
begin
    if connected then  sendbyte(port,COMMAND_INC_CONSIGNE);
end;

end.

