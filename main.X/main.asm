; TODO INSERT INCLUDE CODE HERE
#include "p18f25k40.inc"

    
; TODO INSERT CONFIG HERE
; CONFIG1L
  CONFIG  FEXTOSC = ECH         ; External Oscillator mode Selection bits (EC (external clock) above 8 MHz; PFM set to high power)
  CONFIG  RSTOSC = EXTOSC       ; Power-up default value for COSC bits (EXTOSC operating per FEXTOSC bits (device manufacturing default))

; CONFIG1H
  CONFIG  CLKOUTEN = ON         ; Clock Out Enable bit (CLKOUT function is enabled)
  CONFIG  CSWEN = ON            ; Clock Switch Enable bit (Writing to NOSC and NDIV is allowed)
  CONFIG  FCMEN = ON            ; Fail-Safe Clock Monitor Enable bit (Fail-Safe Clock Monitor enabled)

; CONFIG2L
  CONFIG  MCLRE = EXTMCLR       ; Master Clear Enable bit (If LVP = 0, MCLR pin is MCLR; If LVP = 1, RE3 pin function is MCLR )
  CONFIG  PWRTE = OFF           ; Power-up Timer Enable bit (Power up timer disabled)
  CONFIG  LPBOREN = OFF         ; Low-power BOR enable bit (ULPBOR disabled)
  CONFIG  BOREN = SBORDIS       ; Brown-out Reset Enable bits (Brown-out Reset enabled , SBOREN bit is ignored)

; CONFIG2H
  CONFIG  BORV = VBOR_2P45      ; Brown Out Reset Voltage selection bits (Brown-out Reset Voltage (VBOR) set to 2.45V)
  CONFIG  ZCD = OFF             ; ZCD Disable bit (ZCD disabled. ZCD can be enabled by setting the ZCDSEN bit of ZCDCON)
  CONFIG  PPS1WAY = ON          ; PPSLOCK bit One-Way Set Enable bit (PPSLOCK bit can be cleared and set only once; PPS registers remain locked after one clear/set cycle)
  CONFIG  STVREN = ON           ; Stack Full/Underflow Reset Enable bit (Stack full/underflow will cause Reset)
  CONFIG  DEBUG = OFF           ; Debugger Enable bit (Background debugger disabled)
  CONFIG  XINST = OFF           ; Extended Instruction Set Enable bit (Extended Instruction Set and Indexed Addressing Mode disabled)

; CONFIG3L
  CONFIG  WDTCPS = WDTCPS_31    ; WDT Period Select bits (Divider ratio 1:65536; software control of WDTPS)
  CONFIG  WDTE = OFF            ; WDT operating mode (WDT Disabled)

; CONFIG3H
  CONFIG  WDTCWS = WDTCWS_7     ; WDT Window Select bits (window always open (100%); software control; keyed access not required)
  CONFIG  WDTCCS = SC           ; WDT input clock selector (Software Control)

; CONFIG4L
  CONFIG  WRT0 = OFF            ; Write Protection Block 0 (Block 0 (000800-001FFFh) not write-protected)
  CONFIG  WRT1 = OFF            ; Write Protection Block 1 (Block 1 (002000-003FFFh) not write-protected)
  CONFIG  WRT2 = OFF            ; Write Protection Block 2 (Block 2 (004000-005FFFh) not write-protected)
  CONFIG  WRT3 = OFF            ; Write Protection Block 3 (Block 3 (006000-007FFFh) not write-protected)

; CONFIG4H
  CONFIG  WRTC = OFF            ; Configuration Register Write Protection bit (Configuration registers (300000-30000Bh) not write-protected)
  CONFIG  WRTB = OFF            ; Boot Block Write Protection bit (Boot Block (000000-0007FFh) not write-protected)
  CONFIG  WRTD = OFF            ; Data EEPROM Write Protection bit (Data EEPROM not write-protected)
  CONFIG  SCANE = ON            ; Scanner Enable bit (Scanner module is available for use, SCANMD bit can control the module)
  CONFIG  LVP = OFF             ; Low Voltage Programming Enable bit (HV on MCLR/VPP must be used for programming)

; CONFIG5L
  CONFIG  CP = OFF              ; UserNVM Program Memory Code Protection bit (UserNVM code protection disabled)
  CONFIG  CPD = OFF             ; DataNVM Memory Code Protection bit (DataNVM code protection disabled)

; CONFIG5H

; CONFIG6L
  CONFIG  EBTR0 = OFF           ; Table Read Protection Block 0 (Block 0 (000800-001FFFh) not protected from table reads executed in other blocks)
  CONFIG  EBTR1 = OFF           ; Table Read Protection Block 1 (Block 1 (002000-003FFFh) not protected from table reads executed in other blocks)
  CONFIG  EBTR2 = OFF           ; Table Read Protection Block 2 (Block 2 (004000-005FFFh) not protected from table reads executed in other blocks)
  CONFIG  EBTR3 = OFF           ; Table Read Protection Block 3 (Block 3 (006000-007FFFh) not protected from table reads executed in other blocks)

; CONFIG6H
  CONFIG  EBTRB = OFF           ; Boot Block Table Read Protection bit (Boot Block (000000-0007FFh) not protected from table reads executed in other blocks)
    


; TODO PLACE VARIABLE DEFINITIONS GO HERE
GPR_VAR	        UDATA      0x100
; global
etat_jeu        RES        1	
seed            RES        1
bouton_presse   RES        1 
level           RES        1
; autre   
TEMP_BSR        RES        1
WREG2           RES        1
compteur_suite  RES        1
; compteur_routine_tempo
compteur0	RES        1
compteur1	RES        1
compteur2	RES        1

	       

; RESET VECTOR
RES_VECT  CODE    0x0000            ; processor reset vector
   GOTO    START1                   ; go to beginning of program

   
   
;*******************************************************************************
; INTERRUPTION
;*******************************************************************************
ISRLV     CODE     0x0008
    CALL PUSH_BSR
    ; ON REGARDE DANS QUEL ETAT DE JEU ON EST
    MOVLB 0x01	   ; BSR -> 0x01
    MOVLW 0x0
    CPFSEQ etat_jeu, 1	; si c'est egal a 0, on skip
    GOTO ETAT_JEU_1   ; 
    GOTO ETAT_JEU_0
    
    ; -------------------- IF ETAT_JEU == 0 (MENU) -------------------- 
    ETAT_JEU_0:
    
    CALL GENERATION_SEED_ET_COULEURS

    MOVLW 0x01
    MOVWF etat_jeu, 1	; on change l'etat du jeu
    
    CALL PLAY_ALLUMAGE
    CALL PLAY_ALLUMAGE
    CALL MULTICOULEUR_TOUTES_RGB_1
    CALL ATTENDRE_1s
    CALL ETEINDRE_TOUTES_RGB
    CALL ETEINDRE_BUZZER
    
    CALL ATTENDRE_1s
    CALL JOUER_PROCHAINE_SEQUENCE
    GOTO QUITTER_ISR
    
    
    ; -------------------- IF ETAT_JEU == 1 (GAME) -------------------- 
    ETAT_JEU_1:
    ;remettre a 4 bouton_presse
    MOVLB 0x01	; BSR = 0x01
    MOVLW 0x04
    MOVWF bouton_presse, 1
    
    ; ----- ON MET LE NUMERO DE LA LED PRESSE DANS bouton_presse -----
    MOVLB 0xE	; BSR = 0x0E
    BTFSS PIR0,0,1  ;skip si le bit=1
    goto suite11
    MOVLB 0x01
    MOVLW 0x00
    MOVWF bouton_presse,1
    
    suite11:
    BTFSS PIR0,1,1  ;skip si le bit=1
    goto suite12
    MOVLB 0x01
    MOVLW 0x01
    MOVWF bouton_presse,1
    
    suite12:
    BTFSS PIR0,2,1  ;skip si le bit=1
    goto suite13
    MOVLB 0x01
    MOVLW 0x02
    MOVWF bouton_presse,1
    
    suite13:
    MOVLB 0xF
    BTFSS IOCBF,3,1  ;skip si le bit=1
    goto suite14
    MOVLB 0x01
    MOVLW 0x03
    MOVWF bouton_presse,1
    
    
    ; ----- ON ALLUME LA RGB ET SON BUZZER ASSOCIE -----
    suite14:    ; on met a jour les rgb
    
    CALL PLAY_RGB_ET_BUZZER
    
    
    ; ----- VERIFICATION DE LA SUITE RGB -----
    MOVLB 0x01
    MOVF POSTINC0,0
    CPFSEQ bouton_presse,1
    GOTO FAIRE_GAMEOVER
    
    MOVF FSR0L, 0
    CPFSEQ level,1
    GOTO QUITTER_ISR
    GOTO fin_level
    
    
    FAIRE_GAMEOVER:
    CALL GAME_OVER
    GOTO QUITTER_ISR
    
    fin_level:
    CALL ATTENDRE_01s
    CALL PLAY_VERT_TOUTES_RGB
    INCF level,1,1
    CLRF FSR0L	; remet a 0 fsrol	
    ; JOUER LA PROHAINE SEQUENCE
    CALL ATTENDRE_06s
    CALL JOUER_PROCHAINE_SEQUENCE
    
     ; ----- QUITTER ISR -----
    QUITTER_ISR:
    ; CLEAR les flags 
    MOVLB 0xE
    BCF PIR0, 0, 1  
    BCF PIR0, 1, 1
    BCF PIR0, 2, 1
    MOVLB 0xF
    CLRF IOCBF, 1
    CALL POP_BSR
    RETFIE
   
    
    
;*******************************************************************************
; MAIN PROGRAM
;*******************************************************************************
MAIN_PROG CODE           ; let linker place main program
 
START1:
    ; -------------------- CONFIGURATION --------------------
    ; on met la frequence du microC a 16MHz
    MOVLB 0x0E     ; BSR -> 14
    MOVLW 0x05
    MOVWF OSCFRQ   ; registre pour modifier la frequence du microC
    
    ; On configure le sens des ports
    CLRF TRISC         ; tout les ports C sont en sortie 
    MOVLW b'11001111'
    MOVWF TRISB	       ; port B
    
    ; On configure les entrees comme des entres logique
    MOVLB 0x0F        ; BSR -> 15
    CLRF ANSELB, 1    ; entree analogique to logique (0 ou 1)
    
    ; On configure les interruption pour que les boutons fonctionnent
    MOVLW b'11000000'
    MOVWF INTCON
    MOVLB 0xE          ; BSR -> 15
    MOVLW b'00000000'
    MOVWF PIR0, 1
    MOVLW b'00010111'	; on a desactive les interruptions liees au timer
    MOVWF PIE0, 1
    MOVLB 0xF	       ; BSR -> 14
    MOVLW b'00001000'
    MOVWF IOCBN,1      ; congiguration du bouton 3
    
    ; Configuration du timer0
    MOVLW b'00010000'
    MOVWF T0CON0
    MOVLW b'01001000'
    MOVWF T0CON1
    ; On lance le timer
    CLRF TMR0H
    CLRF TMR0L	    ; On precharge le timer
    BSF T0CON0, 7   ; on allume le timer
    
    ; on dit que aucun bouton n'est presse au debut
    MOVLB 0x01
    MOVLW 0x04		    ; on charge une valeur par defaut
    MOVWF bouton_presse ,1   ; qui correspond a aucun 
    
    
    ; Configuration du buzzer
    BSF TRISC, 1
    MOVLW b'00000100'
    MOVWF CCPTMRS	; associe le module CCP2 avec le timer 2
    
    MOVLB 0x0E		; selection de la banque d'adresse
    MOVLW 0x06
    MOVWF RC1PPS, 1 ; associe le pin RC1 avec la fonction de sortie de CCP2
    MOVLW b'10011111'  ; -> ?
    MOVWF CCP2CON ; configuration du module CCP2 et format des donnees
    MOVLW b'00000001'
    MOVWF T2CLKCON ; configuration de l'horloge du timer 2 = Fosc/4
    MOVLW b'11010000'
    MOVWF T2CON ; choix des options du timer 2 (voir p.256)
    BCF TRISC, 1
    
    
    ; ------------------------ INITIALISATION ------------------------
    MOVLB 0x01	; -> BSR = 1
    
    ; On eteint toutes les leds
    ; MOVLW b'11110000'   ; charge une valeur pour allumer les leds
    MOVLW b'00000000'   ; charge une valeur pour allumer les leds
    MOVWF LATC        ; Ecrit sur le port C
    
    ; on se met en mode menu
    MOVLW 0x00
    MOVWF etat_jeu, 1
    
    ; On initialise le level a 1
    MOVLW 0x01
    MOVWF level, 1
    
    ; ON INTIALISE LE TABLEAU
    LFSR 1, 0x300   ; equivalent (movlw 0x200  ;  movwf fsr0 (haut et bas))
    
    
    GOTO $                          ; loop forever

    
    
    
    
;***********************************************
; ROUTINES
;***********************************************
; GENERATION_SEED_ET_COULEURS
; PLAY_RGB_ET_BUZZER
    
JOUER_PROCHAINE_SEQUENCE:
    CALL PUSH_BSR
    MOVLB 0x01    ; -> BSR
    CLRF compteur_suite, 1
    LOOP_SEQUENCE:
    ; Verifier si on a tout affiche 
    MOVF level, 0, 1
    CPFSEQ compteur_suite, 1	; si level et compteur sont egaux, on 
    GOTO SUITE
    GOTO END_SEQUENCE
    
    SUITE:
    MOVLW 0x00
    CPFSEQ INDF0
    GOTO suite30
    CALL ATTENDRE_02s
    CALL PLAY_RGB0
    
    suite30:
    MOVLW 0x01
    CPFSEQ INDF0
    GOTO suite31
    CALL ATTENDRE_02s
    CALL PLAY_RGB1
    
    suite31:
    MOVLW 0x02
    CPFSEQ INDF0
    GOTO suite32
    CALL ATTENDRE_02s
    CALL PLAY_RGB2
    
    suite32:
    MOVLW 0x03
    CPFSEQ POSTINC0
    GOTO suite33
    CALL ATTENDRE_02s
    CALL PLAY_RGB3
    
    suite33:
    INCF compteur_suite, 1	; on incremente le compteur
    GOTO LOOP_SEQUENCE 
    
    END_SEQUENCE:
    ; on remet FSRO a 0
    LFSR 0, 0x200   ; equivalent (movlw 0x200  ;  movwf fsr0 (haut et bas))
    CALL POP_BSR
    RETURN 
    
    
    
GAME_OVER:
    CALL PUSH_BSR
    CALL ATTENDRE_01s
    CALL PLAY_ROUGE_TOUTES_RGB
    LFSR 0, 0x200
    MOVLB 0x01
    CLRF etat_jeu,1
    MOVLW 0x01
    MOVWF level,1
    CALL POP_BSR
    
    RETURN
    
GENERATION_SEED_ET_COULEURS:
    CALL PUSH_BSR
    LFSR 0, 0x200
    ; GENERATION DE LA GRAINE
    MOVLW b'11111111'
    ANDWF TMR0L, 0	; On recupere tout les bits de TMR0L, -> WREG
    MOVWF seed, 1   ; on sauvegarde la seed
    ; affichage sur les leds
    SWAPF TMR0L, 0	; On inverse les 4 bits de WREG, on a donc ????0000
    MOVWF LATC        ; Ecrit sur le port C

    ; CREATION DE 10 COULEURS ALEATOIRES
    MOVLW d'20'
    MOVWF compteur0, 1
    MOVF seed, 0    ; on met seed dans l'accumulateur 
    GENERATE_LOOP:
    ; Verifier si 20 nombres ont ete genere
    DCFSNZ compteur0, 1,   ; Si different de 0, on skip
    GOTO END_GENERATION
    
    MOVWF WREG2, 1	; on fait ca car on est obliger de travailler avec une v
    RLNCF WREG2, 0, 1   ; on decale de 1 bit le contenu de WREG2
    XORLW b'10101010'
    ADDLW b'11111111'
    MOVWF WREG2, 1	; on sauvegarde WREG dans WREG2
    
    ANDLW b'00000011'   ; on garde que les 2 derniers bits
    MOVWF POSTINC0	; on stocke le nombre dans le tableau
    
    MOVF WREG2, 0, 1	; on remet l'avant derniere valeur dans wreg pour la 
                        ; prochaine generation
    GOTO GENERATE_LOOP 
    
    END_GENERATION:
    ; on remet FSRO a 0
    LFSR 0, 0x200   ; equivalent (movlw 0x200  ;  movwf fsr0 (haut et bas))
    CALL POP_BSR
    RETURN 
    
    
PLAY_RGB_ET_BUZZER:
    CALL PUSH_BSR   ; stocke la valeur du bsr
    
    MOVLB 0x01	    ; BSR = 0x01
    
    MOVLW 0x00 ; Charge la valeur de bouton_presse dans l'accumulateur W
    CPFSEQ bouton_presse,1 ; Test si bouton_presse est egal a 0
    GOTO MAJ_LED_suite1
    CALL PLAY_RGB0
    
    MAJ_LED_suite1:
    MOVLW 0x01
    CPFSEQ bouton_presse,1 ; Compare bouton_presse avec 1
    GOTO MAJ_LED_suite2
    CALL PLAY_RGB1
    
    MAJ_LED_suite2:
    MOVLW 0x02
    CPFSEQ bouton_presse,1 ; Compare bouton_presse avec 2
    GOTO MAJ_LED_suite3
    CALL PLAY_RGB2
    
    
    MAJ_LED_suite3:
    MOVLW 0x03
    CPFSEQ bouton_presse,1 ; Compare bouton_presse avec 3
    GOTO MAJ_LED_end
    CALL PLAY_RGB3
    
    
    MAJ_LED_end:
    CALL POP_BSR  ; redonne la valeur du bsr presente avant l'appel de la routine
    RETURN
      

PLAY_ALLUMAGE:
    CALL ALLUMER_RGB0
    CALL JOUER_SON0
    CALL ATTENDRE_02s
    CALL ETEINDRE_TOUTES_RGB
    
    CALL ATTENDRE_01s
    
    CALL ALLUMER_RGB1
    CALL JOUER_SON1
    CALL ATTENDRE_02s
    CALL ETEINDRE_TOUTES_RGB
    
    CALL ATTENDRE_01s
    
    CALL ALLUMER_RGB2
    CALL JOUER_SON2
    CALL ATTENDRE_02s
    CALL ETEINDRE_TOUTES_RGB
    
    CALL ATTENDRE_01s
    
    CALL ALLUMER_RGB3
    CALL JOUER_SON3
    CALL ATTENDRE_02s
    CALL ETEINDRE_TOUTES_RGB
    
    CALL ATTENDRE_01s
    
    RETURN


    
PLAY_VERT_TOUTES_RGB:
    CALL VERT_TOUTES_RGB
    CALL JOUER_SON0
    CALL ATTENDRE_2s
    CALL ETEINDRE_BUZZER
    CALL ETEINDRE_TOUTES_RGB
    RETURN
    
PLAY_ROUGE_TOUTES_RGB:
    CALL ROUGE_TOUTES_RGB
    CALL JOUER_SON1
    CALL ATTENDRE_2s
    CALL ETEINDRE_BUZZER
    CALL ETEINDRE_TOUTES_RGB
    RETURN
    
PLAY_RGB0:
    CALL ALLUMER_RGB0
    CALL JOUER_SON0
    CALL ATTENDRE_06s
    CALL ETEINDRE_BUZZER
    CALL ETEINDRE_TOUTES_RGB
    RETURN
    
PLAY_RGB1:
    CALL ALLUMER_RGB1
    CALL JOUER_SON1
    CALL ATTENDRE_06s
    CALL ETEINDRE_BUZZER
    CALL ETEINDRE_TOUTES_RGB
    RETURN
    
PLAY_RGB2:
    CALL ALLUMER_RGB2
    CALL JOUER_SON2
    CALL ATTENDRE_06s
    CALL ETEINDRE_BUZZER
    CALL ETEINDRE_TOUTES_RGB
    RETURN
    
PLAY_RGB3:
    CALL ALLUMER_RGB3
    CALL JOUER_SON3
    CALL ATTENDRE_06s
    CALL ETEINDRE_BUZZER
    CALL ETEINDRE_TOUTES_RGB
    RETURN
    

;*******************************************************************************
;				BIBLIOTHEQUE
;*******************************************************************************

;***********************************************
; AUTRE
;***********************************************   
; PUSH_BSR
; POP_BSR

; A placer au debut et a la fin d'une routine, cela permet de securiser la
; valeur pour le bloc de code qui appelle la routine
PUSH_BSR:
    MOVF BSR, 0, 0	; on met le BSR dans l'accumulateur
    MOVLB 0x01	     ; on change le bsr pour acceder a tempBSR
    MOVWF TEMP_BSR, 1	; on met le contenu de l'accumulateur dans tempbsr
    RETURN
    
POP_BSR:
    MOVLB 0x01	     ; on change le bsr pour acceder a tempBSR
    MOVF TEMP_BSR, 0, 1	    ; on met l'ancien bsr dans wreg
    MOVWF BSR, 0
    RETURN
    

    
;***********************************************
; BUZZER
;***********************************************
JOUER_SON0:
    BSF TRISC, 1 ; desactivation de la sortie PWM pour configuration
    
    MOVLW d'50'  ; -> ? 50
    MOVWF T2PR ; fixe la periode de PWM (voir formule p.271)
     
    MOVLW d'30'  ;
    MOVWF CCPR2H
    
    MOVLW d'0'   ;
    MOVWF CCPR2L ; fixe le rapport cyclique du signal
    BCF TRISC, 1 ; activation de la sortie PWM
    RETURN
    
JOUER_SON1:
    BSF TRISC, 1 ; desactivation de la sortie PWM pour configuration
    MOVLW d'300'  ;
    MOVWF T2PR ; fixe la periode de PWM 
    
    MOVLW d'30'  ;
    MOVWF CCPR2H
    
    MOVLW d'0'   ;
    MOVWF CCPR2L ; fixe le rapport cyclique du signal
    BCF TRISC, 1 ; activation de la sortie PWM
    RETURN
    
JOUER_SON2:
    BSF TRISC, 1 ; desactivation de la sortie PWM pour configuration
    MOVLW d'610'  ;
    MOVWF T2PR ; fixe la periode de PWM 
    
    MOVLW d'30'  ;
    MOVWF CCPR2H
    
    MOVLW d'0'   ;
    MOVWF CCPR2L ; fixe le rapport cyclique du signal
    BCF TRISC, 1 ; activation de la sortie PWM
    RETURN   
    
JOUER_SON3:
    BSF TRISC, 1 ; desactivation de la sortie PWM pour configuration
    MOVLW d'550'  ;
    MOVWF T2PR ; fixe la periode de PWM 
    
    MOVLW d'30'  ;
    MOVWF CCPR2H
    
    MOVLW d'0'   ;
    MOVWF CCPR2L ; fixe le rapport cyclique du signal
    BCF TRISC, 1 ; activation de la sortie PWM
    RETURN   
   
ETEINDRE_BUZZER:
    MOVLW d'0'  ; 
    MOVWF T2PR ; fixe la periode de PWM 
    RETURN
    
    
    
;***********************************************
; TIMER SOFTWARE
;***********************************************
ATTENDRE_01s:
    CALL PUSH_BSR
    
    MOVLB 0x01
    MOVLW 0x30
    MOVWF compteur0, 1
    loop70:  
	MOVLW 0x30
	MOVWF compteur1, 1
    loop71:
	MOVLW 0x30
	MOVWF compteur2, 1
    loop72:
    DECFSZ compteur2, 1, 1   ; decremente compteur2, skip if 0
	GOTO loop72   ; si compteur2 != 0	
  
    DECFSZ compteur1, 1, 1   ; decremente compteur1, skip if 0
	GOTO loop71
 
    DECFSZ compteur0, 1, 1   ; decremente compteur0, skip if 0
	GOTO loop70
	
    CALL POP_BSR
    RETURN
    
    
ATTENDRE_02s:
    CALL PUSH_BSR
    
    MOVLB 0x01
    MOVLW 0x30
    MOVWF compteur0, 1
    loop50:  
	MOVLW 0x40
	MOVWF compteur1, 1
    loop51:
	MOVLW 0x30
	MOVWF compteur2, 1
    loop52:
    DECFSZ compteur2, 1, 1   ; decremente compteur2, skip if 0
	GOTO loop52   ; si compteur2 != 0	
  
    DECFSZ compteur1, 1, 1   ; decremente compteur1, skip if 0
	GOTO loop51
 
    DECFSZ compteur0, 1, 1   ; decremente compteur0, skip if 0
	GOTO loop50
	
    CALL POP_BSR
    RETURN
    
ATTENDRE_06s:
    CALL PUSH_BSR
    
    MOVLB 0x01
    MOVLW 0xFF
    MOVWF compteur0, 1
    loop90:  
	MOVLW 0x30
	MOVWF compteur1, 1
    loop91:
	MOVLW 0x30
	MOVWF compteur2, 1
    loop92:
    DECFSZ compteur2, 1, 1   ; decremente compteur2, skip if 0
	GOTO loop92   ; si compteur2 != 0	
  
    DECFSZ compteur1, 1, 1   ; decremente compteur1, skip if 0
	GOTO loop91
 
    DECFSZ compteur0, 1, 1   ; decremente compteur0, skip if 0
	GOTO loop90
	
    CALL POP_BSR
    RETURN
    
    
ATTENDRE_1s:
    CALL PUSH_BSR
    
    MOVLB 0x01
    MOVLW 0xFF
    MOVWF compteur0, 1
    loop60:  
	MOVLW 0x40
	MOVWF compteur1, 1
    loop61:
	MOVLW 0x50
	MOVWF compteur2, 1
    loop62:
    DECFSZ compteur2, 1, 1   ; decremente compteur2, skip if 0
	GOTO loop62   ; si compteur2 != 0	
  
    DECFSZ compteur1, 1, 1   ; decremente compteur1, skip if 0
	GOTO loop61
 
    DECFSZ compteur0, 1, 1   ; decremente compteur0, skip if 0
	GOTO loop60
	
    CALL POP_BSR
    RETURN
     
    
ATTENDRE_2s:
    CALL PUSH_BSR
    
    MOVLB 0x01
    MOVLW 0xFF
    MOVWF compteur0, 1
    loop80:  
	MOVLW 0x60
	MOVWF compteur1, 1
    loop81:
	MOVLW 0x50
	MOVWF compteur2, 1
    loop82:
    DECFSZ compteur2, 1, 1   ; decremente compteur2, skip if 0
	GOTO loop82   ; si compteur2 != 0	
  
    DECFSZ compteur1, 1, 1   ; decremente compteur1, skip if 0
	GOTO loop81
 
    DECFSZ compteur0, 1, 1   ; decremente compteur0, skip if 0
	GOTO loop80
	
    CALL POP_BSR
    RETURN
    
    

;***********************************************
; RGB
;***********************************************
; MULTICOULEUR_TOUTES_RGB
; ROUGE_TOUTES_RGB
; VERT_TOUTES_RGB
; ALLUMER_RGB0
; ALLUMER_RGB1
; ALLUMER_RGB2
; ALLUMER_RGB3
; ETEINDRE_TOUTES_RGB

; ----- ROUTINES EXTERNES -----
MULTICOULEUR_TOUTES_RGB_1:
    CALL ALLUMER_ROUGE
    CALL ALLUMER_BLEU
    CALL ALLUMER_VERT
    CALL ALLUMER_JAUNE
    RETURN
    
MULTICOULEUR_TOUTES_RGB_2:
    CALL ALLUMER_JAUNE
    CALL ALLUMER_ROUGE
    CALL ALLUMER_BLEU
    CALL ALLUMER_VERT
    RETURN
    
MULTICOULEUR_TOUTES_RGB_3:
    CALL ALLUMER_VERT
    CALL ALLUMER_JAUNE
    CALL ALLUMER_ROUGE
    CALL ALLUMER_BLEU
    RETURN
    
MULTICOULEUR_TOUTES_RGB_4:
    CALL ALLUMER_BLEU
    CALL ALLUMER_VERT
    CALL ALLUMER_JAUNE
    CALL ALLUMER_ROUGE
    RETURN
    
ROUGE_TOUTES_RGB:
    CALL ALLUMER_ROUGE
    CALL ALLUMER_ROUGE
    CALL ALLUMER_ROUGE
    CALL ALLUMER_ROUGE
    RETURN
    
VERT_TOUTES_RGB: 
    CALL ALLUMER_VERT
    CALL ALLUMER_VERT
    CALL ALLUMER_VERT
    CALL ALLUMER_VERT
    RETURN
    
ALLUMER_RGB0:
    CALL ALLUMER_ROUGE
    CALL ETEINDRE_LED
    CALL ETEINDRE_LED
    CALL ETEINDRE_LED
    RETURN

ALLUMER_RGB1:
    CALL ETEINDRE_LED
    CALL ALLUMER_BLEU
    CALL ETEINDRE_LED
    CALL ETEINDRE_LED
    RETURN

ALLUMER_RGB2:
    CALL ETEINDRE_LED
    CALL ETEINDRE_LED
    CALL ALLUMER_VERT
    CALL ETEINDRE_LED
    RETURN

ALLUMER_RGB3:
    CALL ETEINDRE_LED
    CALL ETEINDRE_LED
    CALL ETEINDRE_LED
    CALL ALLUMER_JAUNE
    RETURN

    
ETEINDRE_TOUTES_RGB:
    CALL ETEINDRE_LED
    CALL ETEINDRE_LED
    CALL ETEINDRE_LED
    CALL ETEINDRE_LED
    RETURN

    
; ----- ROUTINES INTERNES -----
ETEINDRE_LED:
    ; GREEN
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    ; RED
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    ; BLUE
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    RETURN
    
ALLUMER_ROUGE:
    ; GREEN
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    ; RED
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_1
    CALL ENVOYER_0
    ; BLUE
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    RETURN
    
ALLUMER_VERT:
    ; GREEN
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_1
    CALL ENVOYER_0
    ; RED
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    ; BLUE
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    RETURN
    
ALLUMER_BLEU:
    ; GREEN
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    ; RED
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    ; BLUE
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_1
    CALL ENVOYER_0
    RETURN
    
ALLUMER_JAUNE:
    ; GREEN
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_1
    CALL ENVOYER_0
    CALL ENVOYER_0
    ; RED
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_1
    CALL ENVOYER_0
    CALL ENVOYER_0
    ; BLUE
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    CALL ENVOYER_0
    RETURN

ENVOYER_0:
    BSF LATB,5,0
    BCF LATB,5,0
    NOP
    NOP
    NOP
    RETURN

ENVOYER_1:
    BSF LATB, 5,0
    NOP
    NOP
    BCF LATB, 5,0
    NOP
    RETURN
 
    
END