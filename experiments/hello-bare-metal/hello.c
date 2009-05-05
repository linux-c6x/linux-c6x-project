#include <stdio.h>

volatile unsigned int dummy;
//volatile unsigned int* XXX = (unsigned int*) 0x800003F0;

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

void timer_init(void)
{
	unsigned int ctl;

#if 0
	ctl = TMR_CTL_CLKSRC | 0x033F;
	CTL(TIMER1) = ctl;
	PRD(TIMER1) = 0xF000;
	CTL(TIMER1) = ctl;
	CTL(TIMER1) = ctl | TMR_CTL_GO | TMR_CTL_HLD;
	sleep(1);
	CTL(TIMER1) = ctl | TMR_CTL_HLD;
#else
	ctl = TMR_CTL_CLKSRC;
	CTL(TIMER1) = ctl;
	PRD(TIMER1) = 0xF000;
	CTL(TIMER1) = ctl | TMR_CTL_GO | TMR_CTL_HLD;
#endif
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

void main()
{
	int i;

	printf("IER  = %8.8X   IFR  = %8.8X  ISTP = %8.8X\n", IER, IFR, ISTP);
	ISR  = 0x00000100;
	ISTP = 0x80000000;
	printf("IER  = %8.8X   IFR  = %8.8X  ISTP = %8.8X\n", IER, IFR, ISTP);
	printf("MUXH = %8.8X   MUXL = %8.8X\n", MUXH, MUXL);

	timer_init();
	for (i=0; i < 10; i++) {
		printf("CNT  = %8.8X   IFR  = %8.8X\n", CNT(TIMER1), IFR);
		sleep(1);
	}
}

