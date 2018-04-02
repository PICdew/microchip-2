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
	LCDDATA									;Число для вывода на дисплей
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

	addwf	PCL,F			;Добавляем к PCL значение выводимой цифры
			 ;DEGFABCT
 	retlw	B'11011110'		;Цифра "0"
 	retlw	B'00000110'		;Цифра "1"
 	retlw	B'11101100'		;Цифра "2"
 	retlw	B'10101110'		;Цифра "3"
 	retlw	B'00110110'		;Цифра "4"
 	retlw	B'10111010'		;Цифра "5"
 	retlw	B'11111010'		;Цифра "6"
 	retlw	B'00001110'		;Цифра "7"
 	retlw	B'11111110'		;Цифра "8"
 	retlw	B'10111110'		;Цифра "9"
 	retlw   B'00011100'		;Символ "t"
return

end
