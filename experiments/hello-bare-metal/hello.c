/*
** hello.c: Bare metal hello world w/ timer interrupt tests
**
** HW is 6414/15/16 or appropriate simulator
*/

#define KELVIN_SIM		1	/* enable work-around for kelvin cmd line simulator */

#define SWEEP_TEST		0	/* 1 = sweep through all int mux sources */
#define TIMER2_INTR		1	/* 1 = map in timer2 interupt */

#include <stdio.h>

volatile unsigned int dummy;
volatile unsigned int isr_count[16];
volatile unsigned int isr_last_count[16];

#define TIMER0		0x01940000
#define TIMER1		0x01980000
#define TIMER2		0x01AC0000

#define CTL(base)	(*((volatile unsigned int*) ((base)+0x00)))
#define PRD(base)	(*((volatile unsigned int*) ((base)+0x04)))
#define CNT(base)	(*((volatile unsigned int*) ((base)+0x08)))

#define TMR_CTL_FUNC	0x00000001
#define TMR_CTL_INVOUT	0x00000002
#define TMR_CTL_DATOUT	0x00000004
#define TMR_CTL_DATIN	0x00000008
#define TMR_CTL_PWID	0x00000010
#define TMR_CTL_GO	0x00000040
#define TMR_CTL_HLD	0x00000080
#define TMR_CTL_CP	0x00000100
#define TMR_CTL_CLKSRC	0x00000200
#define TMR_CTL_INVINP	0x00000400
#define TMR_CTL_TSTAT	0x00000800
#define TMR_CTL_SPND	0x00008000

#define MUXH		(*((volatile unsigned int*) (0x019C0000)))
#define MUXL		(*((volatile unsigned int*) (0x019C0004)))

extern cregister volatile unsigned int IER;
extern cregister volatile unsigned int IFR;
extern cregister volatile unsigned int ISTP;
extern cregister volatile unsigned int ISR;
extern cregister volatile unsigned int ICR;
extern cregister volatile unsigned int CSR;

/* 0 is reset */
/* 1 is NMI */
/* 2 & 3 are not generally usable */

interrupt void nmi_handler(void) {
	isr_count[1]++;
}

interrupt void int2_handler(void) {
	isr_count[2]++;
}

interrupt void int3_handler(void) {
	isr_count[3]++;
}

interrupt void int4_handler(void) {
	isr_count[4]++;
}

interrupt void int5_handler(void) {
	isr_count[5]++;
}

interrupt void int6_handler(void) {
	isr_count[6]++;
}

interrupt void int7_handler(void) {
	isr_count[7]++;
}

interrupt void int8_handler(void) {
	isr_count[8]++;
}

interrupt void int9_handler(void) {
	isr_count[9]++;
}

interrupt void int10_handler(void) {
	isr_count[10]++;
}

interrupt void int11_handler(void) {
	isr_count[11]++;
}

interrupt void int12_handler(void) {
	isr_count[12]++;
}

interrupt void int13_handler(void) {
	isr_count[13]++;
}

interrupt void int14_handler(void) {
	isr_count[14]++;
}

interrupt void int15_handler(void) {
	isr_count[15]++;
}

void timer_init(unsigned int base) {
	unsigned int ctl;

	// the simple version that works for CSS 
	ctl = TMR_CTL_CLKSRC;
	CTL(base) = ctl;
	PRD(base) = 0xF000;
	CTL(base) = ctl | TMR_CTL_GO | TMR_CTL_HLD;
}

void sleep(int secs) {
	int i;
	int j;

	for (i=0; i < secs; i++) {
		for (j=0; j < 100000; j++) {
			dummy++;
		}
	}
}

void print_isr_stats(void) {
	int i;
	
	for (i=0; i < 16; i++) {
		if (isr_count[i] != isr_last_count[i]) {
			printf("ISR %2d: %6d  (delta %6d)\n", i, isr_count[i], isr_count[i] -isr_last_count[i]);
			isr_count[i] = isr_last_count[i];
		}
	}
}

void main() {
	int i;
	
	/* the isr and last counts should start 0 but this will detect if that does not happen */
	memset(isr_last_count, 0, sizeof(isr_last_count));
	/* test that the logic works */
	isr_count[2] = 42;

	printf("IER  = %8.8X   IFR  = %8.8X  ISTP = %8.8X  CSR = %8.8X\n", IER, IFR, ISTP, CSR);
	printf("MUXH = %8.8X   MUXL = %8.8X\n", MUXH, MUXL);
	print_isr_stats();

	ISR  = 0x00000100;	/* set int8 manually */
	ISTP = 0x80000000;	/* point to our vector table */
	IER  = 0x0000FFF3;	/* enable all intr's except the reserved 2&3 */
#if KELVIN_SIM & SWEEP_TEST
	printf("note: Sweep test on Kelvin cmd line simulator requires unmapping all other timer interrupt mappings\n");
	MUXH = 0;  		/* null out all timer mappings */
#elif TIMER2_INTR
	MUXH = (MUXH & 0xFFE0FFFF) | 0x00130000;  /* bring timer2 in on int13 */
#elif KELVIN_SIM
	/* do a write the the mux register to make default mappings work on "kelvin" cmd line sim */
	MUXH = MUXH;
#endif
	
	printf("IER  = %8.8X   IFR  = %8.8X  ISTP = %8.8X  CSR = %8.8X\n", IER, IFR, ISTP, CSR);
	print_isr_stats();

	_enable_interrupts();
	printf("IER  = %8.8X   IFR  = %8.8X  ISTP = %8.8X  CSR = %8.8X\n", IER, IFR, ISTP, CSR);
	print_isr_stats();

	timer_init(TIMER0);
	timer_init(TIMER1);
	timer_init(TIMER2);
	for (i=0; i < 32; i++) {
#if SWEEP_TEST
		MUXL = (MUXL & 0xFFFFFFE0) | i;   /* sweep possible sources for int4 */
#endif
		sleep(1);
		printf("CNT  = %8.8X   IFR  = %8.8X  MUXL = %8.8X\n", CNT(TIMER1), IFR, MUXL);
		print_isr_stats();
	}
}

