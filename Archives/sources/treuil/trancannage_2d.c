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
       
*/

#include <p30f3010.h>
#include "Math.h"
#include "GenericTypeDefs.h"

/* Define constants here                            */
#define led 	LATCbits.LATC15 
/*#define AS_NOT_CS 	LATBbits.LATB2 
#define AS_PROG 	LATBbits.LATB1 
#define AS_SCK		LATEbits.LATE8 //pour la programmation
#define AS_DIR		PORTBbits.RB3
*/
#define VERSION 2

#define	COMMAND_VISU_DATA_1 1
#define COMMAND_STORE_OFFS 2
#define COMMAND_WRITE_EEP 3
#define COMMAND_RESET 4
#define COMMAND_CHANGE_FREQ_BOUCLE 5
#define	COMMAND_VISU_DATA_2 6
#define COMMAND_BASCULE_IC_BOBINE 48

#define do_loop flags.bits.b0
#define first_read flags.bits.b1
#define saturH flags.bits.b2
#define saturL flags.bits.b3

/*FREQUENCY SYSTEM DEFINES*/
#define FCY  29491200			//FRC w/PLL x16
#define MILLISEC FCY/29491		//1 mSec delay constant
#define FPWM 20000				//20KHz PWM Freq

#define FLANC_MONTANT 0x03
#define FLANC_DESCENDANT 0x02
#define FLANC_MONTANT_DESCENDANT 0x01

#define NB_CIRC_H 20

typedef union
{
  float fvalue;
  unsigned char ivalue[4];
} __ieee_float;
typedef struct
{	unsigned int version;
	WORD_VAL flags;//b0,b1
	               //b2:
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

 
/************* START OF GLOBAL DEFINITIONS **********/
volatile WORD_VAL flags;
volatile unsigned char rx_command=0;
volatile unsigned int adc_result=0;
volatile unsigned int pos_bobine=0;
volatile unsigned int cmpt_tmr3=0;
volatile unsigned long periode_bobine=0xFFFFFFFF;
unsigned int pos_as5040=0;
volatile BUFFER_EEP config; 
volatile unsigned char cmpt_nvm=0;
volatile float consigne=0;
volatile float next_consigne=0;
volatile float incr_loop=0;
volatile unsigned int cmpt_incr=0;
	
unsigned char dat_transmit[28];
volatile unsigned char tx_cmpt=0;
volatile unsigned char index_tx;

unsigned int data_out=0;
unsigned char cmpt_visu=0;
float Ep0;
float Epu;
float sum_erreur=0;



/************** END OF GLOBAL DEFINITIONS ***********/


void init_tmr1(void);
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
void InitMCPWM(void);
void lecture_config(unsigned int nb_words,int envoi);
void eeprom_load_defaults(unsigned int nb_words);
unsigned int lire_eep_int(unsigned int offset);
void init_IC_bobine(void);
void init_IC2(unsigned int flanc,unsigned int int_enable);
void init_tmr3(void);
void InitADC10(void);
extern void nvm_key_sequ(void);
void calc_incr_consigne(void);

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
	#endif
	#if debug==0
		init_usart();
	//test si eeprom corrompue , ou changement version
		//on lit le 1er emplacement = version
		if (lire_eep_int(0)!=VERSION) eeprom_load_defaults(sizeof(config.eepr)>>1);	
		while (usart_rec()!='G');
    	usart_emi('G');
		usart_emi('O');
		lecture_config(sizeof(config.eepr)>>1,1); //sizeof:bytes,  /2->words
		for (i=0;i<20;i++)
		{	__asm__ volatile ("BTG LATC,#15"); 
			delay100ms();
		}
		
		
	#endif
	
 	init_tmr1();
	init_tmr3(); //input capture timebase
	init_IC_bobine(); //sur ic7(#6)
	
	InitMCPWM();					//Configuring MC PWM module
 	
  	init_spi();
	InitADC10();

	PWMCON1 = 0x0777;				// enable PWM outputs
	OVDCON=0x2A00;//pwm on pwm1,pwm3,pwm5(in l6234)
				  //pwm0,pwm2,pwm4 overrride inactive(=high)(en l6234)

 
	SRbits.IPL = 0;
	#if debug==0
	while (!do_loop);
	do_loop=0;
	#endif	
	next_consigne=pos_as5040-config.eepr.offset_as5040;	
	calc_incr_consigne();
	next_consigne=pos_as5040-config.eepr.offset_as5040;	
	cmpt_incr=0;	
	
	while (1)
	{		
	#if debug==0
		while (!do_loop);
		do_loop=0;
	#endif		
		
		if (cmpt_incr)
		{	consigne-=incr_loop;
			cmpt_incr--;
			if (consigne<0) consigne+=65536.0;
		}
			
		//calcul erreur Ep0
		//erreur=consigne-state
		//ici , inversé car consigne et state diminuent
		Ep0=(float)(pos_as5040-config.eepr.offset_as5040)-consigne;
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
		{ 	if (Epu>1469.0)
			{	temp_pdc=1469;
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
		{	PWMCON2bits.UDIS = 1;
			PDC1=PDC2=PDC3=temp_pdc;
			PWMCON2bits.UDIS = 0;
			SEVTCMPbits.SEVTCMP=temp_pdc>>2;
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
			else __asm__ volatile ("BTG LATC,#15"); 
			cmpt_visu=0;
	
			if (config.eepr.volts_manuel)
			{	PWMCON2bits.UDIS = 1;
				PDC1=PDC2=PDC3=config.eepr.volts_manuel;
				PWMCON2bits.UDIS = 0;
				SEVTCMPbits.SEVTCMP=config.eepr.volts_manuel>>2;
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
					temp_tx=adc_result;//config.eepr.volts_svm;
					dat_transmit[j++]=temp_tx >> 8;
					dat_transmit[j++]=temp_tx & 0xFF;
					temp_tx=(pos_as5040-config.eepr.offset_as5040)>>6;//pos_as5040>>6;
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
					temp_tx=((unsigned int)consigne)>>6;
					dat_transmit[j++]=temp_tx >> 8;
					dat_transmit[j++]=temp_tx & 0xFF;
					temp_tx=(pos_as5040-config.eepr.offset_as5040)>>6;//pos_as5040>>6;
					dat_transmit[j++]=temp_tx >> 8;
					dat_transmit[j++]=temp_tx & 0xFF;
				break;	
			}	
			tx_cmpt=j; //càd le nombre de 'dat_transmit'
			index_tx=0; //index tableau dat_transmit
			IFS0bits.U1TXIF = 0;
			IEC0bits.U1TXIE = 1; //enable transmit interrupt  		  
		}
	}

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
void init_usart(void)
{	U1BRG = 94 ;// Set Baudrate , 19200bds
	//U1BRG = 47 ;// Set Baudrate , 38400bds
	U1STA = 0 ;
	U1MODE = 0x8400 ; /* ; Enable UART for 8-bit data,
				     	; no parity, 1 STOP bit,
				    	; no wakeup
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
	LATC = 0;
	TRISCbits.TRISC15 = 0; // ;Set LED pin as output
	//LATCbits.LATC15 = 1; //Turn LED on
//	ADPCFG=0x03F; //rb5..rb0 en digital
//	TRISBbits.TRISB1=0; //AS_PROG en sortie
//	TRISBbits.TRISB2=0; //AS_NOT_CS en sortie
	
}
void InitADC10(void)
{
	ADPCFG = 0xFFFE;	//Port pin multiplexed with AN0 in Analog mode
	
	ADCON1 = 0x0064;    //ADC is off
						//Continue module operation in Idle mode
						//10-bit, 4-channel ADC operation
						//Data Output Format bits Integer (0000 00dd dddd dddd)
						//011 = Motor Control PWM interval ends sampling and starts conversion
						//Samples in sequence
                        //Sampling begins immediately after last conversion SAMP bit is auto-set.

	ADCHS = 0x0000;    //MUX B pas utilisé
				//MUX A ch0 negative input is VREF-
				//MUX A ch0 positive input is an0
				
	ADCSSL = 0x0000;	//Skip all ANx channels for input scan

	ADCON3 = 0x0004;	//ADC Clock derived from system clock
						//Autosample time time bits = 0 TAD since PWM is controlling sampling time
						//TAD = 3*TCY, TAD = 101.7 nSec
						//TAD = (5/2)*TCY, TAD = 84.77 nSec

	ADCON2 = 0x0000;	//ADREF+ = AVDD ADREF- = AVSS
						//Do not scan inputs
						//00 = Converts CH0
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
{  	TRISD = 0x000e; // ;Set cs_pin as output
	LATDbits.LATD0 = 1; //Turn mcp4921 off
	//aeat-6600 cs mis à la masse en hardware
	//mode master
	SPI1CON=0x0E79;//mode16,cke=0,ckp=1,smp=1,ssen=0,master,937kHz
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

/******************************************************************************
* Function:     InitMCPWM(void)
*
* Output:		None
*
* Overview:		Initializes the PWM module to operate in center-aligned mode
*				at 20KHz. PWM terminals are configured in independent mode.
*				PWM time base is 67.8 nSec.
*				PDCx value range is 0-1464 for 0%-100% duty cycle 
*				ADC reload time is variable according to the PWM duty cycle
*
*
* Note:			None
*******************************************************************************/
void InitMCPWM(void)
{
	PTPER = ((FCY/FPWM)/2 - 1);
							//FCY  29491200...FRC w/PLL x16
							//FPWM 20KHz PWM Freq
							// MAX_DUTY_CYCLE = 736
							// 50% duty cycle = 368
	PTCON=0;
	PTCONbits.PTMOD = 2;	// Center Aligned with X interruption
	PWMCON1 = 0x0700;		// disable PWMs
	OVDCON = 0x0000;		// allow control using OVD
   	SEVTCMPbits.SEVTDIR = 0; 	// trgger ADC when PWM counter is in upwards dir
	SEVTCMPbits.SEVTCMP = 0;	// generates a trigger event for the ADC
								// when PWM time base is counting upwards
								// just before reaching the PTPER value
								// causing a sampling in the middle of the 
								// pulse
    PDC1 = 0;	    // Initialize as 0 voltage
	PDC2 = 0;	    // Initialize as 0 voltage
	PDC3 = 0;	    // Initialize as 0 voltage
	PWMCON2 = 0x0F04;		// 1:16 postscale values,immediate pdc updates
	PTCONbits.PTEN = 1;
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
	config.eepr.flags.Val=0;
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
	float temp_float3;
	
	consigne=next_consigne;
	//temp_int=pos_as5040-config.eepr.offset_as5040;
	temp_float1=(32.0*(float)periode_bobine)/PR1;
	cmpt_incr=(unsigned int)temp_float1;
	//test sur cosf(consigne/10430.37835)+(2.0*config.eepr.pas/config.eepr.largeur_bobine)
	// si >1 , on a passé 0° , on revient vers 270°
	//si <-1 , on a passé 180° , on revient vers 90°
	if (consigne>32767.0) //càd <0
	{	temp_float3=cosf(consigne/10430.37835)-(2.0*config.eepr.pas/config.eepr.largeur_bobine);
		if (temp_float3<-1.0)
		{	temp_float3=-2.0-temp_float3;
			next_consigne=10430.37835*acosf(temp_float3);
		}
		else
		{	next_consigne=65536.0-10430.37835*acosf(temp_float3);
		}
		incr_loop=(consigne-next_consigne)/temp_float1;
	}	
	else //càd >0
	{	temp_float3=cosf(consigne/10430.37835)+(2.0*config.eepr.pas/config.eepr.largeur_bobine);
		if (temp_float3>1.0) 
		{	temp_float3=2.0-temp_float3;
			next_consigne=65536.0-10430.37835*acosf(temp_float3);
			incr_loop=(65536.0+consigne-next_consigne)/temp_float1;
		}
		else
		{	next_consigne=10430.37835*acosf(temp_float3);
			incr_loop=(consigne-next_consigne)/temp_float1;
		}
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
	
	adc_result = ADCBUF0;	//ADC CH0 holds the POT value
	
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

/* Interrupt Service Routine 3: INT0Interrupt       */
/* Save and restore variables var1, var2, etc.      */
/*
void __attribute__((__interrupt__(__save__(variable1,variable2)))) _INT0Interrupt(void)
{

}*/


/********* END OF INTERRUPT SERVICE ROUTINES ********/
