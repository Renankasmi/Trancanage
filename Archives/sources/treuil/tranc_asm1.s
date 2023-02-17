;*****************************************************************************
;                                                                            *
;    NOM               :  lure_asm1                                                   *
;    Date création     :  22/09/2013                                                   *
;    Date modification :                                                     *
;    Version           :   1                                                  *
;    Circuit           :                                                     *
;    Auteur            :                                                     *
;                                                                            *
;	.equ __30F4011, 1
	.include "p30f3010.inc"
;------------------------------------------------------------------------------

	.global _nvm_key_sequ

;*****************************************************************************
;                          PARAMETRES                                        *
;*****************************************************************************

;*****************************************************************************
;                            ACTIONS SELON PARAMETRES                        *
;*****************************************************************************
_nvm_key_sequ:

	DISI #5 ; Block all interrupts with priority <7
	; for next 5 instructions
	MOV #0x55,W0 ;
	MOV W0,NVMKEY ; Write the 0x55 key
	MOV #0xAA,W1 ;
	MOV W1,NVMKEY ; Write the 0xAA key
	BSET NVMCON,#WR ; Initiate erase sequence
	NOP
	NOP
	; Erase cycle will complete in 2mS. CP
	return
	
.end  ; fin du programme
