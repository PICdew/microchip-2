;==================================================================================================
;====================================  NES Joystic Decoder 1.0 ====================================
;================================== DERKACH OLEXANDR DEVELOPMENT ==================================
;========================================= (c) 2012 Alche =========================================
;=========================================  alche@ukr.net =========================================
;==================================================================================================
 #include	<P12F675.inc>					;���� ����������� �����������

 __CONFIG _INTRC_OSC_NOCLKOUT & _WDT_OFF & _PWRTE_ON & _MCLRE_OFF & _CP_OFF & _CPD_OFF

;==================================================================================================
;==================================== ������ �������� �������� ====================================
;==================================================================================================
	#DEFINE OUT			GPIO,0				;����� ����������
	#DEFINE CLK			GPIO,1				;����� ��������������
	#DEFINE LATCH		GPIO,2				;����� ������ � �������
	#DEFINE DATAIN		GPIO,3				;���� �����
	#DEFINE MODE_INV						;��������� (1�� ��� ����� = MODE_NORM, ������=MODE_INV)
	
 CBLOCK	0x020
	cnt										;��������� ������ ����� 
	cnt1									;������ ����� � ��������������� ����������
	cnt2									;������ ����� � ��������������� ����������
	cnt3									;������ ����� ��� ������������� � ������ DIY-RC
	ncnt									;������ ����� � ����������	
	temp									;��������� ������ 1
	temp1									;��������� ������ 2
	tcnt									;������ ����� � ����������
	rezult									;������ �������������� ����������
	sum										;������ ��� ����� CRC � ����������
	bt										;������ ���������� ������ �������� � ����������
	mtx_delay								;������ ������������ ������������� ��������
	mtx_buffer								;������ ��� �������� ���������� ����� ������ +1 = ���������� ��� ������
 ENDC

    packet_len	EQU 2

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
		movlw	b'00000000'					;GP4 ����, ��������� ������
		movwf	TRISIO						;��������� � ������� ������������ ������/�������
		movlw	b'00010110'					;����� ������������ ��� WPU 
		movwf	WPU							;�������� ������������� ���������
		bcf		STATUS,RP0					;��������� � ���� 0
		movlw	b'10000001'					;����� ������������ ��� ADCON
		movwf	ADCON0						;��������� ����� � �������
		clrf	mtx_buffer					;�������� ����� ��������
		clrf	tcnt						;�������� ������ ����� �������� �������
	
INIT
		bcf		OUT
		call	PAUSE
		clrf	rezult						;�������� ������ ����������			
		bcf		STATUS,C					;�������� ���� �������� ����� ���������� �������� ��� ����������� ��������
		bsf		CLK							;���������� 1 �� ������ ������������ ���������� ��������
		call	PAUSE
		bsf		LATCH						;���� ������� �������� ������� ��������� �������
		call	PAUSE
		bcf		LATCH						;���������� 0 �� ������ PS
		call	PAUSE

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
		#ifdef MODE_INV						;���� ������ ����� INV
		 	rlf	rezult						;�� ����� �������� ��������� �����
		endif								;����� ����
	
		#ifdef MODE_NORM					;���� ������ ����� NORM
			rrf	rezult						;�� ����� �������� ��������� ������
		endif								;����� ����
	
		bcf		STATUS,C					;�������� ���� ��������
		bsf		CLK							;��������� 1 �� ������ ������ ��������
		call	PAUSE						;��������� �����, ���� ����� ������������ 
		btfss	DATAIN						;�������� ��������� ����� ���� ������ 0 
	
		#ifdef MODE_INV						;���� ������ ����� INV
			bsf	rezult,0					;�� ��������� ������� ��� �������� ���������� � 1
		endif								;����� ����
	
		#ifdef MODE_NORM					;���� ������ ����� NORM
			bsf	rezult,7					;�� ��������� ������� ��� �������� ���������� � 1
		endif								;����� ����
	
		bcf		CLK							;��������� 0 �� ������ ������ ��������
		call	PAUSE
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

	    movwf   (mtx_buffer+1)
		movlw	0x40
		addwf	tcnt,F
		movf	(mtx_buffer+1),w
		andlw   0x3F
		iorwf   tcnt,W
		movwf   (mtx_buffer+1)
TRANSMIT	
		movlw	0x05						;���������� ��������� ��������
		movwf	temp						;� ������ �����
		call	MANCHESTER					;������� ���
		decfsz	temp						;�������� � ���� �� 0
		goto	$-2							;�� ����������
	   	goto	INIT						;������������ �� ������



ENCODE										;��������� ��� DIY-RC (������ ���������� �� 1 �� 8)
		movlw	0x08						;������� ������
		movwf	cnt							;������ �����
		clrw								;�������� ������� �������, � ���� ����� �������� ���������
		clrf	cnt3						;������ ����� ������
SUM
		incf	cnt3						;��������� �������� 
		btfsc	rezult,0					;���� ������� ��� ����� 1
		addwf	cnt3,0						;����� ��������� �������� �������� ������ � �������� ��������
		rrf		rezult						;�������� ������ ��������
		decfsz	cnt							;��������� �������� �����
		goto	SUM							;���� �� 0 �� ����������
	return									;������������
;==================================================================================================
;========================================= MANCHESTER =============================================
;==================================================================================================
MANCHESTER
mtx_init
		movlw   0xA0						;�������� ������������ ��������� 
		movlw   0x75						;�������� ������������ ��� ���������
		movwf   mtx_delay					;��������� � �������

HEADER										;������� ���������
		movlw   0x14						;���������� ������ � ���������
		movwf   cnt2						;������ ��� �����
head0										;�������� �������
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
		movf    INDF,W						;w=0(mtx),41(mtx+1),0,41,0,41 (���������� �����)
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

org 0x3FF
	retlw 0x3424
 end

