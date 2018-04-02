;====================================================================================================
;========================================= ML-1001 TESTER ===========================================
;====================================================================================================
#include<P16F84a.inc>		;файл стандартных определений
 __CONFIG 3FF9	;конфигурация: WDT включен, PWRTE включен, тактовый генератор HS

;  Описание портов
	#DEFINE 	DIN		 	PORTA, 0		;Управляющий сигнал охраны
	#DEFINE 	DCLK 		PORTA, 1		;Вывод подключения индикатора состояния
	#DEFINE 	LOAD 		PORTA, 2		;Вывод подключения датчика скорости

;  Описание констант
	cblock 	0x10 							;Начальный адрес
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
;================================== Инициализация портов контролера =================================
;====================================================================================================

START
   	bsf		STATUS,RP0	    ;Включаем банк 1
   	movlw	B'00000000'	    ;RA0 на вход  - все на вывод
   	movwf	TRISA		    ;
   	movlw	B'00000001'	    ;RB0 -  на ввод
   	movwf	TRISB		    ;RB1...RB7 на вывод
    bsf		OPTION_REG,NOT_RBPU ;Нагрузочные резисторы включены
   	bcf		STATUS,RP0	    ;Снова банк 0

	BSF INTCON, RBIE; разрешение прерываний по линиям RB7:RB4
	bsf INTCON,INTE
	bsf OPTION_REG,INTEDG
    BSF INTCON, GIE			;Разрешаем прерывания
   	clrf		PORTA		    ;Настраиваем порт A
   	clrf		PORTB		    ;Настраиваем порт В

	
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
