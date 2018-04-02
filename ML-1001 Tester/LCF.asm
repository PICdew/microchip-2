;====================================================================================================
;========================================= ML-1001 TESTER ===========================================
;====================================================================================================
#include<P16F84a.inc>		;���� ����������� �����������
 __CONFIG 3FF9	;������������: WDT �������, PWRTE �������, �������� ��������� HS

;  �������� ������
	#DEFINE 	DIN		 	PORTA, 0		;����������� ������ ������
	#DEFINE 	DCLK 		PORTA, 1		;����� ����������� ���������� ���������
	#DEFINE 	LOAD 		PORTA, 2		;����� ����������� ������� ��������

;  �������� ��������
	cblock 	0x10 							;��������� �����
	LCDDATA									;����� ��� ������ �� �������
	LOOPCNT
	temp
	cntmsec 			;used in delay routine
	cnt_1
	cnt_2
	cnt_3
	Nsec

	endc



STROB	macro
	bsf	DCLK
;	call	DELAY_1sec
	bcf	DCLK
endm
LOADD	macro
	bsf	LOAD
;	call	DELAY_1sec
	bcf	LOAD
endm


org 0x000
	goto START




;====================================================================================================
;================================== ������������� ������ ���������� =================================
;====================================================================================================

START
   	bsf		STATUS,RP0	    ;�������� ���� 1
   	movlw	B'00000000'	    ;RA0 �� ����  - ��� �� �����
   	movwf	TRISA		    ;
   	movlw	B'00000001'	    ;RB0 -  �� ����
   	movwf	TRISB		    ;RB1...RB7 �� �����
    bsf		OPTION_REG,NOT_RBPU ;����������� ��������� ��������
   	bcf		STATUS,RP0	    ;����� ���� 0

	BSF INTCON, RBIE; ���������� ���������� �� ������ RB7:RB4
	bsf INTCON,INTE
	bsf OPTION_REG,INTEDG
    BSF INTCON, GIE			;��������� ����������
   	clrf		PORTA		    ;����������� ���� A
   	clrf		PORTB		    ;����������� ���� �


 	movlw		.8;
	movwf		LOOPCNT
LOOP
	movfw		LOOPCNT
	call		DECODE
	movwf		LCDDATA
LCDSTART	
	bcf			LOAD
	bcf			DIN
	STROB
	movlw		0x08
	movwf		temp
TOLCD
	btfss		LCDDATA,0
	bcf			DIN				;DOT SEG
	btfsc		LCDDATA,0
	bsf			DIN
	STROB
	rrf			LCDDATA
	decfsz		temp
	goto		TOLCD
	LOADD
	decfsz		LOOPCNT
	goto		LOOP
	nop
	goto		$-1


DECODE

	addwf	PCL,F			;��������� � PCL �������� ��������� �����
			 ;DEGFABCT
 	retlw	B'11011110'		;����� "0"
 	retlw	B'00000110'		;����� "1"
 	retlw	B'11101100'		;����� "2"
 	retlw	B'10101110'		;����� "3"
 	retlw	B'00110110'		;����� "4"
 	retlw	B'10111010'		;����� "5"
 	retlw	B'11111010'		;����� "6"
 	retlw	B'00001110'		;����� "7"
 	retlw	B'11111110'		;����� "8"
 	retlw	B'10111110'		;����� "9"
 	retlw   B'00011100'		;������ "t"
return

end
