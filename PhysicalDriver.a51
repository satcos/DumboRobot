INCLUDE reg_51.pdf

; ===============================================================================
; Register Bank
; ===============================================================================
RB0		EQU		000H    ; Select Register Bank 0
RB1		EQU		008H    ; Select Register Bank 1
RB2		EQU		010H    ; Select Register Bank 2

; ===============================================================================
; Command Constant declaration
; ===============================================================================
CMDSTOP		EQU	000H
PLSFORWARD	EQU	001H
CNTFORWARD	EQU	002H
PLSRIGHT	EQU	003H
CNTRIGHT	EQU	004H
PLSLEFT		EQU	005H
CNTLEFT		EQU	006H
PLSBACK		EQU	007H
CNTBACK		EQU	008H
SHUTDOWN	EQU	00FH

; ===============================================================================
; Port Declaration
; ===============================================================================
RELAY		EQU		P1.4	; Raspberry pi turn on relay

MOTORDRIVER EQU		P2		; Motors are connected to this port through bridge connection

LED			EQU		P3.1	; Red Led indicator
INPUT		EQU		P3.3	; Port3, Bit3 is used as input ready interrupt.
MSBIT1		EQU		P3.6	; 4 data bits
MSBIT2		EQU		P3.4	; 
MSBIT3		EQU		P3.5	; 
MSBIT4		EQU		P3.7	; 

; ===============================================================================
; Data Declaration
; ===============================================================================
DSEG
; This is internal data memory
; Bit addressable memory
ORG 20H
	COMMAND:		DS		1			; 4 bit command, 8 bits are allocated
	FLAGS:			DS		1
	NEWCOMMAND		BIT		FLAGS.1		; Toggle represents and new command
	NEW				BIT		FLAGS.2		; Bit set when a new command has been received
	
						
; ===============================================================================
; Code begins here
; ===============================================================================
CSEG            
ORG	0000H							; Reset
	JMP MAIN
ORG 0003H  							; External Interrupt 0
	ACALL RECEIVE
	RETI

	
; ===============================================================================
; RECEIVE: Interrupt 1 routine 
; INPUT falling from 1 to zero indicated availability of new command
; 4 data bits are read in sequence and stored in COMMAND
; ===============================================================================
RECEIVE:
	
	; Clear accumulator
	CLR A
	
	; Read Most Significant Bit 1
	MOV C, MSBIT1
	RLC A
	
	; Read Most Significant Bit 2
	MOV C, MSBIT2
	RLC A
	
	; Read Most Significant Bit 3
	MOV C, MSBIT3
	RLC A
	
	; Read Most Significant Bit 4
	MOV C, MSBIT4
	RLC A
	
	; Store the received command in 'COMMAND'
	MOV COMMAND, A
	
	SETB NEWCOMMAND
	
	; Exit routine
	RET

; ===============================================================================
; PAUSEMOTOR: Switch off motors for few cycles so that they can be operated in reverse direction
; ===============================================================================
PAUSEMOTOR:
	MOV MOTORDRIVER, #000H
	MOV R7, #0FFH
	DJNZ R7, $
	MOV R7, #0FFH
	DJNZ R7, $
	MOV R7, #0FFH
	DJNZ R7, $
	MOV R7, #0FFH
	DJNZ R7, $
	RET
	
; ===============================================================================
; MAIN: Main program
; Blinks Led to check controller functionality
; ===============================================================================
MAIN:
	
	; ===========================================================================
	; Initialization
	; Port
	CLR LED
	SETB INPUT
	SETB MSBIT1
	SETB MSBIT2
	SETB MSBIT3
	SETB MSBIT4
	SETB RELAY
	
	; Storage
	CLR NEWCOMMAND
	MOV COMMAND, #0000H
	
	; Interrupt
	SETB EX1						; Enable external Interrupt1
	CLR IT1							; Triggered by a high to low transition
	SETB EA							; Enable global interrupt
	; ===========================================================================
	
	
	; Test code, will be removed in the final version
	LOOP1:
		ACALL PAUSEMOTOR
		MOV MOTORDRIVER, #05CH
		MOV R1, #00AFH
		LOOP2:
			MOV R2, #00FFH
			LOOP3:
				MOV R3, #00FFH
				DJNZ R3, $
				DJNZ R2, LOOP3
			DJNZ R1, LOOP2
		CPL LED
		
		ACALL PAUSEMOTOR
		MOV MOTORDRIVER, #0A3H
		MOV R1, #00AFH
		LOOP4:
			MOV R2, #00FFH
			LOOP5:
				MOV R3, #00FFH
				DJNZ R3, $
				DJNZ R2, LOOP5
			DJNZ R1, LOOP4
		CPL LED

		ACALL PAUSEMOTOR
		MOV MOTORDRIVER, #095H
		MOV R1, #00AFH
		LOOP6:
			MOV R2, #00FFH
			LOOP7:
				MOV R3, #00FFH
				DJNZ R3, $
				DJNZ R2, LOOP7
			DJNZ R1, LOOP6
		CPL LED

		ACALL PAUSEMOTOR
		MOV MOTORDRIVER, #06AH
		MOV R1, #00AFH
		LOOP8:
			MOV R2, #00FFH
			LOOP9:
				MOV R3, #00FFH
				DJNZ R3, $
				DJNZ R2, LOOP9
			DJNZ R1, LOOP8
		CPL LED
		
		JMP LOOP1
	
	
	; Wait till new command is received
	HERE:
	JNB NEWCOMMAND, HERE
	
	; Proceed if new command is received
	; As we started reading the new command, set off its flag
	; #000H		Stop
	; #05CH		Forward
	; #0A3H		Backward
	; #095H		Right
	; #06AH		Left
	
	CLR NEWCOMMAND
	MOV A, COMMAND
	
		CJNE A, CMDSTOP, LPF
		MOV MOTORDRIVER, #000H
		SJMP HERE
	LPF:
		CJNE A, PLSFORWARD, LCF
		MOV MOTORDRIVER, #000H
		NOP
		NOP
		SJMP HERE
	LCF:
		CJNE A, CNTFORWARD, LPR
		MOV MOTORDRIVER, #000H
		NOP
		NOP
		SJMP HERE
	LPR:
		CJNE A, PLSRIGHT, LCR
		MOV MOTORDRIVER, #000H
		NOP
		NOP
		SJMP HERE
	LCR:
		CJNE A, CNTRIGHT, LPL
		MOV MOTORDRIVER, #000H
		NOP
		NOP
		SJMP HERE
	LPL:
		CJNE A, PLSLEFT, LCL
		MOV MOTORDRIVER, #000H
		NOP
		NOP
		SJMP HERE
	LCL:
		CJNE A, CNTLEFT, LPB
		MOV MOTORDRIVER, #000H
		NOP
		NOP
		SJMP HERE
	LPB:
		CJNE A, PLSBACK, LCB
		MOV MOTORDRIVER, #000H
		NOP
		NOP
		SJMP HERE
	LCB:
		CJNE A, CNTBACK, LSH
		MOV MOTORDRIVER, #000H
		NOP
		NOP
		SJMP HERE
	LSH:
		CJNE A, SHUTDOWN, HERE
		MOV MOTORDRIVER, #000H
		NOP
		NOP
		CLR RELAY
	

	SJMP HERE

END