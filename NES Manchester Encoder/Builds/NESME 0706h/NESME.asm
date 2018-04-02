;==================================================================================================
;====================================  NES Joystic Decoder 1.0 ====================================
;================================== DERKACH OLEXANDR DEVELOPMENT ==================================
;========================================= (c) 2012 Alche =========================================
;=========================================  alche@ukr.net =========================================
;==================================================================================================
;05.07.12 ��������� ������������� � ������ DIY-RC
;06.07.12 �������� ������ ��� ����������� ��������
 #include	<P12F675.inc>				;���� ����������� �����������
__CONFIG _INTRC_OSC_NOCLKOUT & _WDT_OFF & _PWRTE_ON & _MCLRE_OFF & _CP_OFF & _CPD_OFF

;==================================================================================================
;==================================== ������ �������� �������� ====================================
;==================================================================================================
	#DEFINE PRER		GPIO,4			;���� �����
	#DEFINE CLK			GPIO,5			;����� ��������������
	#DEFINE PS			GPIO,2			;����� ������ � �������
	#DEFINE OUT			GPIO,1			;����� ����������
	#DEFINE LED			GPIO,0			;����� ����������� ����������

	CBLOCK	0x020

	

	cnt									;������ �����
	cnt1								;������ ����� � ��������������� ����������
	cnt2								;������ ����� � ��������������� ����������
	cnt3								;������ ����� ��� ������������� � ������ DIY-RC
	sum									;������ ��� ����� CRC � ����������
	bt									;������ ���������� ������ �������� � ����������
	mtx_delay							;������ ������������ ������������� ��������
	ncnt								;������ ����� � ����������	
	temp								;��������� ������ 1
	temp1								;��������� ������ 2
	tcnt								;������ ����� � ����������
	rezult								;������ �������������� ����������
	mtx_buffer							;������ ��� �������� ���������� ����� ������ +1 = ���������� ��� ������
	
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
;==================================== ���������  ������������� ====================================
;==================================================================================================
START
	clrf	INTCON						;������� �������� ����������
	bsf		STATUS,RP0   				;���� 1
	call	0x3FF						;������� ������������� ���������
	movwf	OSCCAL						;�������� � �������
	movlw	b'00000000'					;�������� ��� �������� OPTION
	movwf	OPTION_REG					;��������� �������� � ������� OPTION
  	bcf		STATUS,RP0					;��������� � ���� 0
	clrf	GPIO						;�������� ����
	movlw	b'00000111'					;�������� ��� ������������ ����������� (���������)
	movwf	CMCON						;��������� � ������� ������������ �����������

	bsf		STATUS,RP0					;��������� � ���� 1
	movlw	b'00010000'					;����� ������������ ��� ANSEL, FOsc/2 GP0 ���������� ����
	movwf	ANSEL						;��������� ����� � �������
	movlw	b'00010000'					;GP4 ����, ��������� ������
	movwf	TRISIO						;��������� � ������� ������������ ������/�������
	movlw	b'00010010'					;����� ������������ ��� WPU 
	movwf	WPU							;�������� ������������� ���������

	bcf		STATUS,RP0					;��������� � ���� 0
	movlw	b'10000001'					;����� ������������ ��� ADCON
	movwf	ADCON0						;��������� ����� � �������
	
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
	clrf	rezult						;�������� ������ ����������			
	bcf		STATUS,C					;�������� ���� �������� ����� ���������� �������� ��� ����������� ��������
	bsf		CLK							;���������� 1 �� ������ ������������ ���������� ��������
	bsf		PS							;���� ������� �������� ������� ��������� �������
	SHORTPAUSE							;��������� ��������
	bcf		PS							;���������� 0 �� ������ PS

OPROS
	movlw	0x08						;���������� �������� ��� ���������� ������ ��������
	movwf	cnt							;��������� �� ��������� ������ �����
TAKTLOOP
	call	TAKT						;����� ����������� ����� � ������� ���������
	decfsz	cnt							;��������� ������ �����
	goto	TAKTLOOP					;���� �� 0 �� �� ������ �����
	incf	rezult						;����� �������������� ���������
	decfsz	rezult						;������ ��������������
 	goto	OUTREZULT					;���� �������� �� ���� �� ����� ��� ��������
	goto	INIT						;����� ����� ���������� �����

TAKT
	rrf		rezult						;������� ��������� �����
	bcf		STATUS,C					;�������� ���� ��������
	bsf		CLK							;��������� 1 �� ������ ������ ��������
	btfss	PRER						;�������� ��������� �����
	bsf		rezult,7					;���� ������ 0 �� ��������� ������� ��� �������� ���������� � 1
	bcf		CLK							;��������� 0 �� ������ ������ ��������
 return									;� ������������

OUTREZULT
	movfw	rezult						;��������� � ������� ������� ���������
	movwf	cnt							;������� ������� �� ��������� ������ �����
OUTLOOP
	bcf		OUT							;��������� 0 �� ������
	bsf		OUT							;��������� 1 �� ������
	decfsz	cnt							;�������� ������� �� 1, ���� ������� �� 0
	goto	OUTLOOP						;�� �� ������ �����
	call	ENCODE						;������� ����� ������� (��� DIY-RC Project)
	movfw	rezult						;��������� ������� � w	
	movwf	mtx_buffer+1				;��������� w � �������������+1
	movf    (mtx_buffer+1),W		
	andlw   0x3F
	iorwf   tcnt,W
	movwf   (mtx_buffer+1)
	movlw	3							;���������� ��������� ��������
	movwf	temp						;� ������ �����
	call	MANCHESTER					;������� ���
	decfsz	temp						;�������� � ���� �� 0
	goto	$-2							;�� ����������
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
   	goto	INIT						;����� ������������ � ����� ������


;==================================================================================================
;========================================= MANCHESTER =============================================
;==================================================================================================
MANCHESTER
mtx_init
	movlw   0x75						;�������� ������������ ��������� 
	movwf   mtx_delay					;��������� � �������

HEADER									;������� ���������
	movlw   0x14						;���������� ������ � ���������
	movwf   cnt2						;������ ��� �����
head0									;�������� �������
	call    BIT1						;�������� 1
	decfsz  cnt2,F						;������� ������� � ���� �� ����
	goto    head0						;�������� �� ������ �����
	call    BIT0						;����� �������� 0
	movlw	mtx_buffer					;
	movwf   FSR         
	movlw	packet_len        
	movwf	cnt1     
	movlw	0xFF        
	movwf   sum     
outbu0 
	movf    INDF,W						;w=FF,75,FF,75	
	call    UPDATE_SUM					;w=0,41,0,41,0,41 (���������� �����)
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

ENCODE											;��������� ��� DIY-RC (������ ���������� �� 1 �� 8)
	movlw	0x08								;������� ������
	movwf	cnt									;������ �����
	clrw										;�������� ������� �������, � ���� ����� �������� ���������
	clrf	cnt3								;������ ����� ������
SUM
	incf	cnt3								;��������� �������� 
	btfsc	rezult,0							;���� ������� ��� ����� 1
	addwf	cnt3,0								;����� ��������� �������� �������� ������ � �������� ��������
	rrf		rezult								;�������� ������ ��������
	decfsz	cnt									;��������� �������� �����
	goto	SUM									;���� �� 0 �� ����������
	movwf	rezult								;����� �������� �������� �� W � rezult
 return											;������������

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

