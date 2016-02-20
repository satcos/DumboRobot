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
FRONTDRV	EQU	009H
BACKTDRV	EQU	00AH
POWERTDRV	EQU	00BH
SHUTDOWN	EQU	00FH

; ===============================================================================
; Port Declaration
; ===============================================================================
TESTPORT 	EQU		P0		; Motors are connected to this port through bridge connection

RELAY		EQU		P1.4	; Raspberry pi turn on relay

MOTORDRIVER EQU		P2		; Motors are connected to this port through bridge connection

LED			EQU		P3.1	; Red Led indicator
IRINPUT		EQU		P3.2	; Port3, Bit2 is used as input. The demodulated signal
							; with active low level is connected to this pin
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
	ADDRESSPLUS:	DS		1			; S2, Toggle and 5 bit address
	OLDTOGGLE:		DS		1			; S2, Toggle and 5 bit address
	DRIVEMASK:		DS		1			; MASK for front, back and power drive.
	FLAGS:			DS		1
	NEWCOMMAND		BIT		FLAGS.1		; Toggle represents and new command
	TOGGLEBIT		BIT		FLAGS.2		; Toggles with every new keystroke
	

; ===============================================================================
; Code begins here
; ===============================================================================
CSEG            
ORG	0000H							; Reset
	JMP MAIN
ORG 0003H  							; External Interrupt 0
	ACALL RECEIVEIR
	RETI
ORG	000BH							; Timer 0 interrupt
	ACALL BLINKLED
	RETI
ORG 0013H  							; External Interrupt 1
	ACALL RECEIVE
	RETI


; ===============================================================================
; RECEIVEIR: Interrupt 0 routine 
; Receives signal from IR remove
; Bit Sequence
; S1, S2, Toggle, 5 Bit Address, 6 Bit Command
; Total duration of a bit 1.778ms
; Quarter of the bit is 0.4445ms
; Instructions MOV R1, #222 and DJNZ R1, $ need 0.445 ms 
; which is approximately 1/4th of the bit length
; Crystal frequency is 12MHz
; ===============================================================================
RECEIVEIR:
	; Disable external interrupt 0 as transition of data pin triggers many calls
	CLR EX0
	
	CLR A
	; Already half of the s1 bit is spent, wait for the 2nd half of the bit
	MOV R4, #222
	DJNZ R4, $
	MOV C, IRINPUT		
	RLC A
	MOV R4, #220
	DJNZ R4, $
	
	; First Half of Start 2 bit
	MOV R4, #222
	DJNZ R4, $
	MOV C, IRINPUT
	RLC A
	MOV R4, #220
	DJNZ R4, $
	
	; Second Half of Start 2 bit
	MOV R4, #222
	DJNZ R4, $
	MOV C, IRINPUT
	RLC A
	MOV R4, #220
	DJNZ R4, $
	
	; Check for noise input
	; If the accumulator value doesn't match with the expected value,
	; its a noise and hence exit
	XRL A, #000H
	JZ CONTINUEREADING
	SETB EX0
	RET
	
	CONTINUEREADING:
	; Store toggle bit and 5 bit address in ADDRESSPLUS location
	; Loop through 6 times to read toggle and 5 bit address
	; Wait 1/4 of the bit and read bit value
	; then wast 3/4th of time
	MOV R5, #006H
	CLR A
	READADDRESS:
		MOV R4, #222
		DJNZ R4, $
		MOV R4, #222
		DJNZ R4, $
		MOV R4, #222
		DJNZ R4, $
		MOV C, IRINPUT
		RLC A
		MOV R4, #220
		DJNZ R4, $	
		DJNZ R5, READADDRESS
	MOV ADDRESSPLUS, A
	
	; Loop through 6 times and read command
	MOV R5, #006H
	CLR A
	READCOMMAND:
		MOV R4, #222
		DJNZ R4, $
		MOV R4, #222
		DJNZ R4, $
		MOV R4, #222
		DJNZ R4, $
		MOV C, IRINPUT
		RLC A
		MOV R4, #220
		DJNZ R4, $
		DJNZ R5, READCOMMAND
	MOV COMMAND, A
	
	; Check received command is new
	MOV A, ADDRESSPLUS
	ANL A, #020H
	XRL A, OLDTOGGLE
	JZ SKIPTOGGLE
	MOV OLDTOGGLE, A		;New command is received
	SETB NEWCOMMAND
	
	SKIPTOGGLE:
	
	; Exit routine
	SETB EX0
	RET
	
; ===============================================================================
; BLINKLED: Timer 0 Interrupt routine 
; Turns on led after 20 iterations
; ===============================================================================
BLINKLED:

	CLR TR0
	CLR TF0
	DJNZ R6, BLL1
	CLR LED									; After 20 iterations, turn on the LED and exit the function
	MOV R6, #014H
	MOV TH0, #03CH
	MOV TL0, #0B0H
	RET
	
	BLL1:
	MOV TH0, #03CH
	MOV TL0, #0B0H
	SETB TR0								;Start the Timer0
	
	RET
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
	SETB RELAY
	CLR LED
	SETB IRINPUT
	CLR MSBIT1
	CLR MSBIT2
	CLR MSBIT3
	CLR MSBIT4
	CLR INPUT
	
	MOV TESTPORT, #000H
	MOV MOTORDRIVER, #000H
	
	; Reset Storage
	CLR NEWCOMMAND
	MOV COMMAND, #000H
	MOV DRIVEMASK, #0FFH
	
	; Interrupt
	; External interrupt
	SETB EX0						; Enable external Interrupt0	IR Input
	SETB IT0						; Triggered by a high to low transition
	SETB EX1						; Enable external Interrupt1	RPi Input
	SETB IT1						; Triggered by a high to low transition
	
	;Setting Timer 0 for LED blink when new command is received
	MOV TMOD, #011H
	MOV R6, #014H
	MOV TH0, #03CH
	MOV TL0, #0B0H
	SETB ET0
	
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
	
	; Start timer 0 for led blink
	SETB LED								; Stop the led
	SETB TR0								; Start the Timer0
	
	MOV A, COMMAND
	MOV TESTPORT, A
	
		CJNE A, #CMDSTOP, LPF
		MOV MOTORDRIVER, #000H
		SJMP HERE
	LPF:
		CJNE A, #PLSFORWARD, LCF
		ACALL PAUSEMOTOR
		MOV A, #DRIVEMASK
		ANL A, #05CH
		MOV MOTORDRIVER, A
		ACALL DELAYPULSE
		MOV MOTORDRIVER, #000H
		SJMP HERE
	LCF:
		CJNE A, #CNTFORWARD, LPR
		ACALL PAUSEMOTOR
		MOV A, #DRIVEMASK
		ANL A, #05CH
		MOV MOTORDRIVER, A
		SJMP HERE
	LPR:
		CJNE A, #PLSRIGHT, LCR
		ACALL PAUSEMOTOR
		MOV A, #DRIVEMASK
		ANL A, #095H
		MOV MOTORDRIVER, A
		ACALL DELAYPULSE
		MOV MOTORDRIVER, #000H
		SJMP HERE
	LCR:
		CJNE A, #CNTRIGHT, LPL
		ACALL PAUSEMOTOR
		MOV A, #DRIVEMASK
		ANL A, #095H
		MOV MOTORDRIVER, A
		SJMP HERE
	LPL:
		CJNE A, #PLSLEFT, LCL
		ACALL PAUSEMOTOR
		MOV A, #DRIVEMASK
		ANL A, #06AH
		MOV MOTORDRIVER, A
		ACALL DELAYPULSE
		MOV MOTORDRIVER, #000H
		SJMP HERE
	LCL:
		CJNE A, #CNTLEFT, LPB
		ACALL PAUSEMOTOR
		MOV A, #DRIVEMASK
		ANL A, #06AH
		MOV MOTORDRIVER, A
		SJMP HERE
	LPB:
		CJNE A, #PLSBACK, LCB
		ACALL PAUSEMOTOR
		MOV A, #DRIVEMASK
		ANL A, #0A3H
		MOV MOTORDRIVER, A
		ACALL DELAYPULSE
		MOV MOTORDRIVER, #000H
		LJMP HERE
	LCB:
		CJNE A, #CNTBACK, LFD
		ACALL PAUSEMOTOR
		MOV A, #DRIVEMASK
		ANL A, #0A3H
		MOV MOTORDRIVER, A
		LJMP HERE
	LFD:
		CJNE A, #FRONTDRV, LBD
		MOV DRIVEMASK, #00FH
		LJMP HERE
	LBD:
		CJNE A, #BACKTDRV, LPD
		MOV DRIVEMASK, #0F0H
		LJMP HERE
	LPD:
		CJNE A, #POWERTDRV, LSH
		MOV DRIVEMASK, #0FFH
		LJMP HERE
	LSH:
		CJNE A, #SHUTDOWN, COMMANDNOTFOUND
		CLR EX0						; Stop receiving further comments
		CLR EX1						; Stop receiving further comments
		ACALL PAUSEMOTOR			; Stop motor operation
		ACALL DELAY2MIN				; Wait for raspberry pi to shut-down
		CLR RELAY					; Turn of relay
		ACALL DELAYPULSE			; Wait for 3 seconds and self kill
		ACALL DELAYPULSE
		ACALL DELAYPULSE
	COMMANDNOTFOUND:
		LJMP HERE

END
