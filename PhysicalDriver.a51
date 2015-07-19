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
INPUT		EQU		P3.3	; Port3, Bit3 is used as input ready interrupt.	Pi Pin 11
MSBIT1		EQU		P3.6	; 4 data bits. Pi Pin 12
MSBIT2		EQU		P3.4	; Pi Pin 13
MSBIT3		EQU		P3.5	; Pi Pin 15
MSBIT4		EQU		P3.7	; Pi Pin 16

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
ORG 0013H  							; External Interrupt 0
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
; DELAYPULSE: Delay for pulse movement.
; 1 second and 51 millisecond
; If new command is received, exit the current loop
; ===============================================================================
DELAYPULSE:
	MOV R1, #0008H
		LOOP2:
			MOV R2, #00FFH
			LOOP3:
				MOV R3, #00FFH
				DJNZ R3, $
				JB NEWCOMMAND, EXITDELALY
				DJNZ R2, LOOP3
			DJNZ R1, LOOP2
	EXITDELALY:
	RET
; ===============================================================================
; DELAY2MIN: Two minute delay,after which raspberry pi power
; will be shut-down.
; ===============================================================================
DELAY2MIN:
	MOV R7, #0078H
	D2ML1:
		ACALL DELAYPULSE
		DJNZ R7, D2ML1
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
	MOV MOTORDRIVER, #000H
	
	; Storage
	CLR NEWCOMMAND
	MOV COMMAND, #0000H
	
	; Interrupt
	SETB EX1						; Enable external Interrupt1
	SETB IT1						; Triggered by a high to low transition
	SETB EA							; Enable global interrupt
	; ===========================================================================
	
	
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
	
		CJNE A, #CMDSTOP, LPF
		MOV MOTORDRIVER, #000H
		SJMP HERE
	LPF:
		CJNE A, #PLSFORWARD, LCF
		ACALL PAUSEMOTOR
		MOV MOTORDRIVER, #05CH
		ACALL DELAYPULSE
		MOV MOTORDRIVER, #000H
		SJMP HERE
	LCF:
		CJNE A, #CNTFORWARD, LPR
		ACALL PAUSEMOTOR
		MOV MOTORDRIVER, #05CH
		SJMP HERE
	LPR:
		CJNE A, #PLSRIGHT, LCR
		ACALL PAUSEMOTOR
		MOV MOTORDRIVER, #095H
		ACALL DELAYPULSE
		MOV MOTORDRIVER, #000H
		SJMP HERE
	LCR:
		CJNE A, #CNTRIGHT, LPL
		ACALL PAUSEMOTOR
		MOV MOTORDRIVER, #095H
		SJMP HERE
	LPL:
		CJNE A, #PLSLEFT, LCL
		ACALL PAUSEMOTOR
		MOV MOTORDRIVER, #06AH
		ACALL DELAYPULSE
		MOV MOTORDRIVER, #000H
		SJMP HERE
	LCL:
		CJNE A, #CNTLEFT, LPB
		ACALL PAUSEMOTOR
		MOV MOTORDRIVER, #06AH
		SJMP HERE
	LPB:
		CJNE A, #PLSBACK, LCB
		ACALL PAUSEMOTOR
		MOV MOTORDRIVER, #0A3H
		ACALL DELAYPULSE
		MOV MOTORDRIVER, #000H
		SJMP HERE
	LCB:
		CJNE A, #CNTBACK, LSH
		ACALL PAUSEMOTOR
		MOV MOTORDRIVER, #0A3H
		SJMP HERE
	LSH:
		CJNE A, #SHUTDOWN, HERE
		CLR EA						; Stop receiving further comments
		ACALL PAUSEMOTOR			; Stop motor operation
		ACALL DELAY2MIN				; Wait for raspberry pi to shut-down
		CLR RELAY					; Turn of relay
		ACALL DELAYPULSE			; Wait for 3 seconds and self kill
		ACALL DELAYPULSE
		ACALL DELAYPULSE

END
