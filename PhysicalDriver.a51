INCLUDE reg_51.pdf

; ===============================================================================
; Register Bank
; ===============================================================================
RB0		EQU		000H    ; Select Register Bank 0
RB1		EQU		008H    ; Select Register Bank 1
RB2		EQU		010H    ; Select Register Bank 2


; ===============================================================================
; Port Declaration
; ===============================================================================
LED		EQU		P3.1	; Red Led indicator
INPUT	EQU		P3.2	; Port3, Bit2 is used as input. The demodulated signal
						; with active low level is connected to this pin
OUTPUT	EQU		P2		; 8 bit output port
TESTBIT	EQU		P1.0	; TestBit
; ===============================================================================
; Data Declaration
; ===============================================================================
DSEG
; This is internal data memory
; Bit addressable memory
ORG 20H
	FLAGS:			DS		1
	TOGGLEBIT		BIT		FLAGS.1		; Toggles with every new keystroke
	NEW				BIT		FLAGS.2		; Bit set when a new command has been received
	ADDRESSPLUS:	DS		1			; S2, Toggle and 5 bit address
	COMMAND:		DS		1			; 6 bit command
	OLDTOGGLE:		DS		1			; S2, Toggle and 5 bit address
						
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
; RECEIVE: Interrupt 0 routine 
; Receives signal from IR remove
; Bit Sequence
; S1 S2 Toggle 5 Bit Address 6 Bit Command
; Total duration of a bit 1.778ms
; Quarter of the bit is 0.4445ms
; Instructions MOV R1, #222 and DJNZ R1, $ need 0.445 ms 
; which is approximately 1/4th of the bit length
; Crystal frequency is 12MHz
; ===============================================================================
RECEIVE:
	; Disable global interrupt
	CLR EA
	CLR A
	
	; Already half of the s1 bit is spent, wait for the 2nd half of the bit
	MOV R1, #222
	DJNZ R1, $
	MOV C, INPUT		
	RLC A
	MOV R1, #222
	DJNZ R1, $
	
	; First Half of Start 2 bit
	MOV R1, #222
	DJNZ R1, $
	MOV C, INPUT
	RLC A
	MOV R1, #222
	DJNZ R1, $
	
	; Second Half of Start 2 bit
	MOV R1, #222
	DJNZ R1, $
	MOV C, INPUT
	RLC A
	MOV R1, #222
	DJNZ R1, $
	
	; Check for noise input
	; If the accumulator value doesn't match with the expected value,
	; its a noise and hence exit
	XRL A, #005H
	JZ CONTINUEREADING
	SETB EA
	RET
	
	CONTINUEREADING:
	; Store toggle bit and 5 bit address in ADDRESSPLUS location
	; Loop through 6 times to read toggle and 5 bit address
	; Wait 1/4 of the bit and read bit value
	; then wast 3/4th of time
	MOV R2, #006H
	CLR A
	READADDRESS:
		MOV R1, #222
		DJNZ R1, $
		MOV C, INPUT
		RLC A
		MOV R1, #222
		DJNZ R1, $
		MOV R1, #222
		DJNZ R1, $
		MOV R1, #220
		DJNZ R1, $	
		DJNZ R2, READADDRESS
	MOV ADDRESSPLUS, A
	
	; Loop through 6 times and read command
	MOV R2, #006H
	CLR A
	READCOMMAND:
		MOV R1, #222
		DJNZ R1, $
		MOV C, INPUT
		RLC A
		MOV R1, #222
		DJNZ R1, $
		MOV R1, #222
		DJNZ R1, $
		MOV R1, #220
		DJNZ R1, $
		DJNZ R2, READCOMMAND
	MOV COMMAND, A
	
	; Send the received command to the output port
	CLR OUTPUT
	MOV OUTPUT, COMMAND
	
	MOV A, COMMAND
	XRL A, #03FH
	JZ SKIPTOGGLE
	
	; ; Complement LED if new button is clicked
	; MOV A, ADDRESSPLUS
	; ANL A, #020H
	; MOV ADDRESSPLUS, A
	; XRL A, OLDTOGGLE
	; JZ SKIPTOGGLE
	; MOV OLDTOGGLE, A
	
	CPL LED
	SKIPTOGGLE:
	
	; Enable global interrupt again
	SETB EA
	
	; Exit routine
	RET
	
; ===============================================================================
; MAIN: Main program
; Blinks Led to check controller functionality
; ===============================================================================
MAIN:
	SETB INPUT
	CLR OUTPUT
	CLR TESTBIT
	SETB LED
	
	SETB EX0						; Enable external Interrupt0
	CLR IT0							; Triggered by a high to low transition
	SETB EA							; Enable global interrupt
	
	MOV OLDTOGGLE, #000H
		
	HERE:
	SJMP HERE

END