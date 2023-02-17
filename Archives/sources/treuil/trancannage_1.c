/*
  .L6234 piloté en 1/2 pont
  .lecture aeat-6600 via spi 3 fils
  .configure rd0 en sortie ( led )
  .config timer1 , prediv=256 
  .interrupt timer1(100ms) : toggle led 
  .usart,38400bds,alternate pins	
Tosc=7.37MHz*16
*/

#include <p30f3010.h>
//#include "Math.h"
#include "GenericTypeDefs.h"

/* Define constants here                            */
#define led 	LATCbits.LATC15 
/*#define AS_NOT_CS 	LATBbits.LATB2 
#define AS_PROG 	LATBbits.LATB1 
#define AS_SCK		LATEbits.LATE8 //pour la programmation
#define AS_DIR		PORTBbits.RB3
*/

#define do_loop flags.bits.b0

/*FREQUENCY SYSTEM DEFINES*/
#define FCY  29491200			//FRC w/PLL x16
#define MILLISEC FCY/29491		//1 mSec delay constant
#define FPWM 20000				//20KHz PWM Freq
#define MAX_DUTY_CYCLE 1469  	// 100% duty cycle PDC1=PDC2=PDC3 = 1469

#define FLANC_MONTANT 0x03
#define FLANC_DESCENDANT 0x02
#define FLANC_MONTANT_DESCENDANT 0x01


typedef union
{
  float fvalue;
  unsigned char ivalue[4];
} __ieee_float;
typedef struct
{	unsigned int version;
	WORD_VAL flags;//b0,b1:FS_SEL mpu6050(0:250°/s,1:500,2:1000,3:2000)
	               //b2:reverse roll,b3:reverse tilt
	               //b4=1: I2C , disable slew rate control
	               //b5=0:pos_as_roulis augmente quand roll à droite
	               //b5=1:pos_as_roulis augmente quand roll à gauche(càd inversé)
	               //b6=0:pos_as_tangage augmente quand tangage à cabré
	               //b6=1:pos_as_tangage augmente quand tangage à piqué(càd inversé)
	               //b7=0:filtre_complémentaire / b7=1:madgwick
	               //b8:reverse yaw
	               //b9=0:pos_as_yaw augmente quand yaw à droite
	               //b9=1:pos_as_yaw augmente quand yaw à gauche(càd inversé)
	                   
	unsigned int can_pwm_roulis;
	unsigned int can_pwm_tangage;
	unsigned int can_as5040_roulis;
	unsigned int can_as5040_tangage;
	unsigned int can_pwm_yaw;
	unsigned int can_as5040_yaw;
	unsigned int i2c_baudrate;
	unsigned int angle_svm;
	unsigned int volts_svm;
	unsigned int freq_boucle;
	unsigned int frottement_sec;
	unsigned int sensor_set;
	unsigned int attrib_set;
	unsigned int attrib_voie1;
	unsigned int attrib_voie2;
	int delta_x;
	int delta_y;
	unsigned int zero_y;
	unsigned int gyro_scale[4];
	int OFFSET_ACC_X;
	int OFFSET_ACC_Y;
	int OFFSET_ACC_Z;
	int SCALE_ACC_X;
	int SCALE_ACC_Y;
	int SCALE_ACC_Z;
	unsigned int zero_t;
	unsigned int zero_r;
	
	 //int d'abord , float après
	float Kp_tilt;
	float Ki_tilt;
	float Kd_tilt;
	float Kp_roll;
	float Ki_roll;
	float Kd_roll;
	float Xacc;//filtre accéléros 1er ordre
	float Xtilt;//filtre commande 
	float Xroll;
	float Kp_imu;
	float Ki_imu;
	float limH_t;
	float limL_t;
	float limH_r;
	float limL_r;
	float Xyaw;
	float Kp_yaw;
	float Ki_yaw;
	float Kd_yaw;
	
} CONFIG_EEP;

#define OFFSET_FIRST_FLOAT 32 //index config.words du premier mot en float(lsw)

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
volatile unsigned long periode_bobine=0;
unsigned int pos_as5040=0;
volatile BUFFER_EEP config; //config.eepr.Kp_tilt
	
unsigned char dat_transmit[28];
volatile unsigned char tx_cmpt=0;
volatile unsigned char index_tx;


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
unsigned int lire_eep_int(unsigned int offset);
void init_IC_bobine(void);
void init_IC2(unsigned int flanc,unsigned int int_enable);
void init_tmr3(void);
void InitADC10(void);

/************* START OF MAIN FUNCTION ***************/

int main ( void )  
{	unsigned char i=0;
	unsigned int j=0;
//	unsigned int temp_spi;	
	unsigned int temp_tx;	
	unsigned long temp_tx_l;	
	unsigned int temp_pdc;
	
	flags.Val = 0;

	SRbits.IPL = 7; // off
	init_IO();
	init_usart();

	while (usart_rec()!='G');
    usart_emi('G');
	usart_emi('O');

	init_tmr1();
	
	for (i=0;i<20;i++)
	{	__asm__ volatile ("BTG LATC,#15"); 
		delay100ms();
	}

 	init_tmr3(); //input capture timebase
	init_IC_bobine(); //sur ic7(#6)
	
	InitMCPWM();					//Configuring MC PWM module
 	
  	init_spi();
	InitADC10();

	PWMCON1 = 0x0777;				// enable PWM outputs
	OVDCON=0x2A00;//pwm on pwm1,pwm3,pwm5(in l6234)
				  //pwm0,pwm2,pwm4 overrride inactive(=high)(en l6234)

 
	config.eepr.volts_svm=20;
 			
	SRbits.IPL = 0;
	while (1)
	{		
		while (!do_loop);
		do_loop=0;
		__asm__ volatile ("BTG LATC,#15"); 
	
		temp_pdc=adc_result;
		PWMCON2bits.UDIS = 1;
		PDC1=PDC2=PDC3=temp_pdc;
		PWMCON2bits.UDIS = 0;
	
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
		temp_tx=temp_pdc;//config.eepr.volts_svm;
		dat_transmit[j++]=temp_tx >> 8;
		dat_transmit[j++]=temp_tx & 0xFF;
		temp_tx=pos_as5040>>6;
		dat_transmit[j++]=temp_tx >> 8;
		dat_transmit[j++]=temp_tx & 0xFF;
		tx_cmpt=j; //càd le nombre de 'dat_transmit'
		index_tx=0; //index tableau dat_transmit
		IFS0bits.U1TXIF = 0;
		IEC0bits.U1TXIE = 1; //enable transmit interrupt  		   	
	}

}
void init_tmr1(void)
{
	T1CON = 0;
	TMR1 = 0; /* clear timer1 register */
	PR1 = 0x2CFC; /* set period1 register=.1 s */
	//PR1 = 0xE0EA; /* set period1 register=.5 s */
	T1CON = 0x8030; /* Get Timer1 settings (1:256 prescaler) */
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
	
	ADCON1 = 0x0004;    //ADC is off
						//Continue module operation in Idle mode
						//10-bit, 4-channel ADC operation
						//Data Output Format bits Integer (0000 00dd dddd dddd)
						//000 = clearing samp end sampling and start conv
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
							// MAX_DUTY_CYCLE = 1469
							// 50% duty cycle = 734
	PTCONbits.PTMOD = 2;	// Center Aligned with X interruption
	PWMCON1 = 0x0700;		// disable PWMs
	OVDCON = 0x0000;		// allow control using OVD
    PDC1 = 200;	    // Initialize as 0 voltage
	PDC2 = 734;	    // Initialize as 0 voltage
	PDC3 = 1000;	    // Initialize as 0 voltage
	PWMCON2 = 0x0004;		// 1:1 postscale values,immediate pdc updates
	PTCONbits.PTEN = 1;
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


		
/****** START OF INTERRUPT SERVICE ROUTINES *********/

/* Replace the interrupt function names with the    */
/* appropriate names depending on interrupt source. */

/* The names of various interrupt functions for     */
/* each device are defined in the linker script.    */


/* Interrupt Service Routine 1                      */
/* No fast context save, and no variables stacked   */


/* Interrupt Service Routine 2                      */
/* Fast context save (using push.s and pop.s)       */

void __attribute__((__interrupt__, __shadow__,no_auto_psv)) _T1Interrupt(void)
{	
	//static int sticks=0;
	ADCON1bits.SAMP = 0 ; // start Converting
	SPI1BUF=0;//dummy
	do_loop=1;
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
	
	ADCON1bits.DONE = 0;
	IFS0bits.ADIF = 0;

}
void __attribute__((__interrupt__,no_auto_psv)) _U1RXInterrupt(void)
{ 	static int memo_adr_var;
	int temp_read;
	
	if (U1STAbits.URXISEL==0) //on a reçu une nouvelle commande,sur 1 octet
	{	rx_command=U1RXREG;			
		if (rx_command & 0x80)
		{	memo_adr_var=rx_command & 0x7F; //offset dans config.words[x]
			rx_command=0;
			U1STAbits.URXISEL=3; //interrupt flag set when 4 datas have been received								
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
}	

/* Interrupt Service Routine 3: INT0Interrupt       */
/* Save and restore variables var1, var2, etc.      */
/*
void __attribute__((__interrupt__(__save__(variable1,variable2)))) _INT0Interrupt(void)
{

}*/


/********* END OF INTERRUPT SERVICE ROUTINES ********/
