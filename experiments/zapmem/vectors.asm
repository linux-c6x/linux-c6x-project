; 
;  vector.asm
;
           .sect ".vectors"
           .ref  _c_int00			; Reset handler

	   .align 32
RESET:     MVKL	.S1	_c_int00,A0		; branch to _c_int00
           MVKH	.S1	_c_int00,A0
           B	.S2	A0
           NOP        		
           NOP						
           NOP				
           NOP			
           NOP		

