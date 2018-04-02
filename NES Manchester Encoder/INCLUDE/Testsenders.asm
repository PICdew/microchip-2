
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











