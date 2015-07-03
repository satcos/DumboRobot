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


						
; ===============================================================================
; Code begins here
; ===============================================================================
CSEG            
ORG	0000H							; Reset
	JMP MAIN
	
; ===============================================================================
; MAIN: Main program
; Blinks Led to check controller functionality
; ===============================================================================
MAIN:
	SETB LED
	LOOP1:
		MOV R1, #0005H
		LOOP2:
			MOV R2, #00FFH
			LOOP3:
				MOV R3, #00FFH
				DJNZ R3, $							; Waste Time to sync second bit
				DJNZ R2, LOOP3
			DJNZ R1, LOOP2						; Waste Time to sync second bit
	CPL LED
	JMP LOOP1
