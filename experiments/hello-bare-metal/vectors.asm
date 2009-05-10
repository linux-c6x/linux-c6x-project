; 
;  vector.asm
;
           .sect ".vectors"
           .ref  _c_int00			; Reset handler
	   .ref  _nmi_handler			; NMI
           .ref  _int2_handler
           .ref  _int3_handler
           .ref  _int4_handler
           .ref  _int5_handler
           .ref  _int6_handler
           .ref	 _int7_handler
           .ref	 _int8_handler
           .ref	 _int9_handler
           .ref	 _int10_handler
	   .ref	 _int11_handler
           .ref	 _int12_handler
           .ref	 _int13_handler
           .ref	 _int14_handler
           .ref  _int15_handler

	   .align 32
RESET:     MVKL	.S1	_c_int00,A0		; branch to _c_int00
           MVKH	.S1	_c_int00,A0
           B	.S2	A0
           NOP        		
           NOP						
           NOP				
           NOP			
           NOP		

	   .align 32	
NMI:       STW	.D2     A0,*B15--[1]		; NMI interrupt: not used by Linux
       ||  MVKL	.S1     _nmi_handler,A0
           MVKH	.S1     _nmi_handler,A0
           B	.S2	A0
           LDW	.D2	*++B15[1],A0
           NOP          4
           NOP
           NOP	

	   .align 32	
AINT:      STW	.D2     A0,*B15--[1]		; reserved
       ||  MVKL	.S1     _int2_handler,A0
           MVKH	.S1     _int2_handler,A0
           B	.S2	A0
           LDW	.D2	*++B15[1],A0
           NOP          4
           NOP
           NOP

	   .align 32	
MSGINT:    STW	.D2     A0,*B15--[1]		; reserved
       ||  MVKL	.S1     _int3_handler,A0
           MVKH	.S1     _int3_handler,A0
           B	.S2	A0
           LDW	.D2	*++B15[1],A0
           NOP          4
           NOP
           NOP

	   .align 32	
INT4:      STW	.D2     A0,*B15--[1]
       ||  MVKL	.S1     _int4_handler,A0
           MVKH	.S1     _int4_handler,A0
           B	.S2	A0
           LDW	.D2	*++B15[1],A0
           NOP          4
           NOP
           NOP

	   .align 32
INT5:      STW	.D2     A0,*B15--[1]
       ||  MVKL	.S1     _int5_handler,A0
           MVKH	.S1     _int5_handler,A0
           B	.S2	A0
           LDW	.D2	*++B15[1],A0
           NOP          4
           NOP
           NOP
	
	   .align 32
INT6:      STW	.D2     A0,*B15--[1]
       ||  MVKL	.S1     _int6_handler,A0
           MVKH	.S1     _int6_handler,A0
           B	.S2	A0
           LDW	.D2	*++B15[1],A0
           NOP          4
           NOP
           NOP
			
	   .align 32
INT7:      STW	.D2     A0,*B15--[1]
       ||  MVKL	.S1     _int7_handler,A0
           MVKH	.S1     _int7_handler,A0
           B	.S2	A0
           LDW	.D2	*++B15[1],A0
           NOP          4
           NOP
           NOP

	   .align 32
INT8:      STW	.D2     A0,*B15--[1]
       ||  MVKL	.S1     _int8_handler,A0
           MVKH	.S1     _int8_handler,A0
           B	.S2	A0
           LDW	.D2	*++B15[1],A0
           NOP          4
           NOP
           NOP

	   .align 32
INT9:      STW	.D2     A0,*B15--[1]
       ||  MVKL	.S1     _int9_handler,A0
           MVKH	.S1     _int9_handler,A0
           B	.S2	A0
           LDW	.D2	*++B15[1],A0
           NOP          4
           NOP
           NOP

	   .align 32	
INT10:     STW	.D2     A0,*B15--[1]
       ||  MVKL	.S1     _int10_handler,A0
           MVKH	.S1     _int10_handler,A0
           B	.S2	A0
           LDW	.D2	*++B15[1],A0
           NOP          4
           NOP
           NOP

	   .align 32
INT11:     STW	.D2     A0,*B15--[1]
       ||  MVKL	.S1     _int11_handler,A0
           MVKH	.S1     _int11_handler,A0
           B	.S2	A0
           LDW	.D2	*++B15[1],A0
           NOP          4
           NOP
           NOP

	   .align 32	
INT12:     STW	.D2     A0,*B15--[1]
       ||  MVKL	.S1     _int12_handler,A0
           MVKH	.S1     _int12_handler,A0
           B	.S2	A0
           LDW	.D2	*++B15[1],A0
           NOP          4
           NOP
           NOP
	
	   .align 32	
INT13:     STW	.D2     A0,*B15--[1]
       ||  MVKL	.S1     _int13_handler,A0
           MVKH	.S1     _int13_handler,A0
           B	.S2	A0
           LDW	.D2	*++B15[1],A0
           NOP          4
           NOP
           NOP

	   .align 32
INT14:     STW	.D2     A0,*B15--[1]
       ||  MVKL	.S1     _int14_handler,A0
           MVKH	.S1     _int14_handler,A0
           B	.S2	A0
           LDW	.D2	*++B15[1],A0
           NOP          4
           NOP
           NOP

	   .align 32	
INT15:     STW	.D2     A0,*B15--[1]
       ||  MVKL	.S1     _int15_handler,A0
           MVKH	.S1     _int15_handler,A0
           B	.S2	A0
           LDW	.D2	*++B15[1],A0
           NOP		4
           NOP
           NOP
