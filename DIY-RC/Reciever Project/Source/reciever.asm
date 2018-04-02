;***   File generated automatically using PICUtil

;***************************
;*** Compiler Directives ***
;***************************

	;disable following compiler warnings
	errorlevel -224 ;Use of this instruction is not recommended
	errorlevel -302 ;Register in operand not in bank 0. Ensure that bank bits are correct
	errorlevel -220 ;Address exceeds maximum range for this processor


	__config 0x3F42



;***************************
;*** Program Variables   ***
;***************************
INDIRECT 	equ	0x00	; (used   2 times)
TMR0     	equ	0x01	; (used   2 times)
PCL      	equ	0x02	; (used   1 times)
STATUS   	equ	0x03	; (used  23 times)
FSR      	equ	0x04	; (used   6 times)
PORTA    	equ	0x05	; (used   7 times)
PORTB    	equ	0x06	; (used   4 times)
PCLATH   	equ	0x0A	; (used   3 times)
INTCON   	equ	0x0B	; (used   6 times)
hdrcntmin	EQU	0x0C	; minimum number of header bits to receive
hdrcntmax	EQU	0x10	; maximum number of header bits to receive
CMCCON   	equ	0x1F	; (used   1 times)
savew1  	equ	0x20	; (used   3 times)
savestatus  	equ	0x21	; (used   2 times)
savepclath  	equ	0x22	; (used   2 times)
savefsr  	equ	0x23	; (used   2 times)
bt  	equ	0x24	; (used   2 times)
expire_cnt  	equ	0x25	; (used   4 times)
cur_seq  	equ	0x26	; (used   4 times)
cur_ch  	equ	0x27	; (used   5 times)
cur_state  	equ	0x28	; (used   7 times)
bitcnt  	equ	0x29	; (used   7 times)
tmrval  	equ	0x2A	; (used  10 times)
;bt  	equ	0x2B	; (used  14 times)
flags  		equ	0x2C	; (used  14 times)
btcnt  		equ	0x2D	; (used   4 times)
mrx_buffer  equ	0x2E	; (used   1 times)
bnkd_2F  	equ	0x2F	; (used   5 times)
W	equ	0x0000
F	equ	0x0001
EXPIRE_TIMER	EQU 0x12
LATCH_MASK	EQU 0x00
packet_len	EQU	2

T		EQU	.39 ; half frame 350 usec (= T * 9 usec)

min_t		EQU	T/2  ; half frame (T) minimum time
min_2t		EQU	3*T/2 ; half frame (T) maximum time and full frame (2T) minimum time
max_2t		EQU	5*T/2 ; full frame (2T) maximum time


if_short_val	EQU	1 ; bit value of IF_SHORT flag
first_half_val	EQU	2 ; bit value of FIRST_HALF flag

;mrx_buffer	res	2
#define IF_SHORT flags, 0
#define FIRST_HALF flags, 1
#define HEADER flags, 2
#define VALID flags, 7


 
#define RXBIT PORTA, 5




;***************************
;*** Program Code        ***
;***************************

	org	0x0000
        goto    main     ; Warning--Code may not be reachable
        nop                 ; Warning--Code may not be reachable
        nop                 ; Warning--Code may not be reachable
        nop                 ; Warning--Code may not be reachable

;***************************
;*** Interrupt           ***
;***************************
        goto    itr     

;***************************
;*** Subroutine channel_lookup ***
;***************************

;##################################################
;#  1  #  2  #  4  #  8  # 10  # 20  # 40  #  80  #
;# RA0 # RA1 # RA2 # RA3 # RB4 # RB5 # RB6 #  RB7 #
;##################################################
;  Таблица расчета значений для принятой посылки
;Суммируя можно сформировать комбинацию на выводах
channel_lookup andlw   0x07        
        addwf   PCL,F       
        retlw   0x01        		;Код для нажатой кнопки R1-CA        
        retlw   0x02        		;Код для нажатой кнопки R2-CA       
        retlw   0x04			;Код для нажатой кнопки R3-CA        
        retlw   0x08			;Код для нажатой кнопки R4-CA        
        retlw   0x10        		;Код для нажатой кнопки R1-CB        
        retlw   0x20        		;Код для нажатой кнопки R2-CB        
        retlw   0x40        		;Код для нажатой кнопки R3-CB        
        retlw   0x80        		;Код для нажатой кнопки R4-CB   

     
itr 
		movwf   savew1     
        movf    STATUS,W    
        clrf    STATUS      
        movwf   savestatus     
        movf    PCLATH,W    
        movwf   savepclath     
        clrf    PCLATH 
     
        movf    FSR,W       
        movwf   savefsr
     
        btfsc   INTCON,2    
        call    t0_int_handler 
    
        movf    savefsr,W   
        movwf   FSR   
      
        movf    savepclath,W   
        movwf   PCLATH  
    
        movf    savestatus,W   
        movwf   STATUS     
 
        swapf   savew1,F   
        swapf   savew1,W 
  
        retfie              


main 	
		movlw   0x07        
        movwf   CMCCON      
        movlw   0x10        
        movwf   PORTA       
        clrf    PORTB       
        bsf     STATUS,5    
        bcf     STATUS,6    
        movlw   0x20        
        movwf   PORTA       
        movlw   0x0F        
        movwf   PORTB       
        clrwdt              
        movlw   0x03        
        movwf   TMR0        
        bsf     INTCON,5    
        bcf     STATUS,5    
        bcf     STATUS,6    
        clrf    TMR0        
        clrf    expire_cnt     
        call    mrx_init     
        bsf     INTCON,7    
 
warm      
		clrf    cur_state     
        clrf    cur_seq     
        incf    cur_seq,F 
  
loop
		call    mrx_receive     
        andlw   0xFF        
		bnz		loop
;        btfss   STATUS,2    
 ;       goto    loop     

        call    mrx_chk_buf     
        andlw   0xFF        
        bnz loop
		;btfss   STATUS,2    
        ;goto    loop     

        movf    PORTB,W     
        andlw   0x0F        
        subwf   mrx_buffer,W   
		bnz loop
;        btfss   STATUS,2    
 ;       goto    loop     
rx_ok

		movlw EXPIRE_TIMER		; movlw   0x12  
        movwf   expire_cnt   
  
        movf    bnkd_2F,W   ;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        andlw   0xC0        
        subwf   cur_seq,W   
  		bz		loop

	    ;btfsc   STATUS,2    
        ;goto    loop     
    
	    movf    bnkd_2F,W   
        andlw   0xC0        
        movwf   cur_seq     
        
		movf    bnkd_2F,W   
        andlw   0x3F        
    	bz		loop

;	    btfsc   STATUS,2    
 ;       goto    loop     
    
	    addlw   0xFF        
        andlw   0x0F        
        movwf   bt     
        btfsc   bt,3   
        goto    loop     
        call    channel_lookup     
        movwf   cur_ch 
    
        bcf     INTCON,7    
        btfsc   bnkd_2F,5   
        goto    state_on_off   	; 00-0f: toggle or momentary ON
  
        movf    cur_ch,W   
     	andlw   LATCH_MASK       
        bz    state_on_off  
;		btfsc   STATUS,2    
 ;       goto state_on_off     
	   
      
		  movf    cur_ch,W   
        xorwf   cur_state,F   
        goto    state_done     

state_on_off movf    cur_ch,W   
        xorlw   0xFF        
        andwf   cur_state,F   
        movf    cur_ch,W   
        btfss   bnkd_2F,4   
        iorwf   cur_state,F   
        goto    state_done     

state_done movlw   0x00        
        call    state_out     
        bsf     INTCON,7    
        goto    loop     

;***************************
;*** Subroutine t0_int_handler ***
;***************************
t0_int_handler
		bcf     INTCON,2    
        movf    expire_cnt,F  
		bnz valid_on 
     ;   btfss   STATUS,2    
      ;  goto    valid_on     
       ; movlw   0xFF        
		movlw LATCH_MASK 
        andwf   cur_state,F   
        movlw   0x10        

;***************************
;*** Subroutine state_out ***
;***************************
state_out iorwf   cur_state,W   
        movwf   PORTA       
        movf    cur_state,W   
        movwf   PORTB       
        return              


valid_on decf    expire_cnt,F   
        return              


;***************************
;*** Subroutine mrx_receive ***
;***************************
mrx_receive 
s3		; set flags: first_half=1, if_short=0
		bsf     flags,1   ;bsf FIRST_HALF
s4      bcf     flags,0   ;	bcf IF_SHORT

s5			; init before the received packet

		; set FSR to buffer start


		movlw mrx_buffer    ;      movlw   0x2E      
        movwf   FSR         

		movlw  (packet_len+1) 	;	 movlw   0x03        
        movwf   btcnt  
   		bsf  HEADER 			; bsf     flags,2  
        clrf    bitcnt     
s2
		btfss   RXBIT     
        goto    s2  
  
s6     
		clrf    tmrval     
	
s6_w		btfss   RXBIT     
        goto    s7     
    
	    incf    tmrval,F   
        nop                 
        movlw 	min_2t		;movlw   0x3A        
        subwf   tmrval,W   
        btfss   STATUS,0    
        goto    s6_w   
  
        retlw   0x01
        
s7 		clrf    tmrval     
       
s8
		btfsc 	IF_SHORT	;btfsc   bnkd_2C,0   
        goto    s8_ss1     

s8_ss0 
		btfsc   RXBIT     
        goto    s10  
s9_ss0   
       	movlw	max_2t	; movlw   0x61        
        subwf   tmrval,W   
        btfsc   STATUS,0    
        retlw   0x02        
        incf    tmrval,F   
        goto    s8_ss0     

s8_ss1 	
		btfss   RXBIT     
        goto    s10     
s9_ss1
       	movlw	max_2t	; movlw   0x61        
        subwf   tmrval,W   
        btfsc   STATUS,0    
        retlw   0x02      
  
        incf    tmrval,F   
        goto    s8_ss1     

s10 
		movlw   if_short_val        
        xorwf   flags,F   

s11
     	movlw	min_t;   movlw   0x13        
        subwf   tmrval,W   
        btfss   STATUS,0    
        retlw   0x03  
s12      
        movlw	min_2t	;movlw   0x3A        
        subwf   tmrval,W   
        btfss   STATUS,0    
        goto    s14 
s13   
        btfss   FIRST_HALF ;flags,1   
        goto    s16     
        retlw   0x04   
     
s14 	movlw   first_half_val       
        xorwf   flags,F 
s15  
        btfsc   FIRST_HALF
        goto    s7     

s16 
		btfss   HEADER
        goto    s16_not_header     
        
		btfss	IF_SHORT;btfss   flags,0   
        goto    s16_header_end
     
        btfss   bitcnt,4   
        incf    bitcnt,F  
 
        goto    s7     
        retlw   0x09        ; Warning--Code may not be reachable

s16_header_end 
		bcf		HEADER;bcf     flags,2   
      	movlw	hdrcntmin; movlw   0x0C        
        subwf   bitcnt,W   
        btfss   STATUS,0    
        retlw   0x0A   
     
next_byte	movlw   0x0A        
        	movwf   bitcnt     
        	goto    s7     

s16_not_header 
		decf    bitcnt,F   
		bz		s16_s4
      ;  btfsc   STATUS,2    
       ; goto    lbl00D5     
        movlw   0x01        
        xorwf   bitcnt,W   
		bnz s16_s2
     ;   btfss   STATUS,2    
      ;  goto    lbl00D2     
        btfsc   IF_SHORT
        goto    s7     
        retlw   0x07    
    
s16_s2 	
		rrf     flags,W   
        rlf     bt,F   
        goto    s7     

s16_s4 
		btfsc   IF_SHORT
        retlw   0x08    
    
        movf    bt,W   
        movwf   INDIRECT    
        incf    FSR,F       
      
		decfsz  btcnt,F   
        goto    next_byte  
   
        retlw   0x00        

;***************************
;*** Subroutine mrx_chk_buf ***
;***************************
mrx_chk_buf 
		movlw 	mrx_buffer;movlw   0x2E        
        movwf   FSR         
		movlw (packet_len+1); movlw   0x03        
        movwf   btcnt     
        movlw   0xFF        
        movwf   bt 
    
chk0
		movf    INDIRECT,W  
        xorwf   bt,F   
        clrw                
        btfsc   bt,7   
        xorlw   0x7A        
        btfsc   bt,6   
        xorlw   0x3D        
        btfsc   bt,5   
        xorlw   0x86        
        btfsc   bt,4   
        xorlw   0x43        
        btfsc   bt,3   
        xorlw   0xB9        
        btfsc   bt,2   
        xorlw   0xC4        
        btfsc   bt,1   
        xorlw   0x62        
        btfsc   bt,0   
        xorlw   0x31        
        movwf   bt     

        incf    FSR,F       
        decfsz  btcnt,F  
        goto    chk0  
   
        movf    bt,W  
		bnz		chk_err 
        ;btfss   STATUS,2    
        ;goto    lbl00FE     
        retlw   0x00        

chk_err  retlw   0x0C        

;***************************
;*** Subroutine mrx_init ***
;***************************
mrx_init return              

	end

