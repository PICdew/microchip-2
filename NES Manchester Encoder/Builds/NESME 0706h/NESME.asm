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
	#DEFINE PRER		GPIO,4			;Ввод даных
	#DEFINE CLK			GPIO,5			;Вывод синхроимпульса
	#DEFINE PS			GPIO,2			;Вывод записи в регистр
	#DEFINE OUT			GPIO,1			;Вывод результата
	#DEFINE LED			GPIO,0			;Вывод подключения светодиода

	CBLOCK	0x020

	

	cnt									;Ячейка счета
	cnt1								;Ячейка счета в манчестеровских процедурах
	cnt2								;Ячейка счета в манчестеровских процедурах
	cnt3								;Ячейка счета для перекодировки в формат DIY-RC
	sum									;Ячайка для счета CRC в манчестере
	bt									;Ячейка временного буфера передачи в манчестере
	mtx_delay							;Ячейка длительности передаваемого импульса
	ncnt								;Ячейка счета в манчестере	
	temp								;Временная ячейка 1
	temp1								;Временная ячейка 2
	tcnt								;Ячейка счета в манчестере
	rezult								;Ячейка промежуточного результата
	mtx_buffer							;Ячейка для передачи передается номер пульта +1 = передается код кнопки
	
	ENDC

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
	movlw	b'00010000'					;GP4 вход, остальные выходы
	movwf	TRISIO						;Поместили в регистр конфигурации входов/выходов
	movlw	b'00010010'					;Слово конфигурации для WPU 
	movwf	WPU							;Включили подтягивающие резисторы

	bcf		STATUS,RP0					;Вернулись в банк 0
	movlw	b'10000001'					;Слово конфигурации для ADCON
	movwf	ADCON0						;Поместили слово в регистр
	
	movlw	0x03
	movwf	cnt
LEDBLINK
	bsf		LED
	call	PAUSE
	call	PAUSE
	bcf		LED
	call	PAUSE
	call	PAUSE
	decfsz	cnt
	goto	LEDBLINK

d
INIT
	bcf		OUT
	clrf	rezult						;Очистили ячейку результата			
	bcf		STATUS,C					;Сбросили флаг переноса после предыдущих операций для коректности переноса
	bsf		CLK							;Установили 1 на выводе тактирования сдвигового регистра
	bsf		PS							;Дали команду регистру считать состояние выводов
	SHORTPAUSE							;Небольшая задержка
	bcf		PS							;Установили 0 на выводе PS

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
	rrf		rezult						;Сдвинем результат влево
	bcf		STATUS,C					;Очистили флаг переноса
	bsf		CLK							;Установим 1 на выводе сдвига регистра
	btfss	PRER						;Проверим состояние входа
	bsf		rezult,7					;Если пришел 0 то установим нулевой бит регистра результата в 1
	bcf		CLK							;Установим 0 на выводе сдвига регистра
 return									;и возвращаемся

OUTREZULT
	movfw	rezult						;Поместили в рабочий регистр результат
	movwf	cnt							;Рабочий регистр во временную ячейку счета
OUTLOOP
	bcf		OUT							;Установим 0 на выходе
	bsf		OUT							;установим 1 на выходе
	decfsz	cnt							;Уменьшим счетчик на 1, если счетчик не 0
	goto	OUTLOOP						;то на начало цикла
	call	ENCODE						;Вызовем кодер посылки (для DIY-RC Project)
	movfw	rezult						;Поместили результ в w	
	movwf	mtx_buffer+1				;Перенесли w в буферотправки+1
	movf    (mtx_buffer+1),W		
	andlw   0x3F
	iorwf   tcnt,W
	movwf   (mtx_buffer+1)
	movlw	3							;Количество повторных отправок
	movwf	temp						;в ячейку счета
	call	MANCHESTER					;Выводим код
	decfsz	temp						;Уменьшим и если не 0
	goto	$-2							;то зациклимся
	movfw	rezult
	movlw	0x40
	addwf	tcnt,F

	movfw	rezult
	movwf	cnt
LEDBLINK2
	call	PAUSE
	call	PAUSE
	bsf		LED
	call	PAUSE
	call	PAUSE
	bcf		LED
	
	decfsz	cnt
	goto	LEDBLINK2
   	goto	INIT						;иначе возвращаемся в самое начало


;==================================================================================================
;========================================= MANCHESTER =============================================
;==================================================================================================
MANCHESTER
mtx_init
	movlw   0x75						;Значение длительности импульсов 
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
	movf    INDF,W						;w=FF,75,FF,75	
	call    UPDATE_SUM					;w=0,41,0,41,0,41 (содержимое ячеек)
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
	movwf	rezult								;Иначе поместим значение из W в rezult
 return											;Возвращаемся

PAUSE
	movlw	0xFF
	movwf	temp1
	movwf	temp
	decfsz	temp
	goto	$-1
	decfsz	temp1
	goto $-4
return


TESTSEND
				movlw   0x75        
        		movwf   mtx_delay   
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
;outbu0
;outbyteprohod1
byte1
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
;outbyteprohod2
byte2
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
;outbytebeforereturn
byte3
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
	
				call		PAUSE
				call		PAUSE
				call		PAUSE
				call		PAUSE
				call		PAUSE
				call		PAUSE
				call		PAUSE
				call		PAUSE
				call		PAUSE
				call		PAUSE
				call		PAUSE

	goto TESTSEND 


org 0x3FF
	retlw 0x3424
 end

