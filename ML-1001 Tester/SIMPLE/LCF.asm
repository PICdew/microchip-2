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
	cntmsec 			;used in delay routine
	cnt_1
	cnt_2
	cnt_3
	Nsec

	endc



STROB	macro
	bsf	DCLK
	bcf	DCLK
endm
LOADD	macro
	bsf	LOAD
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

	
	bcf			LOAD

	STROB
	bcf			DIN				;DOT SEG
	STROB
	bcf			DIN				;TRI SEG
	STROB
	bsf			DIN				;C SEG
	STROB
	bsf			DIN				;B SEG
	STROB	
	bcf			DIN				;A SEG
	STROB
	bcf			DIN				;F SEG
	STROB
	bcf			DIN				;G SEG
	STROB
	bcf			DIN				;E SEG
	STROB
	bcf			DIN				;D SEG
	STROB
	LOADD
	

	bcf			DIN				;DOT SEG
	STROB
	bcf			DIN				;TRI SEG
	STROB
	bsf			DIN				;C SEG
	STROB
	bsf			DIN				;B SEG
	STROB	
	bcf			DIN				;A SEG
	STROB
	bcf			DIN				;F SEG
	STROB
	bcf			DIN				;G SEG
	STROB
	bcf			DIN				;E SEG
	STROB
	bcf			DIN				;D SEG
	STROB
	LOADD
;	bsf			DIN
;	STROB
;	LOADD

;	call		DELAY_1sec

;	bsf			CLK
;	call		DELAY_1sec
;	bcf			CLK
;	call		DELAY_1sec
;	bsf			CLK
;	call		DELAY_1sec
;	bcf			CLK
;	call		DELAY_1sec
;	bsf			CLK
;	bSf			HK
	nop
	goto	$-1
	

end
