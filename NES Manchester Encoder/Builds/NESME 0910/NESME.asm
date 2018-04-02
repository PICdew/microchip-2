;==================================================================================================
;====================================  NES Joystic Decoder 1.0 ====================================
;================================== DERKACH OLEXANDR DEVELOPMENT ==================================
;========================================= (c) 2012 Alche =========================================
;=========================================  alche@ukr.net =========================================
;==================================================================================================
;05.07.12 Добавлена перекодировка в формат DIY-RC
;06.07.12 Добавлен маячек для визуального контроля
 #include	<P12F675.inc>				;файл стандартных определений

__CONFIG _INTRC_OSC_NOCLKOUT & _WDT_OFF & _PWRTE_ON & _MCLRE_OFF & _CP_OFF & _CPD_OFF

;==================================================================================================
;==================================== Раздел описания констант ====================================
;==================================================================================================
	#DEFINE OUT			GPIO,0			;Вывод результата
	#DEFINE CLK			GPIO,1			;Вывод синхроимпульса
	#DEFINE LATCH		GPIO,2			;Вывод записи в регистр
	#DEFINE DATAIN		GPIO,3			;Ввод даных


	
	;#DEFINE LED			GPIO,4			;Вывод подключения светодиода
	#DEFINE MODE_INV					;Результат (1ый бит слева = MODE_NORM, справа=MODE_INV)
	CBLOCK	0x020

	
	cod
	cnt									;Ячейка счета
	cnt1								;Ячейка счета в манчестеровских процедурах
	cnt2								;Ячейка счета в манчестеровских процедурах
	cnt3								;Ячейка счета для перекодировки в формат DIY-RC
	ncnt								;Ячейка счета в манчестере	
	temp								;Временная ячейка 1
	temp1								;Временная ячейка 2
	temp3
	tcnt								;Ячейка счета в манчестере
	rezult								;Ячейка промежуточного результата
	sum									;Ячайка для счета CRC в манчестере
	bt									;Ячейка временного буфера передачи в манчестере
	mtx_delay							;Ячейка длительности передаваемого импульса

	Reg_1
	Reg_2
	Reg_3
	Reg_4

	mtx_buffer							;Ячейка для передачи передается номер пульта +1 = передается код кнопки


	ENDC

	TXFLAG	equ	0x02				; 1 = TX in progress
	TXPIN   equ     h'05'           ; TXPIN = GP5 (pin 2) on RGBX board
    packet_len	EQU 2


SHORTPAUSE macro
	movlw	0xFF
	movwf	temp
	decfsz	temp
	goto	$-1
 endm


org 0x000
	goto	START
;==================================================================================================
;==================================== Начальная  инициализация ====================================
;==================================================================================================
START
	clrf	INTCON						;Очистка регистра прерываний
	bsf		STATUS,RP0   				;Банк 1
	call	0x3FF						;Считаем калибровочную константу
	movwf	OSCCAL						;Поместим в регистр
	movlw	b'00000000'					;Значение для регистра OPTION
	movwf	OPTION_REG					;Поместили значение в регистр OPTION
  	bcf		STATUS,RP0					;Вернулись в Банк 0
	clrf	GPIO						;Очистили порт
	movlw	b'00000111'					;Значение для конфигурации компаратора (отключаем)
	movwf	CMCON						;Поместили в регистр конфигурации компаратора

	bsf		STATUS,RP0					;Переходим в банк 1
	movlw	b'00010000'					;Слово конфигурации для ANSEL, FOsc/2 GP0 аналоговый вход
	movwf	ANSEL						;Поместили слово в регистр
	movlw	b'00000000'					;GP4 вход, остальные выходы
	movwf	TRISIO						;Поместили в регистр конфигурации входов/выходов
	movlw	b'00010110'					;Слово конфигурации для WPU 
	movwf	WPU							;Включили подтягивающие резисторы

	bcf		STATUS,RP0					;Вернулись в банк 0
	movlw	b'10000001'					;Слово конфигурации для ADCON
	movwf	ADCON0						;Поместили слово в регистр
	clrf	mtx_buffer
	clrf	tcnt

	movlw	0x01						;для теста
	movwf	mtx_buffer+1				;для теста

	 bsf         GPIO,5

	call	HELLOWORLD
	call	HELLOWORLD

;	call	TESTSENDOK					;Побитная посылка
;	goto	TESTSEND2					;Посылка с мтх буфером и процедурами OUTBYTE,
	;goto	TESTSEND3					;Посылка с мтх буфером

INIT
	bcf		OUT
	call	PAUSE
	clrf	rezult						;Очистили ячейку результата			
	bcf		STATUS,C					;Сбросили флаг переноса после предыдущих операций для коректности переноса
	bsf		CLK							;Установили 1 на выводе тактирования сдвигового регистра
	call	PAUSE
	bsf		LATCH						;Дали команду регистру считать состояние выводов
	call	PAUSE
	bcf		LATCH						;Установили 0 на выводе PS
	call	PAUSE

OPROS
	movlw	0x08						;Количество проходов для считывания выхода регистра
	movwf	cnt							;Поместили во временную ячейку счета
TAKTLOOP
	call	TAKT						;Будем тактировать вывод и считать результат
	decfsz	cnt							;Декримент ячейки счети
	goto	TAKTLOOP					;Если не 0 то на начало цикла
	incf	rezult						;Иначе инкриментируем результат
	decfsz	rezult						;Теперь декриментируем
 	goto	OUTREZULT					;Если резуьтат не ноль то будем его выводить
	goto	INIT						;Иначе будем опрашивать снова

TAKT
#ifdef MODE_INV							;Если указан режим INV
	rlf		rezult						;То будем сдвигать результат влево
endif									;Конец если

#ifdef MODE_NORM						;Если указан режим NORM
	rrf		rezult						;то будем сдвигать результат вправо
endif									;конец если

	bcf		STATUS,C					;Очистили флаг переноса
	bsf		CLK							;Установим 1 на выводе сдвига регистра
	call	PAUSE						;Небольшая пауза, даем время установиться 
	btfss	DATAIN						;Проверим состояние входа если пришел 0 

#ifdef MODE_INV							;Если указан режим INV
	bsf		rezult,0					;то установим нулевой бит регистра результата в 1
endif									;конец если

#ifdef MODE_NORM						;Если указан режим NORM
	bsf		rezult,7					;то установим седьмой бит регистра результата в 1
endif									;конец если

	bcf		CLK							;Установим 0 на выводе сдвига регистра
	call	PAUSE
 return									;и возвращаемся

OUTREZULT
	movfw	rezult						;Поместили в рабочий регистр результат
	movwf	cnt							;Рабочий регистр во временную ячейку счета
OUTLOOP
	bcf		OUT							;Установим 0 на выходе
	bsf		OUT							;установим 1 на выходе
	decfsz	cnt							;Уменьшим счетчик на 1, если счетчик не 0
	goto	OUTLOOP						;то на начало цикла
	clrf	cod
	call	ENCODE						;Вызовем кодер посылки (для DIY-RC Project)
    movwf	cod
    movwf   (mtx_buffer+1)
	
	movlw	0x40
	addwf	tcnt,F
	movwf	Reg_3
	call	TX	


	movfw	tcnt
	movwf	Reg_3
	call	TX

	movf	(mtx_buffer+1),w
	
	andlw   0x3F
	iorwf   tcnt,W
	movwf   (mtx_buffer+1)
	
;	movwf	Reg_4
;	call	RS232SEND

;	movfw	rezult						;Поместили результ в w	
;	movwf	mtx_buffer+1				;Перенесли w в буферотправки+1
;	movf    (mtx_buffer+1),W		
;	andlw   0x3F
;	iorwf   tcnt,W
;	movwf   (mtx_buffer+1)

;	movfw	rezult
;	movwf	temp3
;	call	PAUSE
;	call	HEADERTS
;	decfsz	temp3
;	goto	$-3

	
;	call	PAUSE
;	call	PAUSE


	movlw	0x05						;Количество повторных отправок
	movwf	temp						;в ячейку счета
	call	MANCHESTER					;Выводим код
	decfsz	temp						;Уменьшим и если не 0
	goto	$-2							;то зациклимся

;	movfw	rezult
;	movlw	0x40
;	addwf	(mtx_buffer+1),F

;	movfw	rezult
;	movwf	cnt
   	goto	INIT



ENCODE											;Кодировка под DIY-RC (кнопки номеруются от 1 до 8)
	movlw	0x08								;Счетчик циклов
	movwf	cnt									;Ячейка счета
	clrw										;Очистили рабочий регистр, в него будем помещать результат
	clrf	cnt3								;Ячейка счета кнопок
SUM
	incf	cnt3								;Инкремент счетчика 
	btfsc	rezult,0							;Если нулевой бит равен 1
	addwf	cnt3,0								;тогда суммируем значения счетчика кнопок и рабочего регистра
	rrf		rezult								;Сдвигаем вправо резултат
	decfsz	cnt									;Декримент счетчика цикла
	goto	SUM									;Если не 0 то зациклимся

 return											;Возвращаемся
;==================================================================================================
;========================================= MANCHESTER =============================================
;==================================================================================================
MANCHESTER
mtx_init
	movlw   0xA0						;Значение длительности импульсов 
	movlw   0x75						;Значение длительности для СИМУЛЯЦИИ
	movwf   mtx_delay					;Поместили в регистр

HEADER									;Посылка заголовка
	movlw   0x14						;Количество единиц в заголовке
	movwf   cnt2						;Ячейка для счета
head0									;Начинаем посылку
	call    BIT1						;Отправим 1
	decfsz  cnt2,F						;уменшим счетчик и если не ноль
	goto    head0						;перейдем на начало цикла
	call    BIT0						;иначе отправим 0
	movlw	mtx_buffer					;
	movwf   FSR         
	movlw	packet_len        
	movwf	cnt1     
	movlw	0xFF        
	movwf   sum     
outbu0 
	movf    INDF,W						;w=0(mtx),41(mtx+1),0,41,0,41 (содержимое ячеек)
	call    UPDATE_SUM					
	movf    INDF,W						;w=AC,8D,AC,
	call    OUTBYTE						;w=0,41,0,41,0,41
	incf    FSR,F       
	decfsz  cnt1,F   
	goto    outbu0     
	movf    sum,W   
	call    OUTBYTE     
 return              

OUTBYTE
	movwf   bt    
	movlw   0x08        
	movwf   cnt2     
outby0 
	rlf     bt,F   
	btfsc   STATUS,C    
	goto    outby1     
	call    BIT0    
	goto    outby2     
outby1
	call    BIT1     
outby2 
	decfsz  cnt2,F   
	goto    outby0     
	call    BIT1    

BIT0
	bsf		OUT
ndelaya0       
	movf    mtx_delay,W   
	movwf   ncnt     
ndelaya1
	decfsz  ncnt,F   
	goto    ndelaya1
	bcf		OUT
ndelayb0    
	movf    mtx_delay,W   
	movwf   ncnt     
ndelayb1
	decfsz  ncnt,F   
	goto    ndelayb1
 return            

BIT1
	bcf		OUT
ndelayc0
	movf    mtx_delay,W
	movwf   ncnt
ndelayc1
	decfsz  ncnt,F
	goto    ndelayc1
	bsf		OUT
ndelaye0
	movf    mtx_delay,W
	movwf   ncnt
ndelaye1
	decfsz  ncnt,F
	goto    ndelaye1
 return 

UPDATE_SUM
	xorwf   sum,F   
	clrw                
	btfsc   sum,7   
	xorlw   0x7A        
	btfsc   sum,6   
	xorlw   0x3D        
	btfsc   sum,5   
	xorlw   0x86        
	btfsc   sum,4   
	xorlw   0x43        
	btfsc   sum,3   
	xorlw   0xB9        
	btfsc   sum,2   
	xorlw   0xC4        
	btfsc   sum,1   
	xorlw   0x62        
	btfsc   sum,0   
	xorlw   0x31        
	movwf   sum   
 return  



PAUSE
	movlw	0x0F
	movwf	temp1
	movwf	temp
	decfsz	temp
	goto	$-1
	decfsz	temp1
	goto $-4
return

HELLOWORLD
	movlw	"H"
	movwf	Reg_3
	call	TX
	movlw	"E"
	movwf	Reg_3
	call	TX
	movlw	"L"
	movwf	Reg_3
	call	TX
	movlw	"L"
	movwf	Reg_3
	call	TX
	movlw	"O"
	movwf	Reg_3
	call	TX
	
	movlw	0x0D
	movwf	Reg_3
	call	TX

	movlw	0x0A
	movwf	Reg_3
	call	TX
return

RS232SEND
	swapf	Reg_4,F	
	movlw	b'00001111'
	andwf	Reg_4,w
	call	ENCODER
	movwf	Reg_3
	call	TX

	swapf	Reg_4,F	
	movlw	b'00001111'
	andwf	Reg_4,w
	call	ENCODER
	movwf	Reg_3
	call	TX

	movlw	0x0D
	movwf	Reg_3
	call	TX

	movlw	0x0A
	movwf	Reg_3
	call	TX

	return
ENCODER
	addwf	PCL,F
	retlw	"0"
	retlw	"1"
	retlw	"2"
	retlw	"3"
	retlw	"4"
	retlw	"5"
	retlw	"6"
	retlw	"7"
	retlw	"8"
	retlw	"9"
	retlw	"A"
	retlw	"B"
	retlw	"C"
	retlw	"D"
	retlw	"E"
	retlw	"F"



TX

	
 	movlw       .9          ; 8+1, т.е + бит C из STATUS
	movwf       Reg_2
	bcf         STATUS,C    ; подготовка стартового бита
m1 	
    btfsc       STATUS,C
	goto        bit1
	goto        bit0
bit1 
    bsf         GPIO,5     ; передача единицы
	call        Pause
	goto        m2
bit0
    bcf         GPIO,5     ; передача нуля
	call        Pause
	goto        m2
m2  
    rrf         Reg_3,F     ; сдвиг вправо для передачи с младшего бита
	decfsz      Reg_2,F
	goto        m1
	bsf         GPIO,5     ; установка 1 - "режим ожидания"
	call        Pause
return
	
Pause       movlw       .31
            movwf       Reg_1
wr          decfsz      Reg_1, F
            goto        wr
            nop
            return


















HEADERTS
	movlw   0x14						;Количество единиц в заголовке
	movwf   cnt2						;Ячейка для счета
head0ts									;Начинаем посылку
	call    BIT1						;Отправим 1
	decfsz  cnt2,F						;уменшим счетчик и если не ноль
	goto    head0ts						;перейдем на начало цикла
	call    BIT0						;иначе отправим 0
	return

OUTBYTETS
	movwf   bt    
	movlw   0x08        
	movwf   cnt2     
outby0ts 
	rlf     bt,F   
	btfsc   STATUS,C    
	goto    outby1ts     
	call    BIT0    
	goto    outby2ts     
outby1ts
	call    BIT1     
outby2ts
	decfsz  cnt2,F   
	goto    outby0ts
	call    BIT1  
	call    BIT0  
return

TESTSEND	
	movlw	0x41
	movwf	mtx_buffer+1

T1
				movlw	0xFF
				movwf	cnt
				decfsz	cnt
				goto	$-1
				movlw	0xFF
				movwf	cnt
				decfsz	cnt
				goto	$-1
				movlw	0xFF
				movwf	cnt
				decfsz	cnt
				goto	$-1
				movlw	0xFF
				movwf	cnt
				decfsz	cnt
				goto	$-1
				movlw	0xFF
				movwf	cnt
				decfsz	cnt
				goto	$-1
	call	MANCHESTER
	call	MANCHESTER
	call	MANCHESTER
	call	MANCHESTER
	call	MANCHESTER
	movlw	0x40
	addwf	mtx_buffer+1
	goto	T1
	goto	TESTSEND


TESTSEND2
				movlw   0x85        
        		movwf   mtx_delay  
				movlw	0x41
				movwf	mtx_buffer+1
 

TS2TS1
				movlw	0x05
				movwf	cnt
				call	HEADERTS
TS2byte1_1										;mtx_buffer+1 = 0x00
				movfw	mtx_buffer
				call	OUTBYTE
TS2byte1_2										;mtx_buffer+1 = 0x41
				movfw	mtx_buffer+1
				call	OUTBYTE
TS2byte1_3									;sum = 			0x8D
				movlw	0x8D
				call	OUTBYTE
				decfsz	cnt
				goto	TS2TS1 

				movlw	0x40
				addwf	mtx_buffer+1

				movlw	0x05
				movwf	cnt
TS2TS2
				call	HEADERTS
TS2byte2_1									;mtx_buffer+1 = 0x00
				movfw	mtx_buffer
				call	OUTBYTE
TS2byte2_2									;mtx_buffer+1 =	0x81
				movfw	mtx_buffer+1
				call	OUTBYTE
TS2byte2_3									;sum = 			0xCA
				movlw	0xCA
				call	OUTBYTE
				decfsz	cnt
				goto 	TS2TS2 

				movlw	0x40
				addwf	mtx_buffer+1

				movlw	0x05
				movwf	cnt
TS2TS3
				call	HEADERTS
TS2byte3_1									;mtx_buffer+1 = 0x00
				movfw	mtx_buffer
				call	OUTBYTE
TS2byte3_2									;mtx_buffer+1 =	0xC1
				movfw	mtx_buffer+1
				call	OUTBYTE
TS2byte3_3									;sum = 			0xF7
				movlw	0xF7
				call	OUTBYTE
				decfsz	cnt
				goto	TS2TS3

				movlw	0x40
				addwf	mtx_buffer+1

				movlw	0x05
				movwf	cnt
TS2TS4
				call	HEADERTS
TS2byte4_1									;mtx_buffer = 0x00
				movfw	mtx_buffer
				call	OUTBYTE
TS2byte4_2									;mtx_buffer+1 =	0x01
				movfw	mtx_buffer+1
				call	OUTBYTE
TS2byte4_3									;sum = 			0xB0
				movlw	0xB0
				call	OUTBYTE
				decfsz	cnt
				goto	TS2TS4

				movlw	0x40
				addwf	mtx_buffer+1

				goto TS2TS1





TESTSEND3
				movlw   0x85        
       		movwf   mtx_delay   
				movlw	0x05
				movwf	cnt
TS1
				call	HEADERTS
byte1_1										;mtx_buffer+1 = 0x00
				movlw	0x00
				call	OUTBYTETS
byte1_2										;mtx_buffer+1 = 0x41
				movlw	0x41
				call	OUTBYTETS
byte1_3									;sum = 			0x8D
				movlw	0x8D
				call	OUTBYTETS
				decfsz	cnt
				goto	TS1 



				movlw	0x05
				movwf	cnt
TS2
				call	HEADERTS
byte2_1									;mtx_buffer+1 = 0x00
				movlw	0x00
				call	OUTBYTETS
byte2_2									;mtx_buffer+1 =	0x81
				movlw	0x81
				call	OUTBYTETS
byte2_3									;sum = 			0xCA
				movlw	0xCA
				call	OUTBYTETS
				decfsz	cnt
				goto 	TS2 



				movlw	0x05
				movwf	cnt
TS3
				call	HEADERTS
byte3_1									;mtx_buffer+1 = 0x00
				movlw	0x00
				call	OUTBYTETS
byte3_2									;mtx_buffer+1 =	0xC1
				movlw	0xC1
				call	OUTBYTETS
byte3_3									;sum = 			0xF7
				movlw	0xF7
				call	OUTBYTETS
				decfsz	cnt
				goto	TS3

				movlw	0x05
				movwf	cnt
				
TS4
				call	HEADERTS
byte4_1									;mtx_buffer = 0x00
				movlw	0x00
				call	OUTBYTETS
byte4_2									;mtx_buffer+1 =	0x01
				movlw	0x01
				call	OUTBYTETS
byte4_3									;sum = 			0xB0
				movlw	0xB0
				call	OUTBYTETS
				decfsz	cnt
				goto	TS4
;				goto TESTSEND3
				return

TESTSENDOK
				movlw	0xFF
				movwf	cnt
				decfsz	cnt
				goto	$-1
				movlw	0xFF
				movwf	cnt
				decfsz	cnt
				goto	$-1
				movlw	0xFF
				movwf	cnt
				decfsz	cnt
				goto	$-1
				movlw	0xFF
				movwf	cnt
				decfsz	cnt
				goto	$-1
				movlw	0xFF
				movwf	cnt
				decfsz	cnt
				goto	$-1
				movlw   0x85        
        		movwf   mtx_delay   
				movlw	0x05
				movwf	cnt
TS1OK
				call 	BIT1;1
				call 	BIT1;2
				call 	BIT1;3
				call 	BIT1;4
				call 	BIT1;5
				call 	BIT1;6
				call 	BIT1;7
				call 	BIT1;8
				call 	BIT1;9
				call 	BIT1;10
				call 	BIT1;11
				call 	BIT1;12
				call 	BIT1;13
				call 	BIT1;14
				call 	BIT1;15
				call 	BIT1;16
				call 	BIT1;17
				call 	BIT1;18
				call 	BIT1;19

				call 	BIT1;20
				call 	BIT0;21
byte1_1ok
				call 	BIT0;22
				call 	BIT0;23
				call 	BIT0;24
				call 	BIT0;25
				call 	BIT0;26
				call 	BIT0;27
				call 	BIT0;28
				call 	BIT0;29
							
				call 	BIT1;30
				call 	BIT0;31
byte1_2ok
				call 	BIT0;32
				call 	BIT1;33
				call 	BIT0;34
				call 	BIT0;35
				call 	BIT0;36
				call 	BIT0;37
				call 	BIT0;38
				call 	BIT1;39

				call 	BIT1;40
				call 	BIT0;41
byte1_3ok								;sum = 			0x8D
				call 	BIT1;42
				call 	BIT0;43
				call 	BIT0;44
				call 	BIT0;45
				call 	BIT1;46
				call 	BIT1;47
				call 	BIT0;48
				call 	BIT1;49

				call 	BIT1;50
				call 	BIT0;51

				decfsz	cnt
				goto	TS1OK 


	
				movlw	0x05
				movwf	cnt
TS2OK
				call 	BIT1;1
				call 	BIT1;2
				call 	BIT1;3
				call 	BIT1;4
				call 	BIT1;5
				call 	BIT1;6
				call 	BIT1;7
				call 	BIT1;8
				call 	BIT1;9
				call 	BIT1;10
				call 	BIT1;11
				call 	BIT1;12
				call 	BIT1;13
				call 	BIT1;14
				call 	BIT1;15
				call 	BIT1;16
				call 	BIT1;17
				call 	BIT1;18
				call 	BIT1;19

				call 	BIT1;20
				call 	BIT0;21
byte2_1ok
				call 	BIT0;22
				call 	BIT0;23
				call 	BIT0;24
				call 	BIT0;25
				call 	BIT0;26
				call 	BIT0;27
				call 	BIT0;28
				call 	BIT0;29
							
				call 	BIT1;30
				call 	BIT0;31
byte2_2ok								;mtx_buffer+1 =	0x81
				call 	BIT1;32
				call 	BIT0;33
				call 	BIT0;34
				call 	BIT0;35
				call 	BIT0;36
				call 	BIT0;37
				call 	BIT0;38
				call 	BIT1;39

				call 	BIT1;40
				call 	BIT0;41
byte2_3ok								;sum = 			0xCA
				call 	BIT1;42
				call 	BIT1;43
				call 	BIT0;44
				call 	BIT0;45
				call 	BIT1;46
				call 	BIT0;47
				call 	BIT1;48
				call 	BIT0;49

				call 	BIT1;50
				call 	BIT0;51

				decfsz	cnt
				goto TS2OK

				movlw	0x05
				movwf	cnt
TS3OK
				call 	BIT1;1
				call 	BIT1;2
				call 	BIT1;3
				call 	BIT1;4
				call 	BIT1;5
				call 	BIT1;6
				call 	BIT1;7
				call 	BIT1;8
				call 	BIT1;9
				call 	BIT1;10
				call 	BIT1;11
				call 	BIT1;12
				call 	BIT1;13
				call 	BIT1;14
				call 	BIT1;15
				call 	BIT1;16
				call 	BIT1;17
				call 	BIT1;18
				call 	BIT1;19

				call 	BIT1;20
				call 	BIT0;21
byte3_1ok
				call 	BIT0;22
				call 	BIT0;23
				call 	BIT0;24
				call 	BIT0;25
				call 	BIT0;26
				call 	BIT0;27
				call 	BIT0;28
				call 	BIT0;29
							
				call 	BIT1;30
				call 	BIT0;31
byte3_2ok								;mtx_buffer+1 =	0xC1
				call 	BIT1;32
				call 	BIT1;33
				call 	BIT0;34
				call 	BIT0;35
				call 	BIT0;36
				call 	BIT0;37
				call 	BIT0;38
				call 	BIT1;39

				call 	BIT1;40
				call 	BIT0;41
byte3_3ok								;sum = 			0xF7
				call 	BIT1;42
				call 	BIT1;43
				call 	BIT1;44
				call 	BIT1;45
				call 	BIT0;46
				call 	BIT1;47
				call 	BIT1;48
				call 	BIT1;49

				call 	BIT1;50
				call 	BIT0;51
				decfsz	cnt
				goto	TS3OK


				movlw	0x05
				movwf	cnt
TS4OK
				call 	BIT1;1
				call 	BIT1;2
				call 	BIT1;3
				call 	BIT1;4
				call 	BIT1;5
				call 	BIT1;6
				call 	BIT1;7
				call 	BIT1;8
				call 	BIT1;9
				call 	BIT1;10
				call 	BIT1;11
				call 	BIT1;12
				call 	BIT1;13
				call 	BIT1;14
				call 	BIT1;15
				call 	BIT1;16
				call 	BIT1;17
				call 	BIT1;18
				call 	BIT1;19

				call 	BIT1;20
				call 	BIT0;21
byte4_1ok
				call 	BIT0;22
				call 	BIT0;23
				call 	BIT0;24
				call 	BIT0;25
				call 	BIT0;26
				call 	BIT0;27
				call 	BIT0;28
				call 	BIT0;29
							
				call 	BIT1;30
				call 	BIT0;31
byte4_2ok								;mtx_buffer+1 =	0x01
				call 	BIT0;32
				call 	BIT0;33
				call 	BIT0;34
				call 	BIT0;35
				call 	BIT0;36
				call 	BIT0;37
				call 	BIT0;38
				call 	BIT1;39

				call 	BIT1;40
				call 	BIT0;41
byte4_3ok								;sum = 			0xB0
				call 	BIT1;42
				call 	BIT0;43
				call 	BIT1;44
				call 	BIT1;45
				call 	BIT0;46
				call 	BIT0;47
				call 	BIT0;48
				call 	BIT0;49

				call 	BIT1;50
				call 	BIT0;51
				decfsz	cnt
				goto	TS4OK
return

	goto TESTSENDOK











org 0x3FF
	retlw 0x3424
 end

