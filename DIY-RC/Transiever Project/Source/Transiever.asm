;***   File generated automatically using PICUtil

;***************************
;*** Compiler Directives ***
;***************************

	;disable following compiler warnings
	errorlevel -224 ;Use of this instruction is not recommended
	errorlevel -302 ;Register in operand not in bank 0. Ensure that bank bits are correct
	errorlevel -220 ;Address exceeds maximum range for this processor

#include <p16F628a.inc>
	__CONFIG   _CP_OFF & _WDT_OFF & _PWRTE_ON & _INTRC_OSC_NOCLKOUT & _LVP_OFF & _MCLRE_OFF & _BODEN_OFF


#define MODE_CH8
txport	EQU PORTA
;***************************
;*** Program Variables   ***
;***************************
count1  	equ	0x20	; (used   2 times)
count2  	equ	0x21	; (used   4 times)
ncnt	  	equ	0x22	; (used   8 times)
bt		  	equ	0x23	; (used   2 times)
sum		  	equ	0x24	; (used  12 times)
mtx_buffer  	equ	0x25	; (used   2 times)
mtx_delay  	equ	0x27	; (used   5 times)
tcnt	 	equ	0x28	; (used   3 times)
rcnt	  	equ	0x29	; (used   3 times)
cod		  	equ	0x2A	; (used   5 times)
prevcod  	equ	0x2B	; (used   3 times)
cod0	  	equ	0x2C	; (used  12 times)
rowstate  	equ	0x2D	; (used  10 times)








packet_len	EQU 2

;***** VARIABLE DEFINITIONS


;count1		res 1
;count2		res 1
;ncnt		res 1
;bt		res 1
;sum		res 1

;mtx_buffer	res 2

;mtx_delay	res 1 ; half_frame delay


;***************************
;*** Program Code        ***
;***************************
startup
	org	0x0000
        goto    main     ; Warning--Code may not be reachable
        nop                 ; Warning--Code may not be reachable
        nop                 ; Warning--Code may not be reachable
        nop                 ; Warning--Code may not be reachable

;***************************
;*** Interrupt           ***
;***************************
        retfie              


main
		clrf    PORTA       
		clrf    PORTB       
		clrf    TMR0        

		BANKSEL TRISA
	
		movlw   0x00        
		movwf   PORTA       
		movlw   0xF0        
		movwf   PORTB       
		
		bcf OPTION_REG, PSA
		clrwdt
		clrf OPTION_REG
		clrwdt 
	
		BANKSEL PORTA 
		movlw   0x07        
		movwf   CMCON      
		movlw   0x08        
		movwf   INTCON      

		call    mtx_init     
		clrf    mtx_buffer     
		clrf    tcnt     

loop0 	
		clrf    (mtx_buffer+1)   ;!!!! 
		movlw   0xFF        
		movwf   prevcod    
		movlw   0xFC        
		movwf   PORTB       
		movlw   0xF0        
		movwf	TRISB       
		movf    PORTB,W     
		bcf     INTCON,RBIF 
		sleep
               
loop
		clrf    cod    
        movlw   0xFE        
		movwf	TRISB       
        clrf    PORTB       
#ifdef	MODE_CH8							;Выбор количества каналов
		clrw
#endif
#ifdef	MODE_CH4
		movlw 0x20
#endif       
        call    scan     
        movlw   0xFD 
		movwf	TRISB       

#ifdef MODE_CH8
		movlw 0x04
#endif
#ifdef MODE_CH4
		movlw 0x30
#endif       
        call    scan     
        movf    cod,W   
      	bz		loop2   

        subwf   prevcod,W   
        bz loop2   

        movf    cod,W   
        movwf   prevcod     
        movwf   (mtx_buffer+1)    
        movlw   0x03        
        movwf   rcnt     
        movlw   0x40        
        addwf   tcnt,F   

loop2 
		movlw   0xF7        
        movwf	TRISB        
        call    scanid     
        movf    cod0,W   
        movwf   mtx_buffer
loop3     
        movf    (mtx_buffer+1),W   
        andlw   0x3F        
        iorwf   tcnt,W   
        movwf   (mtx_buffer+1)    
        
		call    mtx_send
    
        movf    rcnt,W   
      	bz		loop_done
        decfsz  rcnt,F   
        goto    loop 
    
loop_done 
		movf    cod,W   
        btfsc   STATUS,Z  
        goto    loop0     
        goto    loop    

;***************************
;*** Subroutine scan ***
;***************************
scan
		movwf   cod0  
scandelay   
        movlw   0xF0        
        andwf   PORTB,W     
        movwf   rowstate
    
        incf    cod0,F   
        btfss   rowstate,4   
        goto	pressed  
 
        incf    cod0,F   
        btfss   rowstate,5   
        goto	pressed 
  
        incf    cod0,F   
        btfss   rowstate,6   
        goto	pressed
     
        incf    cod0,F   
        btfss   rowstate,7   
        goto	pressed     
        retlw   0x00        
pressed
		 movf    cod0,W   
        movwf   cod     
        return              


;***************************
;*** Subroutine scanid ***
;***************************
scanid	
		clrf    cod0     
        clrw                
scandelay2
		addlw   0x01        
		bnz scandelay2   
        movlw   0xF0        
        andwf   PORTB,W     
        movwf   rowstate
     
        btfss   rowstate,7   
        bsf     cod0,3   
        btfss   rowstate,6   
        bsf     cod0,2   
        btfss   rowstate,5   
        bsf     cod0,1   
        btfss   rowstate,4   
        bsf     cod0,0   
        return              


;***************************
;*** Subroutine mtx_init ***
;***************************
mtx_init movlw   0x75        
        movwf   mtx_delay     
        return              


;***************************
;*** Subroutine lbl0077 ***
;***************************
mtx_send
outbuf
		movlw   0x14  				;Количество единиц в заголовке
header      
        movwf   count2				;Ячейка для счета
head0								;Начинаем посылку
		call    bit1				;Отправим 1
        decfsz  count2,F			;уменшим счетчик и если не ноль
        goto    head0				;перейдем на начало посылки
        call    bit0				;иначе отправим 0
    
		movlw	mtx_buffer			; movlw   0x25        
        movwf   FSR         
        movlw   packet_len        
        movwf   count1     
        movlw   0xFF        
        movwf   sum     
outbu0 
		movf    INDF,W  
        call    update_sum     
        movf    INDF,W  
        call    outbyte     
        incf    FSR,F       
        decfsz  count1,F   
        goto    outbu0     
        movf    sum,W   
        call    outbyte     
        return              


;***************************
;*** Subroutine lbl008D ***
;***************************
update_sum
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

outbyte
		movwf   bt    
        movlw   0x08        
        movwf   count2     
outby0 
		rlf     bt,F   
        btfsc   STATUS,C    
        goto    outby1     
        call    bit0     
        goto    outby2     

outby1
		call    bit1     
outby2 
		decfsz  count2,F   
        goto    outby0     
        call    bit1     

;***************************
;*** Subroutine lbl00AD ***
;***************************
bit0
		movlw   0x01        		;TXHIGH
        movwf   txport
ndelaya0       
        movf    mtx_delay,W   
        movwf   ncnt     
ndelaya1
		decfsz  ncnt,F   
        goto    ndelaya1

        movlw   0x00        		;TXLOW
        movwf   txport   
ndelayb0    
        movf    mtx_delay,W   
        movwf   ncnt     
ndelayb1
		decfsz  ncnt,F   
        goto    ndelayb1
        return              



bit1	
		movlw   0x00 					;TXLOW       
        movwf   txport 
ndelayc0      
        movf    mtx_delay,W   
        movwf   ncnt     
ndelayc1
		decfsz  ncnt,F   
        goto    ndelayc1     
    
	    movlw   0x01  					;TXHIGH      
        movwf	txport       
ndelaye0
        movf    mtx_delay,W   
        movwf   ncnt     
ndelaye1
		decfsz  ncnt,F   
        goto    ndelaye1
        return              

	end

