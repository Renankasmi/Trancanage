;*****************************************************************************
;                                                                            *
;    NOM: regul_def1_wdt_eep
;    Date:  05/05/2014                                                                 *
;    Version:                                                                *
;    Circuit:                                                                *
;    Auteur:                                                                 *
;                                                                            *
;*****************************************************************************
;                                                                            *
;    Fichier requis: P12F675.inc                                             *
;                                                                            *
;                                                                            *
;                                                                            *
;*****************************************************************************
;                                                                            *
;    Notes:  config minimum : osc interne(4MHz) et pas de master clear
;			 modif fréquence , réduction 1/18 environ
;
;*****************************************************************************
	errorlevel -302

	LIST      p=12F675            ; Définition de processeur
	#include <p12F675.inc>        ; fichier include

	__CONFIG   _CP_OFF & _CPD_OFF & _BODEN_ON & _PWRTE_ON & _WDT_ON & _INTRC_OSC_NOCLKOUT & _MCLRE_OFF


;*****************************************************************************
;                               ASSIGNATIONS SYSTEME                         *
;*****************************************************************************

; REGISTRE OPTION_REG (configuration)
; -----------------------------------
OPTIONVAL	EQU	B'00000111'
			; NOT_GPPU b7 : 0= Résistance rappel +5V en service
			; INTEDG   b6 : 1= Interrupt sur flanc montant de gp2/int
			;              -- 0= Interrupt sur flanc descend. de gp2/int
			; TOCS      b5 : 1= source clock = transition sur gp2/t0cki
			;                0= horloge interne
			; TOSE      b4 : 1= Sélection flanc descendant gp2/t0cki(si B5=1)
			;                0= Sélection flanc montant gp2
			; PSA       b3 : 1= Assignation prédiviseur sur Watchdog
			;                --0= Assignation prédiviseur sur Tmr0
			; PS2/PS0   b2/b0 valeur du prédiviseur
            ;           000 =  1/1 (watchdog) ou 1/2 (tmr0)
			;           001 =  1/2               1/4
			;           010 =  1/4		     1/8
			;           011 =  1/8		     1/16  16*256*256=268sec
			;           100 =  1/16		     1/32
			;           101 =  1/32		     1/64
			;           110 =  1/64		     1/128
			;           111 =  1/128	---     1/256


; REGISTRE INTCON (contrôle interruptions standard)
; -------------------------------------------------
INTCONVAL	EQU	B'01110000'
			; GIE       b7 : masque autorisation générale interrupt
                        ;                ne pas mettre ce bit à 1 ici
                        ;                sera mis en temps utile
			; --PEIE      b6 : masque autorisation générale périphériques
			; --T0IE      b5 : masque interruption tmr0
			; --INTE      b4 : masque interuption gp2/Int
			; GPIE      b3 : masque interruption changement d'une des gpio
			; T0IF      b2 : flag tmr0
			; INTF      b1 : flag gp2/Int
			; RBIF      b0 : flag interruption changement d'une des gpio

; REGISTRE PIE1 (contrôle interruptions périphériques)
; ----------------------------------------------------
PIE1VAL		EQU	B'00000001'
			; EEIE      b7 : masque interrupt écriture EEPROM
			; ADIE      b6 : masque interrupt convertisseur A/D
			; ----      b4 : toujours 0 sur 12f629
			; ----      b4 : toujours 0 sur 12f629
			; CMIE      b3 : masque interrupt changement sur sortie comparateur
			; ----      b2 : toujours 0 sur 12f629
			; ----      b2 : toujours 0 sur 12f629
			; --TMR1IE    b0 : masque interrupt débordement tmr1
; REGISTRE ADCON1 (ANALOGIQUE/DIGITAL)
; ------------------------------------
ANSELVAL	EQU	B'00010000' ; an0 , an1, an2 et an3 en mode digital
							; b7 : toujours 0
							; b6..b4 : 001 Fosc/8 , 2µs
							; b3..b0 : 0 si digital I/O
							;          1 si analogique, pour chaque an3..an0

CMCONVAL  EQU B'00000111' ; module comparateur off
							
; DIRECTION DES PORTS I/O
; -----------------------

DIRGPIO	EQU	B'00011110'	; Direction GPIO (1=entrée)
				; note : gp3 toujours en entrée
				;gp0 : sortie buzzer 
				;gp1 : entrée switch poignée
				;gp2 : entrée int 
				;gp4 : entré bp_marche
				;gp5 : sortie shunt bp_plus
				
				
; résistances de tirage pull-up
; -----------------------------

WPUVAL EQU B'00000110' ; 1 : pull_up enabled sur gp2 ( entrée int ) et gp1
					; note : .gp3 est une exception
					;        .pour activer individuellement, il faut activer
					;          globalement (NOT_GPPU=0)

;*****************************************************************************
;                           ASSIGNATIONS PROGRAMME                           *
;*****************************************************************************
#define zero STATUS,Z
#define carry STATUS,C

;*****************************************************************************
;                                  DEFINE                                    *
;*****************************************************************************

#DEFINE buzzer	GPIO,0
#DEFINE handle_idle	GPIO,1
#DEFINE borne_W	GPIO,2 ;interrupt int sur front descendant
#DEFINE bp_plus	GPIO,5		
#DEFINE bp_marche GPIO,4
#DEFINE bp_set_regime GPIO,3

#DEFINE time_out flags,0 ; 
#DEFINE f_buzzer flags,1 ; 

#DEFINE REG_RALENTI_MIN  .5402;.5555 ; 180Hz
#DEFINE REG_RALENTI_MAX  .3241;.3333 ; 300Hz 
;#DEFINE REG_1800         .1784;.1835 ; 545Hz
#DEFINE REG_MAXI         0x600; .1536 ; 651Hz ..633


;*****************************************************************************
;                             MACRO                                          *
;*****************************************************************************

			; Changement de banques
			; ----------------------

BANK0	macro				; passer en banque0
		bcf	STATUS,RP0
	endm

BANK1	macro				; passer en banque1
		bsf	STATUS,RP0
	endm

			; opérations en mémoire eeprom
			; -----------------------------

REEPROM macro				; lire eeprom(adresse & résultat en w)
		clrwdt			; reset watchdog
		bsf	STATUS,RP0	; passer en banque1
		movwf	EEADR		; pointer sur adresse eeprom
		bsf	EECON1,RD	; ordre de lecture
		movf	EEDATA,w	; charger valeur lue
		bcf	STATUS,RP0	; passer en banque0
	endm


WEEPROM	macro	addwrite	; la donnée se trouve dans W
	LOCAL	loop_eep
	bsf	STATUS,RP0	; passer en banque1
	movwf	EEDATA		; placer data dans registre
	movlw	addwrite	; charger adresse d'écriture
	movwf	EEADR		; placer dans registre
	bsf	EECON1 , WREN	; autoriser accès écriture
	bcf	INTCON , GIE	; interdire interruptions
	movlw	0x55		; charger 0x55
	movwf	EECON2		; envoyer commande
	movlw	0xAA		; charger 0xAA
	movwf	EECON2		; envoyer commande
	bsf	EECON1 , WR	; lancer cycle d'écriture
	bsf	INTCON , GIE	; réautoriser interruptions
loop_eep
	btfsc	EECON1 , WR	; tester si écriture terminée
	goto	loop_eep		; non, attendre
	bcf	EECON1 , WREN	; verrouiller prochaine écriture
	bcf	STATUS , RP0	; passer en banque0
	clrwdt			; reset watchdog
	endm



;*****************************************************************************
;                        VARIABLES BANQUE 0                                  *
;*****************************************************************************

; Zone de 64 bytes
; ----------------

	CBLOCK	0x20		; Début de la zone (0x20 à 0x5F)

	w_temp : 1		; Sauvegarde registre W
	status_temp : 1		; sauvegarde registre STATUS
	FSR_temp : 1		; sauvegarde FSR (si indirect en interrupt)
	flags : 1
	periode : 2
	regime ; 0:arrêt,1:ralenti,2:<1800tr/min,3:>1800tr/min
	cmpt_tmr0
	regul_regime : 2
	memo_regime 
	
	;variables de calculs  : 6 octets
	AARGB0 : 1
	AARGB1 : 1
	AARGB2 : 1
	BARGB0 : 1
	BARGB1 : 1
	BARGB2 : 1
			
	;***** Variable de temporisation
	tempo50u : 1		; Variable tempo 50 µs
	tempo10ms : 1		; Variable tempo 10 ms
	tempo1s	: 1		; Variable tempo 1s

        ENDC			; Fin de la zone                        

;*****************************************************************************
;                        VARIABLES BANQUE 1                                  *
;*****************************************************************************

; Zone de 64 bytes
; ----------------

	CBLOCK	0xA0		; Début de la zone (0xA0 à 0xDF)
	w_temp2 : 1		; Sauvegarde registre W
	
	ENDC			; Fin de la zone                        



;*****************************************************************************
;                      DEMARRAGE SUR RESET                                   *
;*****************************************************************************

	org 0x000 		; Adresse de départ après reset
  	goto    init		; Initialiser

; ////////////////////////////////////////////////////////////////////////////

;                         I N T E R R U P T I O N S

; ////////////////////////////////////////////////////////////////////////////

;*****************************************************************************
;                     ROUTINE INTERRUPTION                                   *
;*****************************************************************************
;-----------------------------------------------------------------------------
; Si on n'utilise pas l'adressage indirect dans les interrupts, on se passera
; de sauvegarder FSR
;-----------------------------------------------------------------------------
			;sauvegarder registres	
			;---------------------
	org 0x004		; adresse d'interruption
	movwf   w_temp  	; sauver registre W
	swapf	STATUS,w	; swap status avec résultat dans w
	bcf STATUS,RP0
	movwf	status_temp	; sauver status swappé
;	movf	FSR , w		; charger FSR
;	movwf	FSR_temp	; sauvegarder FSR

	btfsc	INTCON,T0IF	; oui, tester si interrupt timer en cours
	call int_tmr0
	btfsc PIR1,TMR1IF
	call int_tmr1
	btfsc INTCON,INTF 	
	call int_gp2
	
	   		;restaurer registres
			;-------------------
restorereg
;	movf	FSR_temp , w	; charger FSR sauvé
;	movwf	FSR		; restaurer FSR
	swapf	status_temp,w	; swap ancien status, résultat dans w
	movwf   STATUS		; restaurer status
	swapf   w_temp,f	; Inversion L et H de l'ancien W
                       		; sans modifier Z
	swapf   w_temp,w  	; Réinversion de L et H dans W
				; W restauré sans modifier status
	retfie  		; return from interrupt

int_gp2 ; interrupt signal W de l'alternateur
	bcf T1CON,TMR1ON
	movf TMR1H,w
	movwf AARGB0
	movf TMR1L,w
	movwf AARGB1
	bsf T1CON,TMR1ON
	clrf TMR1L
	clrf TMR1H
	btfss time_out
	goto ig1
	movlw 0xFF
	movwf AARGB0
	movwf AARGB1
	
ig1	;moyenne avec la mesure précédente
	movlw high REG_MAXI
	subwf AARGB0,w ;tmr1H-1536 : 651Hz,2171tr/min 
	btfss carry 
	;trop petit , peut-être un glitch
	goto fin_int_gp2
	
	clrf AARGB2 ;poids fort addition
	movf periode+1,w
	addwf AARGB1,f
	movf periode,w
	btfsc STATUS,C
	goto ig2
	addwf AARGB0,f
	btfsc STATUS,C
	incf AARGB2,f
	goto ig3
ig2
	incf periode,w
	btfsc zero
	incf AARGB2,f
	addwf AARGB0,f
ig3
	rrf AARGB2,f
	rrf AARGB0,f
	rrf AARGB1,f
	movf AARGB0,w
	movwf periode
	movf AARGB1,w
	movwf periode+1

	;comparaison par rapport aux seuils
	; entiers non signés
	; on compare les poids forts ,
	; si égaux , on compare ensuite les poids faibles
	clrf BARGB0 ; regime temporaire
	movf AARGB0,w
	sublw high REG_RALENTI_MIN ;seuil-periode
	btfss carry
	goto ig4
	;poids fort > ou =
	btfss zero
	goto $+5
	;il faut comparer les poids faibles
	movf AARGB1,w
	sublw low REG_RALENTI_MIN 
	btfss carry
	goto ig4
	incf BARGB0,f
	
	movf AARGB0,w
	sublw high REG_RALENTI_MAX
	btfss carry
	goto ig4
	;poids fort > ou =
	btfss zero
	goto $+5
	;il faut comparer les poids faibles
	movf AARGB1,w
	sublw low REG_RALENTI_MAX
	btfss carry
	goto ig4
	incf BARGB0,f
	
	movf AARGB0,w
	subwf regul_regime,w;sublw high REG_1800
	btfss carry
	goto ig4
	;poids fort > ou =
	btfss zero
	goto $+5
	;il faut comparer les poids faibles
	movf AARGB1,w
	subwf regul_regime+1,w;sublw low REG_1800
	btfss carry
	goto ig4
	incf BARGB0,f
	
ig4
	movf BARGB0,w
	movwf regime

fin_int_gp2
	bcf time_out	
	bcf INTCON,INTF
	return

int_tmr1 ; débordement timer1 , càd 65ms sans mouvement de l'alternateur 
		; , càd régime < (1/.065)/18*60=51tr/min
	bsf time_out		

	bcf PIR1,TMR1IF
	return
int_tmr0 ; débordement timer0 , càd 256*256µs=65ms 
	;toggle buzzer toutes les 4 interrupt , càd 250ms environ
	; si la poignée est montée ( pin=1) est régime au ralenti (0 ou 1)
	bcf INTCON,T0IF
	movlw .2
	subwf regime,w ; regime-2
	btfss carry ; c=0 si regime-2<0 , càd regime<2 , càd 0 ou 1
	goto toggle_gp0
	;regime>ralenti
buzz_off
	bcf buzzer
	clrf cmpt_tmr0
	return
toggle_gp0
	;arrêté ou au ralenti
	;on vérifie si poignée au repos (=0)
	btfss handle_idle
	goto buzz_off	
	incf cmpt_tmr0,f
	btfss cmpt_tmr0,2 ; ?=4
	return
	clrf cmpt_tmr0
	;toggle buzzer
	btfsc f_buzzer
	goto c_buzzer
	bsf buzzer
	bsf f_buzzer
	return	
c_buzzer
	bcf buzzer
	bcf f_buzzer	
	return	

; ////////////////////////////////////////////////////////////////////////////

;                           P R O G R A M M E

; ////////////////////////////////////////////////////////////////////////////

;*****************************************************************************
;                          INITIALISATIONS                                   *
;*****************************************************************************
init
	
	clrwdt
			; initialisation PORTS (banque 0 et 1)
			; ------------------------------------
	BANK0			; sélectionner banque0
	clrf	GPIO 		; Sorties GPIO à 0
	movlw   CMCONVAL    ; GP0..2 en mode comparateur/digital
	movwf   CMCON		; écriture dans registre comparateur
	bsf	STATUS,RP0	; passer en banque1
	movlw	ANSELVAL	; GPIO en mode digital/analogique
	movwf	ANSEL		; écriture dans contrôle A/D
	movlw	DIRGPIO	    ; Direction GPIO
	movwf	TRISIO		; écriture dans registre direction
	movlw   WPUVAL      ; pull-up des gpio
	movwf   WPU			; écriture dans registre pull-up


			; Registre d'options (banque 1)
			; -----------------------------
	movlw	OPTIONVAL	; charger masque
	movwf	OPTION_REG	; initialiser registre option

			; registres interruptions (banque 1)
			; ----------------------------------
	movlw	INTCONVAL	; charger valeur registre interruption
	movwf	INTCON		; initialiser interruptions
	movlw	PIE1VAL		; Initialiser registre 
	movwf	PIE1		; interruptions périphériques 1
			; calibration de l'oscillateur interne
			;-------------------------------------
	call 0x3FF
	movwf OSCCAL  ; la dernière case mémoire contient la valeur de calibration
			; la remettre après effacement		
			
				
			; Effacer RAM banque 0
			; ---------------------
	bcf	STATUS,RP0	; sélectionner banque 0
	movlw	0x20		; initialisation pointeur
	movwf	FSR		; d'adressage indirect
init1
	clrf	INDF		; effacer ram
	incf	FSR,f		; pointer sur suivant
	btfss	FSR,6		; tester si fin zone atteinte (>5F)
	goto	init1		; non, boucler
	btfss	FSR,5		; tester si fin zone atteinte (>5F)
	goto	init1		; non, boucler
					
	;configuration timer1
	;----------------------------------
	movlw b'00000000' ;tick=1µs*1=1µs
	movwf T1CON ; pas de gate,mode timer, prédiv=1,timer off
	clrf TMR1L
	clrf TMR1H ; compteur mis à 0
	
	movlw 0xFF
	movwf periode
	movwf periode+1
	
	movlw .0
	REEPROM
	movwf regul_regime ; poids fort
	movlw .1
	REEPROM
	movwf regul_regime+1 ; poids faible
	

;	goto	start		; programme principal




;*****************************************************************************
;                      PROGRAMME PRINCIPAL                                   *
;*****************************************************************************

start
	clrwdt
	call Wait1s
	call Wait1s
	;vérification si bp_marche au repos(=0)
s1	clrwdt
	btfsc bp_marche
	goto s1
	;2 beeps pour signaler que le montage est prêt
	bsf buzzer
	call Wait200ms
	bcf buzzer
	call Wait200ms
	bsf buzzer
	call Wait200ms
	bcf buzzer
	
	clrf TMR0
	; autoriser interruptions (banque 0)
	clrf	PIR1		; effacer flags 1
	bcf INTCON,T0IF
	bsf T1CON,TMR1ON
	bsf	INTCON,GIE	; valider interruptions

loop
	clrwdt
	btfsc bp_set_regime
	goto bp_set
	;on vérifie si on est au ralenti
	;regime ; 0:arrêt,1:ralenti,2:<1800tr/min,3:>1800tr/min
	movf regime,w
	sublw .1
	btfss zero
	goto loop
	;on est au ralenti
	;test si appui bp_marche (=1)
l1	clrwdt
	btfss bp_marche
	goto l1
	;on a détecté un appui sur marche
	call Wait100ms
	btfss bp_marche
	goto l1
	call Wait1s
	call Wait1s
	;on shunte le bp_plus pour augmenter le régime
	bsf bp_plus
l2	clrwdt
	;test si régime atteint
	movf regime,w
	sublw .3
	btfsc zero
	goto ok_1800
	movf regime,w
	btfss zero ; si arrêté , on revient au départ
	goto l2
	bcf bp_plus
	goto loop
ok_1800
	bcf bp_plus ; on relâche le bp_plus
	call Wait1s
	call Wait1s

	goto loop	
	
bp_set
	;on a détecté un appui sur set
	call Wait100ms
	btfss bp_set_regime
	goto loop
	call Wait1s
	call Wait1s
	btfss bp_set_regime
	goto loop
	;appui pendant plus de 2s
	;2 beeps
	bsf buzzer
	call Wait200ms
	call Wait200ms
	bcf buzzer
	call Wait200ms
	call Wait200ms
	bsf buzzer
	call Wait200ms
	call Wait200ms
	bcf buzzer
	;on mémorise le régime
	bcf	INTCON,GIE	; couper interruptions
	movf periode+1,w
	movwf memo_regime
	movf periode,w
	bsf	INTCON,GIE	; valider interruptions
	movwf regul_regime ; poids fort
	WEEPROM .0
	movf memo_regime,w
	movwf regul_regime+1 ; poids faible
	WEEPROM .1
	call Wait1s
	call Wait1s
	;3 beeps
	bsf buzzer
	call Wait200ms
	call Wait200ms
	bcf buzzer
	call Wait200ms
	call Wait200ms
	bsf buzzer
	call Wait200ms
	call Wait200ms
	bcf buzzer
	call Wait200ms
	call Wait200ms
	bsf buzzer
	call Wait200ms
	call Wait200ms
	bcf buzzer
	call Wait1s
	call Wait1s
	call Wait1s
	goto loop
	
	
;**************************************
;*  sous programme calcul 16+16=16
;*  AARGB+BARGB->BARGB  , 0:MSB , 1:LSB
;**************************************
Add16
	movf AARGB1,w
	addwf BARGB1,f
	movf AARGB0,w
	btfsc STATUS,C
	incfsz AARGB0,w
	addwf BARGB0,f
	return	
;
;**************************************
;*  sous programme calcul 16-16=16
;*  BARGB-AARGB->BARGB  , 0:MSB , 1:LSB
;**************************************
Sub16
	movf AARGB1,w
	subwf BARGB1,f
	movf AARGB0,w
	btfss STATUS,C
	incfsz AARGB0,w
	subwf BARGB0,f
	return	


;**********************************************************************
;                                                                     *
;    Les pauses a 4Mhz			                  	      *
;                                                                     *
;                                                                     *
;**********************************************************************


;***** Attente de 1 s (1.33s)
Wait1s
		MOVLW	D'99'		;	99 fois
		MOVWF	tempo1s		; stockage dans la variable tempo1s
T1sboucle	CALL	Wait10ms
		DECFSZ	tempo1s,1	; décremente et test
		GOTO	T1sboucle	; on boucle tant que <>0  
		RETURN
;***** Attente de 200ms 
Wait200ms
		MOVLW	D'20'		;	99 fois
		MOVWF	tempo1s		; stockage dans la variable tempo1s
T200msboucle	CALL	Wait10ms
		DECFSZ	tempo1s,1	; décremente et test
		GOTO	T200msboucle	; on boucle tant que <>0  
		RETURN
;***** Attente de 100ms 
Wait100ms
		MOVLW	D'10'		;	99 fois
		MOVWF	tempo1s		; stockage dans la variable tempo1s
T100msboucle	CALL	Wait10ms
		DECFSZ	tempo1s,1	; décremente et test
		GOTO	T100msboucle	; on boucle tant que <>0  
		RETURN

;***** Attente de 500ms 
Wait500ms
		MOVLW	D'50'		;	99 fois
		MOVWF	tempo1s		; stockage dans la variable tempo1s
T500msboucle	CALL	Wait10ms
		DECFSZ	tempo1s,1	; décremente et test
		GOTO	T500msboucle	; on boucle tant que <>0  
		RETURN

;***** Attente de 15 ms (exactement 14.99 ms)
Wait15ms
		MOVLW	D'149'		;	149 fois
		MOVWF	tempo10ms	; stockage dans la variable tempo10ms
T15msboucle	CALL	Wait100us
		DECFSZ	tempo10ms,1	; décremente et test
		GOTO	T15msboucle	; on boucle tant que <>0
		RETURN


;***** Attente de 10 ms (exactement 10.02 ms)
Wait10ms
		clrwdt
		MOVLW	D'198'		;	198 fois
		MOVWF	tempo10ms	; stockage dans la variable tempo10ms
T10msboucle	CALL	Wait50us
		
		DECFSZ	tempo10ms,1	; décremente et test
		GOTO	T10msboucle	; on boucle tant que <>0
		RETURN

;***** Attente de 1.5 ms (exactement ? ms)
Wait1.5ms
		MOVLW	D'29'		;	29 fois
		MOVWF	tempo10ms	; stockage dans la variable tempo10ms
T1.5msboucle	CALL	Wait50us
		DECFSZ	tempo10ms,1	; décremente et test
		GOTO	T1.5msboucle	; on boucle tant que <>0
		RETURN

;***** Attente de 100 us 
Wait100us	
		clrwdt
		MOVLW	D'31'		;	31 fois
		MOVWF	tempo50u	; stockage dans la variable tempo50u
T100usboucle	DECFSZ	tempo50u,1	; décremente et test
		GOTO	T100usboucle	; on boucle tant que <>0  1*3=3 µs en tout
		RETURN


;***** Attente de 50 µs 
Wait50us	
		nop
		clrwdt
		MOVLW	D'14'		;	14 fois
		MOVWF	tempo50u	; stockage dans la variable tempo50µ
T50usboucle	DECFSZ	tempo50u,1	; décremente et test
		GOTO	T50usboucle	; on boucle tant que <>0  1*3=3 µs en tout
		RETURN

;***** Attente de 5 µs 
Wait5us	clrwdt
		RETURN


	END 			; directive fin de programme

