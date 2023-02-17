/*
  .L6234 piloté en 1/2 pont
  .lecture aeat-6600 via spi 3 fils
  .configure rd0 en sortie ( led )
  .config timer1 , prediv=256 
  .interrupt timer1(100ms) : toggle led 
  .usart,38400bds,alternate pins	
Tosc=7.37MHz*16
/_1 : test simu capture ic_bobine logicielle
/_2 : conv ad synchronisée sur le signal pwm, au milieu du créneau 
/_2b : modif config
/_2c : consigne linéarisée , plus de calcul Kd , calculs en float
       extrapolation consigne en début de boucle
/_2d : switch linéaire/rot_const via le soft pc
	   mise au neutre au démarrage et à la fin de la treuillée     
/_2f : offset défini au milieu de la bobine ,
     au cours du mouvement de gauche à droite
     charge uc (t_lect6 en nombre de cycles (3686<->1ms)
/_2g : essai fonctionnement autonome , lecture switch selection 
/_2h : envoi données eeprom sur commande
/ sur base 'trancannage_2i.c'
	modifs: changement front sur entrée selection , maintenant , détection front montant pour action
	        pilotage L6234 via oc1(pwm_in) et rf3(pwm_en,sdo1 disabled)
	        lecture tensions sur ra0(courant) et ra1(tension batterie) , en simultané
/1 : modif gestion entrée sélection	        
/1b : mise en sommeil entre deux treuillées
      envoi tension Ubat en mode install , t_lect6 en mode asservissement
      traitement commande mise aux limites
*/

#include <p30f3010.h>
#include "Math.h"
#include "GenericTypeDefs.h"

/* Define constants here                            */
#define led 	LATCbits.LATC15 
#define selection PORTDbits.RD1 //int2
#define pwm_en LATFbits.LATF3 //#17

#define VERSION 2

#define	COMMAND_VISU_DATA_1 1
#define COMMAND_STORE_OFFS 2
#define COMMAND_WRITE_EEP 3
#define COMMAND_RESET 4
#define COMMAND_CHANGE_FREQ_BOUCLE 5
#define	COMMAND_VISU_DATA_2 6
#define COMMAND_BASCULE_IC_BOBINE 48
#define COMMAND_NEUTRE 7
#define COMMAND_INC_CONSIGNE 8
#define COMMAND_GOTO 9
#define COMMAND_SEND_EEP 10
#define COMMAND_LIMITE 11

#define do_loop flags.bits.b0
#define first_read flags.bits.b1
#define saturH flags.bits.b2
#define saturL flags.bits.b3
#define running flags.bits.b4
#define ask_for_running flags.bits.b5
#define ask_for_stop flags.bits.b6

/*FREQUENCY SYSTEM DEFINES*/
#define FCY  29491200			//FRC w/PLL x16
#define MILLISEC FCY/29491		//1 mSec delay constant
#define FPWM 20000				//20KHz PWM Freq

#define FLANC_MONTANT 0x03
#define FLANC_DESCENDANT 0x02
#define FLANC_MONTANT_DESCENDANT 0x01

#define VMAX 4096.0
#define A_ACC (VMAX/2.0)
#define A_DEC (VMAX/6.0)



typedef union
{
  float fvalue;
  unsigned char ivalue[4];
} __ieee_float;
typedef struct
{	unsigned int version;
	WORD_VAL flags;//b0: 0:rotation constante/1:mouvement linéaire
	               //
	unsigned int offset_as5040;
	unsigned int volts_manuel;
	unsigned int largeur_bobine;
	unsigned int freq_boucle;
	unsigned int idata1;
	unsigned int idata2;
	unsigned int idata3;
	unsigned int idata4;
	unsigned int idata5;
	unsigned int idata6;
	unsigned int idata7;
	unsigned int idata8;
	unsigned int idata9;
	unsigned int idata10;
	 //int d'abord , float après
	float Kp;
	float Ki;
	float Kd;
	float pas;
	float fdata1;
	float fdata2;
	float fdata3;
	float fdata4;
	float fdata5;
	float fdata6;
	float fdata7;
	float fdata8;
	float fdata9;
	float fdata10;
} CONFIG_EEP;

#define OFFSET_FIRST_FLOAT 16 //index config.words du premier mot en float(lsw)

typedef union
{
	CONFIG_EEP eepr;
	unsigned int words[256];
} BUFFER_EEP;	

//theta=f(lin) , par pas de 5mm pour bobine de 140mm
// soit 5*32768/140=1170.28 ; index=0..56
const unsigned int f_lin[] __attribute__((space(auto_psv)))=
						 	{0,9,18,28,37,46,55,64,
							75,85,95,108,123,142,191,240,
							264,282,302,317,330,344,357,369,
							380,394,406,417,429,441,452,465,
							477,490,503,517,532,548,564,583,
							606,630,715,801,836,864,887,905,
							922,937,953,966,980,991,1002,1013,1024};
/*							 
								  {0,74,106,133,155,174,192,207,
						  222,236,248,260,272,283,294,300,
						  310,318,329,338,346,356,365,375,
						  386,400,412,432,487,549,572,590,
						  607,620,633,646,659,670,683,696,
						  706,719,727,740,751,763,776,788,
						  801,816,831,847,864,883,903,924,1024};
*/						  

 
/************* START OF GLOBAL DEFINITIONS **********/
volatile WORD_VAL flags;
volatile unsigned char debounce_select=0;
volatile unsigned int t_lect6=0;
volatile unsigned char rx_command=0;
volatile unsigned int adc_result_i=0;
volatile unsigned int adc_result_u=0;
volatile unsigned int pos_bobine=0;
volatile unsigned int cmpt_tmr3=0;
volatile unsigned long periode_bobine=0xFFFFFFFF;
unsigned int pos_as5040=0;
volatile BUFFER_EEP config; 
volatile unsigned char cmpt_nvm=0;
volatile float consigne_theta=0;
volatile float next_consigne_theta=0;
volatile float consigne_lin=0;
volatile float next_consigne_lin=0;
volatile float incr_loop=0;
volatile unsigned int cmpt_incr=0;
unsigned int cmpt_incr_goto_acc=0;
float incr_loop_goto_acc=0;
unsigned int cmpt_incr_goto_dec=0;
float incr_loop_goto_dec=0;
unsigned int cmpt_incr_goto_cte=0;
float incr_loop_goto_cte=0;
	
unsigned char dat_transmit[28];
volatile unsigned char tx_cmpt=0;
volatile unsigned char index_tx;

unsigned int data_out=0;
unsigned char cmpt_visu=0;
float Ep0;
float Epu;
float sum_erreur=0;

unsigned char cmpt_before_sleep=0;

/************** END OF GLOBAL DEFINITIONS ***********/


void init_tmr1(void);
void init_tmr4(void);
void init_usart(void);
void init_IO(void);
void init_spi(void);
void delay100ms(void);
void delay500us(void);
void delay2us(void);
void delay500ns(void);
void usart_emi(unsigned int data);
unsigned int usart_rec(void);
float lire_eep_float(unsigned int offset);
void ecrire_eep_float(float* donnee,unsigned int offset);
void InitOC1(void);
void lecture_config(unsigned int nb_words,int envoi);
void eeprom_load_defaults(unsigned int nb_words);
unsigned int lire_eep_int(unsigned int offset);
void init_IC_bobine(void);
void init_IC2(unsigned int flanc,unsigned int int_enable);
void init_tmr3(void);
void InitADC10(void);
extern void nvm_key_sequ(void);
void calc_incr_consigne(void);
void calc_neutre(void);
void calc_limites(void);
void calc_goto(unsigned int pos_goto);
void init_int_select(void);
	
/************* START OF MAIN FUNCTION ***************/

int main ( void )  
{	unsigned char i=0;
	unsigned int j=0;
//	unsigned int temp_spi;	
	unsigned int temp_tx;	
	unsigned long temp_tx_l;	
	unsigned int temp_pdc;
	unsigned char ack_commande=0;
		
	flags.Val = 0;

	SRbits.IPL = 7; // off
	init_IO();
#define debug 0
	#if debug==1
		eeprom_load_defaults(sizeof(config.eepr)>>1);	
		pos_as5040=46600;
	#endif

	#if debug==0
		init_usart();
	//test si eeprom corrompue , ou changement version
		//on lit le 1er emplacement = version
		if (lire_eep_int(0)!=VERSION) eeprom_load_defaults(sizeof(config.eepr)>>1);	
		lecture_config(sizeof(config.eepr)>>1,0); //sizeof:bytes,  /2->words
		for (i=0;i<20;i++)
		{	__asm__ volatile ("BTG LATC,#15"); 
			delay100ms();
		}
	
	#endif
	
 	init_tmr1();
 	init_tmr4(); //charge uc timebase
	init_tmr3(); //input capture timebase
//	init_IC_bobine(); //sur ic7(#6)
	init_int_select();
	
	InitOC1();	//Configuring OC1 module in pwm mode
 	
  	init_spi();
	InitADC10();

	
	SRbits.IPL = 0;
	#if debug==0
	while (!do_loop);
	do_loop=0;
	#endif	
	
	ask_for_stop=1;
	debounce_select=1;//pour ne démarrer la scrutation de sélection
					   // seulement au bout d'1 seconde
	pwm_en=1;//enable L6234
	
	while (1)
	{		
	#if debug==0
		while (!do_loop);
		do_loop=0;
	#endif		
		t_lect6=TMR4;	//temps libre (mis à 0 à la fin de la boucle
		
		if (cmpt_incr)
		{	consigne_theta-=incr_loop;
			cmpt_incr--;
			if (consigne_theta<0) consigne_theta+=65536.0;
		}
		if (cmpt_incr_goto_dec)
		{	if (cmpt_incr_goto_acc)
			{ //accélération
				incr_loop_goto_acc+=A_ACC/((float)config.eepr.freq_boucle*(float)config.eepr.freq_boucle);//incrémenté de 8192/2*freq_boucle à chaque boucle	
				consigne_theta-=incr_loop_goto_acc;
				cmpt_incr_goto_acc--;
				if (consigne_theta<0) consigne_theta+=65536.0;
			}
			else //fin accélération
			{	if (cmpt_incr_goto_cte)
				{ //vitesse constante
					consigne_theta-=incr_loop_goto_cte;
					cmpt_incr_goto_cte--;
					if (consigne_theta<0) consigne_theta+=65536.0;
				}
				else //fin vitesse constante ou décélération directe
				{	incr_loop_goto_dec-=A_DEC/((float)config.eepr.freq_boucle*(float)config.eepr.freq_boucle);//décrémenté de 8192/4*freq_boucle à chaque boucle
					if (incr_loop_goto_dec<0) incr_loop_goto_dec=128.0/config.eepr.freq_boucle;
					consigne_theta-=incr_loop_goto_dec;
					cmpt_incr_goto_dec--;
					if (consigne_theta<0) consigne_theta+=65536.0;
					Ep0=next_consigne_theta-consigne_theta;
					if (Ep0<-32767.0) Ep0+=65536.0;
					if (Ep0>32767.0) Ep0-=65536.0;
		
					if (Ep0>=0)	cmpt_incr_goto_dec=0;
					else
					{	if (cmpt_incr_goto_dec==0)	cmpt_incr_goto_dec=1;
					}		
							
				}	
			}	
		}
  
			
		//calcul erreur Ep0
		//erreur=consigne-state
		//ici , inversé car consigne et state diminuent
		Ep0=(float)(pos_as5040-config.eepr.offset_as5040)-consigne_theta;
		if (Ep0<-32767.0) Ep0+=65536.0;
		if (Ep0>32767.0) Ep0-=65536.0;
		if (Ep0<0)
		{	if (!saturL) 
			{	sum_erreur+=Ep0;
			}	
		}
		else
		{	if (!saturH) sum_erreur+=Ep0;
		}
		Epu=config.eepr.Ki*sum_erreur/10000;
		Epu+=config.eepr.Kp*Ep0/100;
		
		saturH=0;
		saturL=0;
		if (Epu>=0)
		{ 	if (Epu>1473.0)
			{	temp_pdc=1473;
				saturH=1;
			}	
			else temp_pdc=(unsigned int)Epu;
		}	
		else
		{	sum_erreur=0;
		    temp_pdc=0;
			saturL=1;
		}	
		if (config.eepr.volts_manuel==0)
		{	OC1RS=temp_pdc;
		}
	
	
		if (rx_command)
		{	switch (rx_command)
			{	case COMMAND_VISU_DATA_1 :
 					data_out=COMMAND_VISU_DATA_1;
			   		break;
				case COMMAND_VISU_DATA_2 :
 					data_out=COMMAND_VISU_DATA_2;
			   		break;
				case COMMAND_STORE_OFFS :
			        config.eepr.offset_as5040=pos_as5040;
				 	ack_commande=20;
				 	break;
				case COMMAND_CHANGE_FREQ_BOUCLE :
					init_tmr1(); //changement freq_boucle
					break;
				case COMMAND_RESET :
			        __asm__ volatile ("reset"); 
			        break; 	
				case COMMAND_NEUTRE :
			        calc_neutre();
			        break; 	
				case COMMAND_LIMITE :
			        calc_limites();
			        break; 	
				case COMMAND_GOTO :
			        calc_goto(config.eepr.idata1<<6);
			        break; 	
			    case COMMAND_INC_CONSIGNE :
			  		consigne_theta-=64; //  : 1/1000ème de tour de la came
					if (consigne_theta<0) consigne_theta+=65536.0; 
			    	break;    
				case COMMAND_SEND_EEP :
			        data_out=COMMAND_SEND_EEP;
			        break; 	
				case COMMAND_WRITE_EEP :
			        //on lance la mémorisation (erase and write)
			        //de la structure config.words 
			        //la procédure se poursuit via les interruptions
			        //1st stage :effacement 1er row de 16 words
//					operation_eeprom=1; //pour éviter la mise en Idle
					cmpt_nvm=0; //compteur états dans interrupt nvm
					TBLPAG = 0x7F;// __builtin_tblpage(user_data);
					NVMADRU = 0x7F;//__builtin_tblpage(user_data);
					NVMADR = 0xFC00;//__builtin_tbloffset(user_data);
					NVMCON = 0x4045; //erase one row of eeprom
					IPC3bits.NVMIP = 2; /* set priority level */
					IFS0bits.NVMIF = 0;
					IEC0bits.NVMIE = 1; //enable eeprom interrupt
			  		nvm_key_sequ();
			  		ack_commande=20;
				 	break; 	
			}	 	
			rx_command=0;
			cmpt_visu=0;
		}
		cmpt_visu++;
		if (cmpt_visu==(config.eepr.freq_boucle/10)) //envoi toutes les 1s/10=100ms
		{	
			if (ack_commande) 
			{	ack_commande--;
				led=1;
			}	
			else 
			{	if (running) __asm__ volatile ("BTG LATC,#15"); 
				else led=0;
			}	
			cmpt_visu=0;
			
			if (debounce_select) 
			{	debounce_select--;
				if (debounce_select==0)
				{	//test état entrée
					if (ask_for_running)
					{	if (selection)
						{	running=1;
							pwm_en=1;//enable L6234
							//start interrupt ic_bobine
							init_IC_bobine(); //sur ic7(#6)
							//next interrupt on positive edge
							INTCON2bits.INT2EP=1; //1:neg edge , 0:pos edge	
						}
						else cmpt_before_sleep=1;//pour remettre en sleep immédiatement
					}		
					ask_for_running=0;
					if ((ask_for_stop)&&(!selection))
					{	running=0;
						//stop interrupt ic_bobine
						IC7CON = 0;
						IEC1bits.IC7IE = 0; /* disable interrupts */
						//next interrupt on negative edge
						INTCON2bits.INT2EP=0; //1:neg edge , 0:pos edge	
						rx_command=COMMAND_NEUTRE; // pour remettre au neutre
						cmpt_before_sleep=150;//15s
					}
					ask_for_stop=0;
					IFS1bits.INT2IF = 0; /* clear interrupt flag */	
					IEC1bits.INT2IE = 1; // enable interrupt
				}	
			}
			if (cmpt_before_sleep)
			{	cmpt_before_sleep--;
				if (cmpt_before_sleep==0)
				{	pwm_en=0; //L6234 off
					//sum_erreur=0;
					Sleep();
				}	
				
			}	
				
			
			if (config.eepr.volts_manuel)
			{	OC1RS=config.eepr.volts_manuel;
			}
			switch (data_out)
			{	case COMMAND_VISU_DATA_1 :
					U1TXREG=0xF0;
					U1TXREG=0xF1;
					U1TXREG=0xF2;
					temp_tx=pos_bobine;//pos_as5040;
					U1TXREG=temp_tx >> 8;
					U1TXREG=temp_tx & 0xFF;
					j=0;
					temp_tx_l=periode_bobine;
					dat_transmit[j++]=temp_tx_l >> 24;
					dat_transmit[j++]=(temp_tx_l >> 16)& 0xFF;
					dat_transmit[j++]=(temp_tx_l >> 8)& 0xFF;
					dat_transmit[j++]=temp_tx_l & 0xFF;
					temp_tx=adc_result_i;//config.eepr.volts_svm;
					dat_transmit[j++]=temp_tx >> 8;
					dat_transmit[j++]=temp_tx & 0xFF;
					temp_tx=pos_as5040>>6;
					dat_transmit[j++]=temp_tx >> 8;
					dat_transmit[j++]=temp_tx & 0xFF;
					temp_tx=adc_result_u;//t_lect6;
					dat_transmit[j++]=temp_tx >> 8;
					dat_transmit[j++]=temp_tx & 0xFF;
				break;	
				case COMMAND_VISU_DATA_2 :
					U1TXREG=0xF0;
					U1TXREG=0xF1;
					U1TXREG=0xF2;
					temp_tx=pos_bobine;//pos_as5040;
					U1TXREG=temp_tx >> 8;
					U1TXREG=temp_tx & 0xFF;
					j=0;
					temp_tx=(int)Ep0;
					dat_transmit[j++]=temp_tx >> 8;
					dat_transmit[j++]=temp_tx & 0xFF;
					temp_tx=temp_pdc;
					dat_transmit[j++]=temp_tx >> 8;
					dat_transmit[j++]=temp_tx & 0xFF;
					temp_tx=((unsigned int)consigne_theta)>>6;
					dat_transmit[j++]=temp_tx >> 8;
					dat_transmit[j++]=temp_tx & 0xFF;
					temp_tx=(pos_as5040-config.eepr.offset_as5040)>>6;//pos_as5040>>6;
					dat_transmit[j++]=temp_tx >> 8;
					dat_transmit[j++]=temp_tx & 0xFF;
					temp_tx=t_lect6;
					dat_transmit[j++]=temp_tx >> 8;
					dat_transmit[j++]=temp_tx & 0xFF;
				break;	
				case COMMAND_SEND_EEP : 
					data_out=0;
					U1TXREG=0xF3;
					temp_tx=config.words[0];//version
					U1TXREG=temp_tx >> 8;
					U1TXREG=temp_tx & 0xFF;
					j=0;
					temp_tx=config.words[1];//flags
					dat_transmit[j++]=temp_tx >> 8;
					dat_transmit[j++]=temp_tx & 0xFF;
					temp_tx=config.words[2];//offset_as5040
					dat_transmit[j++]=temp_tx >> 8;
					dat_transmit[j++]=temp_tx & 0xFF;
					temp_tx=config.words[3];//volts_manuel
					dat_transmit[j++]=temp_tx >> 8;
					dat_transmit[j++]=temp_tx & 0xFF;
					temp_tx=config.words[4];//largeur_bobine
					dat_transmit[j++]=temp_tx >> 8;
					dat_transmit[j++]=temp_tx & 0xFF;
					temp_tx=config.words[5];//freq_boucle
					dat_transmit[j++]=temp_tx >> 8;
					dat_transmit[j++]=temp_tx & 0xFF;
					temp_tx=config.words[16];//Kp low
					dat_transmit[j++]=temp_tx >> 8;
					dat_transmit[j++]=temp_tx & 0xFF;
					temp_tx=config.words[17];//Kp high
					dat_transmit[j++]=temp_tx >> 8;
					dat_transmit[j++]=temp_tx & 0xFF;
					temp_tx=config.words[18];//Ki low
					dat_transmit[j++]=temp_tx >> 8;
					dat_transmit[j++]=temp_tx & 0xFF;
					temp_tx=config.words[19];//Ki high
					dat_transmit[j++]=temp_tx >> 8;
					dat_transmit[j++]=temp_tx & 0xFF;
					temp_tx=config.words[20];//Kd low
					dat_transmit[j++]=temp_tx >> 8;
					dat_transmit[j++]=temp_tx & 0xFF;
					temp_tx=config.words[21];//Kd high
					dat_transmit[j++]=temp_tx >> 8;
					dat_transmit[j++]=temp_tx & 0xFF;
					temp_tx=config.words[22];//pas low
					dat_transmit[j++]=temp_tx >> 8;
					dat_transmit[j++]=temp_tx & 0xFF;
					temp_tx=config.words[23];//pas high
					dat_transmit[j++]=temp_tx >> 8;
					dat_transmit[j++]=temp_tx & 0xFF;
				break;
			}	
			tx_cmpt=j; //càd le nombre de 'dat_transmit'
			index_tx=0; //index tableau dat_transmit
			IFS0bits.U1TXIF = 0;
			IEC0bits.U1TXIE = 1; //enable transmit interrupt  		  
		}
		TMR4=0;
	}

}
void calc_goto(unsigned int pos_goto)
{	unsigned int dist;
	unsigned long d_var;
	//Vmax=1/2 tour en 4 secondes , soit 32768/4=8192/s
  //accélération : 0 à Vmax en 2s
  //décélération : Vmax à 0 en 4s
  //distance de 0 à Vmax = 1/2*Vmax^2/acc = Vmax
  //distance de Vmax à 0 = 1/2*Vmax^2/acc = 2*Vmax
  //test si distance > dist_acc+dist_dec=3*Vmax=24576
  d_var=((VMAX*VMAX)*(A_ACC+A_DEC)/(A_ACC*A_DEC))/2;
  	next_consigne_theta=pos_goto;
	dist=pos_as5040-config.eepr.offset_as5040-pos_goto;
	if (dist>d_var) //étape à Vcte=Vmax		
	{	//calcul cmpt_incr_goto_acc,incr_loop_goto_acc,cmpt_incr_goto_dec,
		//incr_loop_goto_dec,cmpt_incr_goto_cte,incr_loop_goto_cte
		incr_loop_goto_cte=VMAX/config.eepr.freq_boucle;
		//cmpt_incr_goto_cte=(dist-d_var)/(unsigned int)incr_loop_goto_cte;
		cmpt_incr_goto_cte=(dist-d_var)/incr_loop_goto_cte;
		incr_loop_goto_acc=0;//incrémenté de 8192/2*freq_boucle à chaque boucle
		cmpt_incr_goto_acc=(VMAX/A_ACC)*config.eepr.freq_boucle;
	 	incr_loop_goto_dec=VMAX/config.eepr.freq_boucle;//décrémenté de 8192/4*freq_boucle à chaque boucle
		cmpt_incr_goto_dec=(VMAX/A_DEC)*config.eepr.freq_boucle;
	}
	else //pas assez de temps pour atteindre Vmax
	{
		incr_loop_goto_cte=0;
		cmpt_incr_goto_cte=0;
		incr_loop_goto_acc=0;//incrémenté de 8192/2*freq_boucle à chaque boucle
		cmpt_incr_goto_acc=(unsigned int)(sqrtf((4*(float)dist)/(3*VMAX))*config.eepr.freq_boucle);//sqrtf(4*d/3*Vmax)
		incr_loop_goto_dec=(unsigned int)(sqrtf((VMAX*(float)dist)/3)/config.eepr.freq_boucle);//sqrtf(dist*Vmax/3) 
		                   //décrémenté de 8192/4*freq_boucle à chaque boucle
		cmpt_incr_goto_dec=cmpt_incr_goto_acc*(A_ACC/A_DEC); //*2
	}	
}	

void calc_neutre(void)
{	//mise au neutre
	consigne_theta=pos_as5040-config.eepr.offset_as5040;	
	if ((consigne_theta>(f_lin[0]<<6))&&(consigne_theta<(f_lin[28]<<6))) 
	{	next_consigne_theta=f_lin[0]<<6;
		next_consigne_lin=0;
	}	
	else
	{	next_consigne_theta=(f_lin[28]<<6);
		next_consigne_lin=32768;
	}	
	calc_goto(next_consigne_theta);
}
void calc_limites(void)
{	//mise à la limite la plus proche , index 14  / 42
	consigne_theta=pos_as5040-config.eepr.offset_as5040;	
	if ((consigne_theta>(f_lin[14]<<6))&&(consigne_theta<(f_lin[42]<<6))) 
	{	next_consigne_theta=f_lin[14]<<6;
		next_consigne_lin=16384;
	}	
	else
	{	next_consigne_theta=(f_lin[42]<<6);
		next_consigne_lin=49152;
	}	
	calc_goto(next_consigne_theta);
}
void init_int_select(void)
{
	TRISDbits.TRISD1 = 1; // ;Set select pin as input
	INTCON2bits.INT2EP=0; //1:neg edge , 0:pos edge	
	IPC5bits.INT2IP = 2; /* set priority level */
//	IFS1bits.INT2IF = 0; /* clear interrupt flag */
//	IEC1bits.INT2IE = 1; /* enable interrupts */
}	

void init_tmr1(void)
{
	T1CON = 0;
	TMR1 = 0; /* clear timer1 register */
	PR1=FCY/(8*config.eepr.freq_boucle);
	T1CON = 0x8010; /* Get Timer1 settings (1:8 prescaler) */
	IPC0bits.T1IP = 2; /* set priority level */
	IFS0bits.T1IF = 0; /* clear interrupt flag */
	IEC0bits.T1IE = 1; /* enable interrupts */
	//SRbits.IPL = 3; /* enable CPU priority levels 4-7 */
}
void init_tmr4(void)
{
	T4CON = 0;
	TMR4 = 0; /* clear timer1 register */
	T4CON = 0x8010; /* Get Timer1 settings (1:8 prescaler) */
}

void init_usart(void)
{	U1BRG = 94 ;// Set Baudrate , 19200bds
	//U1BRG = 47 ;// Set Baudrate , 38400bds
	U1STA = 0 ;
	U1MODE = 0x8480 ; /* ; Enable UART for 8-bit data,
				     	; no parity, 1 STOP bit,
				    	; wakeup enabled
				    	; alternate pins, rx:#12 , tx:#11 */
	U1STAbits.UTXEN = 1 ;//; Enable transmit	
	U1STAbits.UTXISEL = 1;//interrupt when tx buffer empty ( each 4 sent )
	IPC2bits.U1RXIP = 3; //
	IFS0bits.U1RXIF = 0;
	IEC0bits.U1RXIE = 1; //enable receive interrupt (from interface)
	IPC2bits.U1TXIP = 3; //
	//IFS0bits.U1TXIF = 0;
	//IEC0bits.U1TXIE = 1; //enable transmit interrupt 
}

void init_IO(void)
{ //Initialize LED output on PORTC bit 15
	led = 0;
	TRISCbits.TRISC15 = 0; // Set LED pin as output
	//LATCbits.LATC15 = 1; //Turn LED on
	pwm_en=0; //L6234 off
	TRISFbits.TRISF3 = 0; // Set pwm_en as output
}

void InitADC10(void)
{
	ADPCFG = 0xFFFC;	//Port pin multiplexed with AN0,AN1 in Analog mode
	
	ADCON1 = 0x000C;    //ADC is off
						//Continue module operation in Idle mode
						//10-bit, 4-channel ADC operation
						//Data Output Format bits Integer (0000 00dd dddd dddd)
						//000 = clearing samp end sampling and start conv
						//Samples CH0,CH1 simultanously
                        //Sampling begins immediately after last conversion SAMP bit is auto-set.

	ADCHS = 0x0001;    //MUX B pas utilisé
				//MUX A ch0 negative input is VREF-
				//MUX A ch0 positive input is an1
				//MUX A ch1 negative input is VREF-
				//MUX A ch1 positive input is an0
				
	ADCSSL = 0x0000;	//Skip all ANx channels for input scan

	ADCON3 = 0x0005;	//ADC Clock derived from system clock
						//Autosample time time bits = 0 TAD since PWM is controlling sampling time
						//TAD = 3*TCY, TAD = 101.7 nSec
						

	ADCON2 = 0x0100;	//ADREF+ = AVDD ADREF- = AVSS
						//Do not scan inputs
						//01 = Converts CH0 an CH1
						//A/D is currently filling buffer 0x0-0x7
						//Interrupts at the completion of conversion for each sample/convert sequence
						//Always starts filling buffer from the beginning
						//Always uses channel input selects for Sample A
	
	ADCON1bits.DONE = 0;
	IPC2bits.ADIP = 4;	
	IFS0bits.ADIF = 0;	
	IEC0bits.ADIE = 1;
	ADCON1bits.ADON=1;
}
void init_spi(void)
{  	//aeat-6600 cs mis à la masse en hardware
	//mode master
	SPI1CON=0x0E79;//,sdo disabled,mode16,cke=0,ckp=1,smp=1,ssen=0,master,937kHz
	//SPI1CON=0x0E71;//mode16,cke=0,ckp=1,smp=1,ssen=0,master,469kHz
	SPI1STATbits.SPIROV=0;
	SPI1STATbits.SPIEN=1;
	IPC2bits.SPI1IP = 2; /* set priority level */
	IFS0bits.SPI1IF = 0; /* clear interrupt flag */
	IEC0bits.SPI1IE = 1; /* enable interrupts */
}	

//void __attribute__ ((address(0x800))) delay100ms(void) 	/* provides delay for atleast 15msec */
void delay100ms(void) 	/* provides delay for atleast 15msec */
	{   unsigned int i;
		unsigned int j;
    for(i=0;i < 39306;i++)
    {	for (j=0;j<10;j++) asm("nop");
      	
      }  
}
void delay500ns(void) 	
{   unsigned int i;
	for (i=0;i<2;i++) ;
}
void delay2us(void) 	
{   unsigned int i;
	for (i=0;i<8;i++) ;
}
void delay500us(void) 	
{   unsigned int i;
	for (i=0;i<2000;i++) ;
}
void usart_emi(unsigned int data)
{   while(U1STAbits.UTXBF);
	U1TXREG = data;
	//while(!U1STAbits.TRMT);
}	
unsigned int usart_rec(void)
{   while(!U1STAbits.URXDA);
    return (U1RXREG);
}	
float lire_eep_float(unsigned int offset)
{	
	//lecture eep de données codées en float
	//offset=rang , on tient compte ici que la donnée est codée sur 4 octets
	long temp_long_eep;
	unsigned int temp_word_eep;
	float* temp_float_ptr;
	temp_float_ptr=(float*)&temp_long_eep;
	TBLPAG = 0x7F;// __builtin_tblpage(user_data);
	              //eep_adr = __builtin_tbloffset(user_data);//0xFC00
	temp_word_eep = __builtin_tblrdl(0xFC00+(4*offset));
	temp_long_eep=temp_word_eep;
	temp_word_eep = __builtin_tblrdl(0xFC02+(4*offset));
	temp_long_eep+=((long)temp_word_eep)<<16;
	return (*temp_float_ptr);
}	

void ecrire_eep_float(float* donnee,unsigned int offset)
{	
	//codage float->word pour sauvegarde eeprom
	//offset=rang , on tient compte ici que la donnée est codée sur 4 octets
	int* temp_int_ptr;
	unsigned int temp_word_eep;
	temp_int_ptr=(int*)donnee;//&delta
	temp_word_eep=*temp_int_ptr;//1er emplacement eeprom

	TBLPAG = 0x7F;// __builtin_tblpage(user_data);
	NVMADRU = 0x7F;//__builtin_tblpage(user_data);
	NVMADR = 0xFC00+(4*offset);//__builtin_tbloffset(user_data);
	NVMCON = 0x4044; //erase one word of eeprom
	NVMKEY = 0x55;
	NVMKEY = 0xAA;
	NVMCONbits.WR = 1;
	while (NVMCONbits.WR);
	
	//écriture poids faible du codage float ieee
	__builtin_tblwtl(NVMADR,temp_word_eep);
	
	NVMCON = 0x4004; //program one word of eeprom
	NVMKEY = 0x55;
	NVMKEY = 0xAA;
	NVMCONbits.WR = 1;
	while (NVMCONbits.WR);

	NVMADR += 2;
	NVMCON = 0x4044; //erase one word of eeprom
	NVMKEY = 0x55;
	NVMKEY = 0xAA;
	NVMCONbits.WR = 1;
	while (NVMCONbits.WR);

	temp_int_ptr++;
	temp_word_eep=*temp_int_ptr;//2ème emplacement eeprom

	//écriture poids fort du codage float ieee
	__builtin_tblwtl(NVMADR,temp_word_eep);
	
	NVMCON = 0x4004; //program one word of eeprom
	NVMKEY = 0x55;
	NVMKEY = 0xAA;
	NVMCONbits.WR = 1;
	while (NVMCONbits.WR);
}

void InitOC1(void)
{	//timer base : tmr2
	T2CON = 0x0000; /* Get Timer2 settings (1:1 prescaler) */	
	TMR2 = 0; /* clear timer2 register */
	PR2=((FCY/FPWM) - 1);
						//FCY  29491200...FRC w/PLL x16
						//FPWM 20KHz PWM Freq
						// MAX_DUTY_CYCLE = 1473
						// 50% duty cycle = 736
	OC1R = 0;	    // Initialize as 0 voltage
	OC1RS = 0;	    // Initialize as 0 voltage
	OC1CON = 0x0006; //pwm mode, fault pin disabled,timer2 clock source
	T2CONbits.TON=1; //start timer2
}

void lecture_config(unsigned int nb_words,int envoi)
{ //lecture données en eeprom
  //formatées à l'aide de struct config_eep et union buffer_eep
  //on lit tout en entier 
  //on envoie via usart si pc connecté
	unsigned int temp_word_eep;
	unsigned int temp_adr_eep=0xFC00;
	unsigned int i;
	
	TBLPAG = 0x7F;// __builtin_tblpage(user_data);
	              //eep_adr = __builtin_tbloffset(user_data);//0xFC00
	for (i=0;i<nb_words;i++)
	{	temp_word_eep = __builtin_tblrdl(temp_adr_eep);
		config.words[i] = temp_word_eep;
		if (envoi)
		{	usart_emi(temp_word_eep >> 8);
			usart_emi(temp_word_eep & 0xFF);
		}	
		temp_adr_eep+=2;
	}	
}	
void eeprom_load_defaults(unsigned int nb_words)
{	int i;
	unsigned int temp_adr_eep_def=0xFC00;
	unsigned int nb_eep_def=0;
	unsigned int index_nvm_def=0;

	config.eepr.version=VERSION;
	config.eepr.flags.Val=1;
	config.eepr.offset_as5040=0;
	config.eepr.volts_manuel=0;
	config.eepr.largeur_bobine=140;
	config.eepr.freq_boucle=100;
	config.eepr.idata1=0;
	config.eepr.idata2=0;
	config.eepr.idata3=0;
	config.eepr.idata4=0;
	config.eepr.idata5=0;
	config.eepr.idata6=0;
	config.eepr.idata7=0;
	config.eepr.idata8=0;
	config.eepr.idata9=0;
	config.eepr.idata10=0;
	 //int d'abord , float après
	config.eepr.Kp=11.2;
	config.eepr.Ki=.1;
	config.eepr.Kd=0.0;
	config.eepr.pas=5.0;
	config.eepr.fdata1=0.0;
	config.eepr.fdata2=0.0;
	config.eepr.fdata3=0.0;
	config.eepr.fdata4=0.0;
	config.eepr.fdata5=0.0;
	config.eepr.fdata6=0.0;
	config.eepr.fdata7=0.0;
	config.eepr.fdata8=0.0;
	config.eepr.fdata9=0.0;
	config.eepr.fdata10=0.0;
	

	TBLPAG = 0x7F;// __builtin_tblpage(user_data);
	NVMADRU = 0x7F;//__builtin_tblpage(user_data);
	
	do
	{	NVMADR=temp_adr_eep_def;
		NVMCON = 0x4045; //erase one row of eeprom
		nvm_key_sequ();
		while (NVMCONbits.WR);//attente fin d'opération
		for (i=0;i<16;i++)
		{	//__builtin_tblwtl(temp_adr_eep,adr_nvm++);
			__builtin_tblwtl(temp_adr_eep_def,config.words[index_nvm_def++]);
			temp_adr_eep_def+=2;
		}
		nb_eep_def+=16;	
		NVMCON = 0x4005; //program one row of eeprom
		nvm_key_sequ();
		while (NVMCONbits.WR);//attente fin d'opération
		//si d'autres données , on efface le rang suivant de 16 words
		//sinon , fin procédure
	}	
	while ((sizeof(config.eepr)>>1)>nb_eep_def);
}	

unsigned int lire_eep_int(unsigned int offset)
{	
	//lecture eep 
	//offset=rang , on tient compte ici que la donnée est codée sur 2 octets
	unsigned int temp_word_eep;
	TBLPAG = 0x7F;// __builtin_tblpage(user_data);
	              //eep_adr = __builtin_tbloffset(user_data);//0xFC00
	temp_word_eep = __builtin_tblrdl(0xFC00+(2*offset));
	return (temp_word_eep);
}	
void init_IC2(unsigned int flanc,unsigned int int_enable)
{ //init input capture
	IC2CON = 0;
	IC2CON = flanc ; //0x01 :tmr3 captured, every edge
					//0x03 :tmr3 captured, every rising edge
					//0x02 :tmr3 captured, every falling edge
	IPC1bits.IC2IP = 3; /* set priority level */
	IFS0bits.IC2IF = 0; /* clear interrupt flag */
	if (int_enable)	IEC0bits.IC2IE = 1; /* enable interrupts */
}
void init_IC_bobine(void)
{	IC7CON = 0;
	IC7CON = 0x02; //0x01 :tmr3 captured, every edge
					//0x03 :tmr3 captured, every rising edge
					//0x02 :tmr3 captured, every falling edge
	IPC4bits.IC7IP = 3; /* set priority level */
	IFS1bits.IC7IF = 0; /* clear interrupt flag */
	IEC1bits.IC7IE = 1; /* enable interrupts */
}	
void init_tmr3(void)
{
	T3CON = 0x8030; //prescale 1:256, on
	TMR3 = 0; /* clear timer1 register */
	IPC1bits.T3IP = 2; /* set priority level */
	IFS0bits.T3IF = 0; /* clear interrupt flag */
	IEC0bits.T3IE = 1; /* enable interrupts */
	//SRbits.IPL = 3; /* enable CPU priority levels 4-7 */
}
void calc_incr_consigne(void)
{	
	float temp_float1;
	float temp_float2;
	float delta_lin;
	unsigned char index_p;
	
	consigne_theta=next_consigne_theta;
	
	//temp_int=pos_as5040-config.eepr.offset_as5040;
	temp_float1=(32.0*(float)periode_bobine)/PR1;
	cmpt_incr=(unsigned int)temp_float1;
	
	if (config.eepr.flags.bits.b0)
	{ //linéaire
		consigne_lin=next_consigne_lin;
		delta_lin=32768.0*config.eepr.pas/config.eepr.largeur_bobine;
		next_consigne_lin-=delta_lin;
		if (next_consigne_lin<=0) next_consigne_lin+=65536.0;
		temp_float2=ceilf(next_consigne_lin/1170.285714);
		index_p=(unsigned char)temp_float2;
		temp_float2=((temp_float2*1170.285714)-next_consigne_lin)/1170.285714;
		next_consigne_theta=64*(f_lin[index_p]-(temp_float2*(f_lin[index_p]-f_lin[index_p-1])));
		incr_loop=(consigne_theta-next_consigne_theta);
		if (incr_loop<0) incr_loop+=65536.0;
		incr_loop/=temp_float1;
	}
	else
	{ //rotation constante
		next_consigne_theta=32768*config.eepr.pas/config.eepr.largeur_bobine;
		incr_loop=next_consigne_theta/temp_float1;
		next_consigne_theta=consigne_theta-next_consigne_theta;
		if (next_consigne_theta<-32767.0) next_consigne_theta+=65536.0;
	}		
	
}		
		
/****** START OF INTERRUPT SERVICE ROUTINES *********/

/* Replace the interrupt function names with the    */
/* appropriate names depending on interrupt source. */

/* The names of various interrupt functions for     */
/* each device are defined in the linker script.    */


/* Interrupt Service Routine 1                      */
/* No fast context save, and no variables stacked   */


/* Interrupt Service Routine 2                      */
/* Fast context save (using push.s and pop.s)       */

void __attribute__((__interrupt__,no_auto_psv)) _T1Interrupt(void)
{	
	//static int sticks=0;
	ADCON1bits.SAMP = 0 ; // start Converting
	SPI1BUF=0;//dummy
	//do_loop=1;
	IFS0bits.T1IF = 0; /* clear interrupt flag */

}

void __attribute__((__interrupt__,no_auto_psv)) _IC7Interrupt(void)
{
	static unsigned int memo_ic_tmr3;
	unsigned int temp_ic;
	while (IC7CONbits.ICBNE)
	{  	temp_ic=IC7BUF;
		periode_bobine=temp_ic-memo_ic_tmr3;
		if (temp_ic<memo_ic_tmr3) cmpt_tmr3--;
		periode_bobine+=((unsigned long)cmpt_tmr3<<16);
		memo_ic_tmr3=temp_ic;
		cmpt_tmr3=0;
		pos_bobine++;	
	    calc_incr_consigne();
	}	
	
	IFS1bits.IC7IF = 0; // clear interrupt flag 
}
void __attribute__((__interrupt__, __shadow__,no_auto_psv)) _T3Interrupt(void)
{	
	//déborde toutes les 256*65536/FCY=568ms
	cmpt_tmr3++;
	if (cmpt_tmr3&0x08)
	{	cmpt_tmr3--;
		periode_bobine=0xFFFFFFFF;
	}	
	IFS0bits.T3IF = 0; /* clear interrupt flag */

}

void __attribute__((__interrupt__,no_auto_psv)) _IC2Interrupt(void)
{
	IFS0bits.IC2IF = 0; // clear interrupt flag 
}
void __attribute__((__interrupt__,auto_psv)) _ADCInterrupt(void)
{	
	
	adc_result_u = ADCBUF0;	//ADC CH0 holds the Ubat value
	adc_result_i = ADCBUF1;	//ADC CH0 holds the I value
	
//	ADCON1bits.DONE = 0;
	IFS0bits.ADIF = 0;

}
void __attribute__((__interrupt__,no_auto_psv)) _U1RXInterrupt(void)
{ 	static int memo_adr_var;
	int temp_read;
	static unsigned int memo_ic_tmr3;
	unsigned int temp_ic;
	
	if (U1STAbits.URXISEL==0) //on a reçu une nouvelle commande,sur 1 octet
	{	rx_command=U1RXREG;			
		if (rx_command & 0x80)
		{	memo_adr_var=rx_command & 0x7F; //offset dans config.words[x]
			rx_command=0;
			U1STAbits.URXISEL=3; //interrupt flag set when 4 datas have been received								
		}
		if (rx_command==COMMAND_BASCULE_IC_BOBINE)
		{
			temp_ic=TMR3;
			periode_bobine=temp_ic-memo_ic_tmr3;
			if (temp_ic<memo_ic_tmr3) cmpt_tmr3--;
			periode_bobine+=((unsigned long)cmpt_tmr3<<16);
			memo_ic_tmr3=temp_ic;
			cmpt_tmr3=0;
			pos_bobine++;	
			rx_command=0;
			calc_incr_consigne();
		}	

	}
	else // on a reçu une nouvelle valeur , sur 4 octets(int ou float)
	{
		if (memo_adr_var>=OFFSET_FIRST_FLOAT) //float
		{	temp_read=U1RXREG << 8;
			config.words[memo_adr_var++]=temp_read | U1RXREG; //poids faible
			temp_read=U1RXREG << 8;
			config.words[memo_adr_var]=temp_read | U1RXREG; //poids fort
		}
		else //int
		{	temp_read=U1RXREG << 8;
			config.words[memo_adr_var]=temp_read | U1RXREG; //poids faible
			temp_read=U1RXREG;
			temp_read=U1RXREG; // 2 dummies
		}
		U1STAbits.URXISEL=0; //interrupt flag set when 1 data has been received					
	}	
	IFS0bits.U1RXIF = 0;
//	if (repos) Idle(); // mise au repos si pas de calculs en cours
}	
void __attribute__((__interrupt__,no_auto_psv)) _U1TXInterrupt(void)
{
	unsigned char nb_fifo=4;
	while ((tx_cmpt)&&(nb_fifo--))
	{	U1TXREG=dat_transmit[index_tx++];
		tx_cmpt--;
	}	
	if (tx_cmpt==0)	IEC0bits.U1TXIE=0;//disable transmit interrupt 

	IFS0bits.U1TXIF = 0;
//	if (repos) Idle(); // mise au repos si pas de calculs en cours

}
void __attribute__((__interrupt__,no_auto_psv)) _SPI1Interrupt(void)
{	
	pos_as5040=SPI1BUF; 
	IFS0bits.SPI1IF = 0;
	do_loop=1;
}	
void __attribute__((__interrupt__,no_auto_psv)) _NVMInterrupt(void)
{	int i;
	static unsigned int temp_adr_eep=0xFC00;
	static unsigned int nb_eep=0;
	static unsigned int index_nvm=0;
	
	IFS0bits.NVMIF = 0;
	cmpt_nvm++;
	switch (cmpt_nvm)
	{	case 0x01:  //on arrive ici après effacement d'un bloc
					//on rentre les 16 words suivant dans les latchs
			for (i=0;i<16;i++)
			{	//__builtin_tblwtl(temp_adr_eep,adr_nvm++);
				__builtin_tblwtl(temp_adr_eep,config.words[index_nvm++]);
				temp_adr_eep+=2;
			}
			nb_eep+=16;	
			NVMCON = 0x4005; //program one row of eeprom
			nvm_key_sequ();

			break;
		case 0x02:  //si d'autres données , on efface le rang suivant de 16 words
					//sinon , fin procédure
			if ((sizeof(config.eepr)>>1)>nb_eep)
			{	cmpt_nvm=0;
				NVMADR=temp_adr_eep;
				NVMCON = 0x4045; //erase one row of eeprom
		  		nvm_key_sequ();
			}
			else 
			{	IEC0bits.NVMIE = 0; //disable eeprom interrupt
				temp_adr_eep=0xFC00;
				nb_eep=0;
				index_nvm=0;
//				operation_eeprom=0;
//				if (repos) Idle(); // mise au repos si pas de calculs en cours		
			}
			break;
	}

}	
void __attribute__((__interrupt__,no_auto_psv)) _INT2Interrupt(void)
{	
	if (running)
	{	ask_for_stop=1;
	}	
	else
	{	ask_for_running=1;
	}	
	debounce_select=10; //10*100ms=1s
	IEC1bits.INT2IE = 0; /* disable interrupts, re-enable when debounce=0*/
	IFS1bits.INT2IF = 0; /* clear interrupt flag */
}	

/* Interrupt Service Routine 3: INT0Interrupt       */
/* Save and restore variables var1, var2, etc.      */
/*
void __attribute__((__interrupt__(__save__(variable1,variable2)))) _INT0Interrupt(void)
{

}*/


/********* END OF INTERRUPT SERVICE ROUTINES ********/
