; http://www.8051projects.info/resources/infrared-receiver-interfacing.36/
; http://www.sbprojects.com/knowledge/ir/rc5.php
INCLUDE reg_51.pdf

; ===============================================================================
; Register Bank
; ===============================================================================
RB0		EQU		000H    ; Select Register Bank 0
RB1		EQU		008H    ; Select Register Bank 1  ...poke to PSW to use
RB2		EQU		010H    ; Select Register Bank 2.

; ===============================================================================
; Port Declaration
; ===============================================================================
INPUT	EQU		P3.2	; Port3,Bit2 is used as input. The demodulated signal
						; with active low level is connected to this pin

; ===============================================================================
; Data Declaration
; ===============================================================================
DSEG
; This is internal data memory
; Bit addressable memory
ORG 20H
	FLAGS:		DS		1
	CONTROL		BIT		FLAGS.0		; Toggles with every new keystroke
	NEW			BIT		FLAGS.1		; Bit set when a new command has been received
	COMMAND:	DS		1			; Received command byte
	SUBAD:		DS		1			; Device subaddress
	TOGGLE:		DS		1			; Toggle every bit
	ANS:		DS		1
	ADDR:		DS		1
	STACK:		DS		1			; Stack begins here

; ===============================================================================
; Code begins here
; ===============================================================================
CSEG            
ORG 0000H							; Reset
	JMP MAIN
ORG 0003H  							; External Interrupt 0
	JMP RECEIVE    
     

; ===============================================================================
; RECEIVE: Interrupt 0 routine 
; Receives signal from IR remove
; ===============================================================================
RECEIVE:
	CPL P2.2
	MOV 2, #235						; Time Loop (3/4 bit time)
	DJNZ 2, $						; Waste Time to sync second bit
	MOV 2, #235						; Time Loop (3/4 bit time)
	DJNZ 2, $						; Waste Time to sync second bit
	Mov 2, #134						; Time Loop (3/4 bit time)
	DJNZ 2, $						; Waste Time to sync second bit
	CLR A
	MOV R6, #07H

POL1:
	MOV C, INPUT
	RLC A
	Mov 2, #235						; Waste time for next BIT
	DJNZ 2, $  
	Mov 2, #235						; Time Loop (3/4 bit time)
	DJNZ 2, $						; Waste Time to sync second bit
	Mov 2, #235						; Time Loop (3/4 bit time)
	DJNZ 2, $						; Waste Time to sync second bit
	Mov 2, #105						; Time Loop (3/4 bit time)
	DJNZ 2, $						; Waste Time to sync second bit
	DJNZ R6, POL1
	MOV SUBAD, A
	MOV R6, #06H

POL2:
	MOV C, Input
	RLC A
	MOV 2, #235						; Waste time for next BIT
	DJNZ 2, $  
	MOV 2, #235						; Time Loop (3/4 bit time)
	DJNZ 2, $						; Waste Time to sync second bit
	MOV 2, #235						; Time Loop (3/4 bit time)
	DJNZ 2, $						; Waste Time to sync second bit
	MOV 2, #105						; Time Loop (3/4 bit time)
	DJNZ 2, $						; Waste Time to sync second bit
	DJNZ R6, POL2
	Mov COMMAND, A					; Save Command at IRData memory
	MOV A, SUBAD
	MOV ADDR, A
	ANL A, #0FH
	MOV SUBAD, A
	CJNE A, #03H, ZXC1
	MOV A, COMMAND
	CPL A
	MOV COMMAND, A
	AJMP ASZ

ZXC1:
	MOV A, SUBAD
	CJNE A, #00H, ANSS
	AJMP ASZ
 
ASZ:
	MOV A, ADDR
	ANL A, #20H
	MOV TOGGLE, A
	CJNE A, ANS, ANSS
	AJMP WAR

ANSS:
	JMP ANS1
	
WAR:           
	MOV A, COMMAND
	CJNE A, #01H, DSP1
	CPL P0.0
	DSP1:	CJNE A, #02H, DSP2
	CPL P0.1
	DSP2:	CJNE A, #03H, DSP3
	CPL P0.2
	DSP3:	CJNE A, #04H, DSP4
	CPL P0.3
	DSP4:	CJNE A, #05H, DSP5
	CPL P0.4
	DSP5:	CJNE A, #06H, DSP6
	CPL P0.5
	DSP6:	CJNE A, #07H, DSP7
	CPL P0.6
	DSP7:	CJNE A, #08H, DSP8
	CPL P0.7
	DSP8:	CJNE A, #0CH, DSP9
	MOV P0, #0FFH
	DSP9:
		MOV ANS, TOGGLE
		MOV A, ANS
		CPL ACC.5
		MOV ANS, A
		SETB NEW						; Set flag to indicate the new command


;################################################################      
ANS1:
	RETI


; ===============================================================================
; MAIN: Main program
; Perform initialization
; Loop infinitely, clear if NEW flag is set
; ===============================================================================
MAIN:
	MOV SP, #60H
	SETB EX0						; Enable external Interrupt0
	CLR IT0							; Triggered by a high to low transition
	SETB EA							; Enable global interrupt
	MOV ANS, #00H					; Clear temp toggle bit
	CLR NEW							; Initialize NEW flag
	LOO:
		JNB NEW, LOO
		CLR NEW
		AJMP LOO

; ===============================================================================
; End of program
; ===============================================================================
END