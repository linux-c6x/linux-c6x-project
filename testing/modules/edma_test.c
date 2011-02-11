/*
 * edma-test kernel module
 *
 * Copyright (C) 2009, 2011 Texas Instruments Incorporated - http://www.ti.com/
 *
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *
 * Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the
 * distribution.
 *
 * Neither the name of Texas Instruments Incorporated nor the names of
 * its contributors may be used to endorse or promote products derived
 * from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
*/

#define ITERATIONS 10

/*******************************************************************************
 *	HEADER FILES
 */
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/init.h>
#include <linux/sched.h>
#include <linux/wait.h>
#include <linux/mm.h>
#include <linux/dma-mapping.h>
#include <linux/io.h>
#include <linux/gpio.h>
#include <linux/platform_device.h>

#include <mach/irq.h>
#include <mach/hardware.h>
#include <asm/edma.h>
#include <asm/gpio.h>
#include <asm/delay.h>

/*******************************************************************************
 *	LOCAL DEFINES
 */
/* #undef EDMA3_DEBUG */

#ifdef EDMA3_DEBUG
#define DMA_PRINTK(ARGS...)  printk(KERN_INFO "<%s>: ",__FUNCTION__);printk(ARGS)
#define DMA_FN_IN printk(KERN_INFO "[%s]: start\n", __FUNCTION__)
#define DMA_FN_OUT printk(KERN_INFO "[%s]: end\n",__FUNCTION__)
#else
#define DMA_PRINTK( x... )
#define DMA_FN_IN
#define DMA_FN_OUT
#endif

/*******************************************************************************
 *	FILE GLOBALS
 */
static volatile int irqraised1 = 0;
static volatile int irqraised2 = 0;

int edma3_memtomemcpytest_dma(int acnt, int bcnt, int ccnt, int sync_mode,
			      int event_queue);
int edma3_memtomemcpytest_dma_link(int acnt, int bcnt, int ccnt, int sync_mode,
				   int event_queue);

static int edma3_gpio_triggered_dma(int acnt, int bcnt, int ccnt, int sync_mode,
				    int event_queue, int event_id);

dma_addr_t dmaphyssrc1 = 0;
dma_addr_t dmaphyssrc2 = 0;
dma_addr_t dmaphysdest1 = 0;
dma_addr_t dmaphysdest2 = 0;

char *dmabufsrc1 = NULL;
char *dmabufsrc2 = NULL;
char *dmabufdest1 = NULL;
char *dmabufdest2 = NULL;

static int acnt = 512;
static int bcnt = 8;
static int ccnt = 8;

module_param(acnt, int, S_IRUGO);
module_param(bcnt, int, S_IRUGO);
module_param(ccnt, int, S_IRUGO);

#define MAX_DMA_TRANSFER_IN_BYTES   (acnt * bcnt * ccnt)

#define GPIO_LINE     5
#define GPIO_DMA_EVT  DMA_GPIO_EVT5

static struct gpio_controller *__iomem g;
static int old_gpio_dir;
static int old_gpio_val;
static int old_gpio_falling;
static int old_gpio_rising;

static struct resource edma_test_resources[] = {
	{
		.name	= "GPIO_EVT",
		.start	= GPIO_DMA_EVT,
		.flags	= IORESOURCE_DMA,
	},
};

static struct platform_device edma_test_device = {
	.name           = "edma_test_gpio",
	.id             = 1,
	.num_resources	= ARRAY_SIZE(edma_test_resources),
	.resource	= edma_test_resources,
};


/*******************************************************************************
 *	FUNCTION DEFINITIONS
 */
static void callback1(unsigned channel, u16 ch_status, void *data)
{
	switch (ch_status) {
	case DMA_COMPLETE:
		irqraised1 = 1;
		/*DMA_PRINTK ("\n From Callback 1: Channel %d status is: %u\n", channel, ch_status);*/
		break;
	case DMA_CC_ERROR:
		irqraised1 = -1;
		DMA_PRINTK("\nFrom Callback 1: DMA_EVT_MISS_ERROR occured "
			   "on Channel %d\n", channel);
		break;
	default:
		break;
	}
}

static void callback2(unsigned channel, u16 ch_status, void *data)
{
	switch (ch_status) {
	case DMA_COMPLETE:
		irqraised2 = 1;
		/*DMA_PRINTK ("\n From Callback 2: Channel %d status is: %u\n", channel, ch_status);*/
		break;
	case DMA_CC_ERROR:
		irqraised2 = -1;
		DMA_PRINTK("\nFrom Callback 2: DMA_EVT_MISS_ERROR occured "
			   "on Channel %d\n", channel);
		break;
	default:
		break;
	}
}

static int edma_test_init(void)
{
	int result = 0;
	int iterations = 0;
	int numTCs = 2;
	int modes = 2;
	int i, j;

	printk("\nInitializing edma3_sample_app module\n");

	DMA_PRINTK("\nACNT=%d, BCNT=%d, CCNT=%d", acnt, bcnt, ccnt);

	/* allocate consistent memory for DMA
	   dmaphyssrc1(handle)= device viewed address.
	   dmabufsrc1 = CPU-viewed address */

	dmabufsrc1 = dma_alloc_coherent(NULL, MAX_DMA_TRANSFER_IN_BYTES,
					&dmaphyssrc1, 0);
	if (!dmabufsrc1) {
		DMA_PRINTK("dma_alloc_coherent failed for dmaphyssrc1\n");
		return -ENOMEM;
	}

	dmabufdest1 = dma_alloc_coherent(NULL, MAX_DMA_TRANSFER_IN_BYTES,
					 &dmaphysdest1, 0);
	if (!dmabufdest1) {
		DMA_PRINTK("dma_alloc_coherent failed for dmaphysdest1\n");

		dma_free_coherent(NULL, MAX_DMA_TRANSFER_IN_BYTES, dmabufsrc1,
				  dmaphyssrc1);
		return -ENOMEM;
	}

	dmabufsrc2 = dma_alloc_coherent(NULL, MAX_DMA_TRANSFER_IN_BYTES,
					&dmaphyssrc2, 0);
	if (!dmabufsrc2) {
		DMA_PRINTK("dma_alloc_coherent failed for dmaphyssrc2\n");

		dma_free_coherent(NULL, MAX_DMA_TRANSFER_IN_BYTES, dmabufsrc1,
				  dmaphyssrc1);
		dma_free_coherent(NULL, MAX_DMA_TRANSFER_IN_BYTES, dmabufdest1,
				  dmaphysdest1);
		return -ENOMEM;
	}

	dmabufdest2 = dma_alloc_coherent(NULL, MAX_DMA_TRANSFER_IN_BYTES,
					 &dmaphysdest2, 0);
	if (!dmabufdest2) {
		DMA_PRINTK("dma_alloc_coherent failed for dmaphysdest2\n");

		dma_free_coherent(NULL, MAX_DMA_TRANSFER_IN_BYTES, dmabufsrc1,
				  dmaphyssrc1);
		dma_free_coherent(NULL, MAX_DMA_TRANSFER_IN_BYTES, dmabufdest1,
				  dmaphysdest1);
		dma_free_coherent(NULL, MAX_DMA_TRANSFER_IN_BYTES, dmabufsrc2,
				  dmaphyssrc2);
		return -ENOMEM;
	}

#if defined(GPIO_DMA_EVT)
	/*
	 * This is to reserve a GPIO event triggered DMA channel.
	 * The test device must be registered before the first call to
	 * edma_alloc_channel()
	 */
	platform_device_register(&edma_test_device);

	g = __gpio_to_controller(GPIO_LINE);
	__dint();
	old_gpio_val = __raw_readl(&g->in_data) & (1 << GPIO_LINE);
	old_gpio_dir = __raw_readl(&g->dir) & (1 << GPIO_LINE);

	__raw_writel((1 << GPIO_LINE), &g->clr_data);
	__raw_writel(__raw_readl(&g->dir) & ~(1 << GPIO_LINE), &g->dir);

	/* rising edge event */
	old_gpio_rising = __raw_readl(&g->set_rising) & (1 << GPIO_LINE);
	old_gpio_falling = __raw_readl(&g->set_falling) & (1 << GPIO_LINE);
	__raw_writel((1 << GPIO_LINE), &g->clr_falling);
	__raw_writel((1 << GPIO_LINE), &g->set_rising);
	__rint();
#endif

	for (iterations = 0; iterations < ITERATIONS; iterations++) {
		DMA_PRINTK("Iteration = %d\n", iterations);

		for (j = 0; j < numTCs; j++) {
			DMA_PRINTK("TC = %d\n", j);

			for (i = 0; i < modes; i++) { /* sync_mode */
				DMA_PRINTK("Mode = %d\n", i);

				/* Run all EDMA3 test cases */
				DMA_PRINTK("Starting edma3_memtomemcpytest_dma\n");
				result = edma3_memtomemcpytest_dma(acnt,
								   bcnt,
								   ccnt,
								   i, j);
				if (result) {
					printk(KERN_INFO "edma3_memtomemcpytest_dma failed\n");
					goto done;
				}

				DMA_PRINTK("Starting edma3_memtomemcpytest_dma_link\n");
				result = edma3_memtomemcpytest_dma_link(acnt,
									bcnt,
									ccnt,
									i, j);
				if (result) {
					printk("edma3_memtomemcpytest_dma_link failed\n");
					goto done;
				}
#if defined(GPIO_DMA_EVT)
				result = edma3_gpio_triggered_dma(acnt,
								  bcnt,
								  ccnt,
								  i, j,
								  GPIO_DMA_EVT);
				if (result) {
					printk("edma3_gpio_triggered_dma failed\n");
					goto done;
				}
#endif
			}
		}
	}

done:
#if defined(GPIO_DMA_EVT)
	/*
	 * Restore borrowed gpio
	 */
	__dint();
	if (old_gpio_val)
		__raw_writel((1 << GPIO_LINE), &g->set_data);
	else
		__raw_writel((1 << GPIO_LINE), &g->clr_data);

	if (old_gpio_dir)
		__raw_writel(__raw_readl(&g->dir) | (1 << GPIO_LINE), &g->dir);

	if (old_gpio_falling)
		__raw_writel((1 << GPIO_LINE), &g->set_falling);

	if (!old_gpio_rising)
		__raw_writel((1 << GPIO_LINE), &g->clr_rising);
	__rint();
#endif
	return result;
}

void edma_test_exit(void)
{
	dma_free_coherent(NULL, MAX_DMA_TRANSFER_IN_BYTES, dmabufsrc1,
			  dmaphyssrc1);
	dma_free_coherent(NULL, MAX_DMA_TRANSFER_IN_BYTES, dmabufdest1,
			  dmaphysdest1);

	dma_free_coherent(NULL, MAX_DMA_TRANSFER_IN_BYTES, dmabufsrc2,
			  dmaphyssrc2);
	dma_free_coherent(NULL, MAX_DMA_TRANSFER_IN_BYTES, dmabufdest2,
			  dmaphysdest2);

	printk("\nExiting edma3_sample_app module\n");
}

/* DMA Channel, Mem-2-Mem Copy, ASYNC Mode, INCR Mode */
int edma3_memtomemcpytest_dma(int acnt, int bcnt, int ccnt, int sync_mode,
			      int event_queue)
{
	int result = 0;
	unsigned int dma_ch = 0;
	int i;
	int count;
	unsigned int Istestpassed = 0u;
	unsigned int numenabled = 0;
	struct edmacc_param param_set;

	/* Initalize source and destination buffers */
	for (count = 0; count < (acnt * bcnt * ccnt); count++) {
		dmabufsrc1[count] = 'A' + (count % 26);
		dmabufdest1[count] = 0;
	}
	dma_sync_single_range_for_device(NULL, dmaphyssrc1,
					 0, (acnt * bcnt * ccnt),
					 DMA_TO_DEVICE);

	/*
	 * We use DMA_BIDERCTIONAL on this area since the CPU is both
	 * writing (before DMA) and reading (after DMA) here.
	 */
	dma_sync_single_range_for_device(NULL, dmaphysdest1,
					 0, (acnt * bcnt * ccnt),
					 DMA_BIDIRECTIONAL);

	dma_ch = edma_alloc_channel(EDMA_CHANNEL_ANY, callback1, NULL,
			event_queue);
	if (dma_ch < 0) {
		DMA_PRINTK
		    ("\nedma3_memtomemcpytest_dma: edma_alloc_channel failed for dma_ch, error:%d\n",
		     dma_ch);
		return dma_ch;
	}

	param_set.opt = 0;
	param_set.src = (unsigned)dmaphyssrc1;
	param_set.dst = (unsigned)dmaphysdest1;

	param_set.a_b_cnt = (bcnt << 16) | acnt;
	param_set.ccnt = ccnt;

	/* Set B count reload as B count. */
	param_set.link_bcntrld = bcnt << 16;

	/* Setting up the SRC/DES Index */
	param_set.src_dst_bidx = (acnt << 16) | acnt;

	/* A Sync Transfer Mode */
	param_set.src_dst_cidx = (acnt << 16) | acnt;

	/* Enable the Interrupts on Channel 1 */
	param_set.opt |= (ITCINTEN | TCINTEN);
	param_set.opt |= EDMA_TCC(EDMA_CHAN_SLOT(dma_ch));
	edma_write_slot(dma_ch, &param_set);

	numenabled = bcnt * ccnt;

	for (i = 0; i < numenabled; i++) {
		irqraised1 = 0;

		/* Now enable the transfer as many times as calculated above. */
		result = edma_start(dma_ch);
		if (result != 0) {
			DMA_PRINTK
				("edma3_memtomemcpytest_dma: edma_start failed for ch %d\n", dma_ch);
			break;
		}

		/* Wait for the Completion ISR. */
		while (irqraised1 == 0u) ;
		if (irqraised1 == 0) {
			/* Some error occured, break from the FOR loop. */
			DMA_PRINTK("edma3_memtomemcpytest_dma: "
				   "Event Timeout!\n");
			result = -1;
			break;
		}

		/* Check the status of the completed transfer */
		if (irqraised1 < 0) {
			/* Some error occured, break from the FOR loop. */
			DMA_PRINTK("edma3_memtomemcpytest_dma: "
				   "Event Miss Occured!!!\n");
			break;
		}
	}

	if (0 == result) {
		dma_sync_single_range_for_cpu(NULL, dmaphysdest1,
					      0, (acnt * bcnt * ccnt),
					      DMA_FROM_DEVICE);

		for (i = 0; i < (acnt * bcnt * ccnt); i++) {
			if (dmabufsrc1[i] != dmabufdest1[i]) {
				DMA_PRINTK
				    ("\n edma3_memtomemcpytest_dma: Data write-read matching failed at = %u\n",
				     i);
				Istestpassed = 0u;
				result = -1;
				break;
			}
		}
		if (i == (acnt * bcnt * ccnt))
			Istestpassed = 1u;

		edma_stop(dma_ch);
		edma_clean_channel(dma_ch);
		edma_free_slot(dma_ch);
		edma_free_channel(dma_ch);
	}

	if (Istestpassed == 1u) {
		DMA_PRINTK
		    ("\nedma3_memtomemcpytest_dma: EDMA Data Transfer Successfull \n");
	} else {
		DMA_PRINTK
		    ("\nedma3_memtomemcpytest_dma: EDMA Data Transfer Failed \n");
	}

	return result;
}

/* 2 DMA Channels Linked, Mem-2-Mem Copy, ASYNC Mode, INCR Mode */
int edma3_memtomemcpytest_dma_link(int acnt, int bcnt, int ccnt, int sync_mode,
				   int event_queue)
{
	int result = 0;
	unsigned int dma_ch1 = 0;
	unsigned int dma_ch2 = 0;
	int i;
	int count = 0;
	unsigned int Istestpassed1 = 0u;
	unsigned int Istestpassed2 = 0u;
	unsigned int numenabled = 0;
	struct edmacc_param param_set;

	/* Initalize source and destination buffers */
	for (count = 0u; count < (acnt * bcnt * ccnt); count++) {
		dmabufsrc1[count] = 'A' + (count % 26);
		dmabufdest1[count] = 0;

		dmabufsrc2[count] = 'A' + (count % 26);
		dmabufdest2[count] = 0;
	}

	dma_sync_single_range_for_device(NULL, dmaphyssrc1,
					 0, (acnt * bcnt * ccnt),
					 DMA_TO_DEVICE);
	dma_sync_single_range_for_device(NULL, dmaphyssrc2,
					 0, (acnt * bcnt * ccnt),
					 DMA_TO_DEVICE);

	/*
	 * We use DMA_BIDERCTIONAL on these two since the CPU is both
	 * writing (before DMA) and reading (after DMA) these areas.
	 */
	dma_sync_single_range_for_device(NULL, dmaphysdest1,
					 0, (acnt * bcnt * ccnt),
					 DMA_BIDIRECTIONAL);
	dma_sync_single_range_for_device(NULL, dmaphysdest2,
					 0, (acnt * bcnt * ccnt),
					 DMA_BIDIRECTIONAL);

	dma_ch1 = edma_alloc_channel(EDMA_CHANNEL_ANY, callback1, NULL,
				event_queue);
	if (dma_ch1 < 0) {
		DMA_PRINTK
		    ("edma3_memtomemcpytest_dma_link::edma_alloc_channel "
		     "failed for dma_ch1, error:%d\n", dma_ch1);
		return dma_ch1;
	}

	param_set.opt = 0;
	param_set.src = (unsigned)dmaphyssrc1;
	param_set.dst = (unsigned)dmaphysdest1;

	param_set.a_b_cnt = (bcnt << 16) | acnt;
	param_set.ccnt = ccnt;

	/* Set B count reload as B count. */
	param_set.link_bcntrld = bcnt << 16;

	/* Setting up the SRC/DES Index */
	param_set.src_dst_bidx = (acnt << 16) | acnt;

	/* A Sync Transfer Mode */
	param_set.src_dst_cidx = (acnt << 16) | acnt;

	/* Enable the Interrupts on Channel 1 */
	param_set.opt |= (ITCINTEN | TCINTEN);
	param_set.opt |= EDMA_TCC(EDMA_CHAN_SLOT(dma_ch1));
	edma_write_slot(dma_ch1, &param_set);

	/* Request a Link Channel */
	dma_ch2 = edma_alloc_channel(EDMA_CHANNEL_ANY, callback2, NULL,
				event_queue);
	DMA_PRINTK("edma3_memtomemcpytest_dma_link::dma_ch2 is %d\n", dma_ch2);

	if (dma_ch2 < 0) {
		DMA_PRINTK
		    ("\nedma3_memtomemcpytest_dma_link::edma_alloc_channel "
		     "failed for dma_ch2, error:%d\n", dma_ch2);
		return dma_ch2;
	}


	param_set.src = (unsigned)dmaphyssrc2;
	param_set.dst = (unsigned)dmaphysdest2;

	param_set.a_b_cnt = (bcnt << 16) | acnt;
	param_set.ccnt = ccnt;

	/* Set B count reload as B count. */
	param_set.link_bcntrld = bcnt << 16;

	/* Setting up the SRC/DES Index */
	param_set.src_dst_bidx = (acnt << 16) | acnt;

	/* A Sync Transfer Mode */
	param_set.src_dst_cidx = (acnt << 16) | acnt;

	/* Enable the Interrupts on Channel 1 */
	param_set.opt |= (ITCINTEN | TCINTEN);
	param_set.opt |= EDMA_TCC(EDMA_CHAN_SLOT(dma_ch1));
	edma_write_slot(dma_ch2, &param_set);

	/* Link both the channels */
	edma_link(dma_ch1, dma_ch2);

	numenabled = bcnt * ccnt;

	for (i = 0; i < numenabled; i++) {
		irqraised1 = 0;

		/* Now enable the transfer as many times as calculated above. */
		result = edma_start(dma_ch1);
		if (result != 0) {
			DMA_PRINTK
			    ("edma3_memtomemcpytest_dma_link: edma_start failed \n");
			break;
		}

		/* Wait for the Completion ISR. */
		while (irqraised1 == 0u) ;

		/* Check the status of the completed transfer */
		if (irqraised1 < 0) {
			/* Some error occured, break from the FOR loop. */
			DMA_PRINTK("edma3_memtomemcpytest_dma_link: "
				   "Event Miss Occured!!!\n");
			break;
		}
	}

	if (result == 0) {
		for (i = 0; i < numenabled; i++) {
			irqraised1 = 0;

			/* Now enable the transfer as many times as calculated above
			 * on the LINK channel.
			 */
			result = edma_start(dma_ch1);
			if (result != 0) {
				DMA_PRINTK
				    ("\nedma3_memtomemcpytest_dma_link: edma_start failed \n");
				break;
			}

			/* Wait for the Completion ISR. */
			while (irqraised1 == 0u) ;

			/* Check the status of the completed transfer */
			if (irqraised1 < 0) {
				/* Some error occured, break from the FOR loop. */
				DMA_PRINTK("edma3_memtomemcpytest_dma_link: "
					   "Event Miss Occured!!!\n");
				break;
			}
		}
	}

	if (0 == result) {
		dma_sync_single_range_for_cpu(NULL, dmaphysdest1,
					      0, (acnt * bcnt * ccnt),
					      DMA_FROM_DEVICE);

		for (i = 0; i < (acnt * bcnt * ccnt); i++) {
			if (dmabufsrc1[i] != dmabufdest1[i]) {
				DMA_PRINTK
				    ("\nedma3_memtomemcpytest_dma_link(1): Data "
				     "write-read matching failed at = %u\n", i);
				Istestpassed1 = 0u;
				break;
			}
		}
		if (i == (acnt * bcnt * ccnt)) {
			Istestpassed1 = 1u;
		}

		dma_sync_single_range_for_cpu(NULL, dmaphysdest2,
					      0, (acnt * bcnt * ccnt),
					      DMA_FROM_DEVICE);

		for (i = 0; i < (acnt * bcnt * ccnt); i++) {
			if (dmabufsrc2[i] != dmabufdest2[i]) {
				DMA_PRINTK
				    ("\nedma3_memtomemcpytest_dma_link(2): Data "
				     "write-read matching failed at = %u\n", i);
				Istestpassed2 = 0u;
				break;
			}
		}
		if (i == (acnt * bcnt * ccnt)) {
			Istestpassed2 = 1u;
		}

		edma_stop(dma_ch1);
		edma_clean_channel(dma_ch1);
		edma_free_slot(dma_ch1);
		edma_free_channel(dma_ch1);

		edma_stop(dma_ch2);
		edma_clean_channel(dma_ch2);
		edma_free_slot(dma_ch2);
		edma_free_channel(dma_ch2);
	}

	if ((Istestpassed1 == 1u) && (Istestpassed2 == 1u)) {
		DMA_PRINTK
		    ("\nedma3_memtomemcpytest_dma_link: EDMA Data Transfer Successfull\n");
	} else {
		DMA_PRINTK
		    ("\nedma3_memtomemcpytest_dma_link: EDMA Data Transfer Failed\n");
	}

	return result;
}

#if defined(GPIO_DMA_EVT)
/* 3. DMA Channel, Mem-2-Mem Copy, ASYNC Mode, INCR Mode, triggered by real event */
static int edma3_gpio_triggered_dma(int acnt, int bcnt, int ccnt, int sync_mode,
				    int event_queue, int event_id)
{
	int result = 0;
	unsigned int dma_ch = 0;
	int i;
	int count;
	unsigned int Istestpassed = 0u;
	unsigned int numenabled = 0;
	struct edmacc_param param_set;

	/* Initalize source and destination buffers */
	for (count = 0; count < (acnt * bcnt * ccnt); count++) {
		dmabufsrc1[count] = 'A' + (count % 26);
		dmabufdest1[count] = 0;
	}
	dma_sync_single_range_for_device(NULL, dmaphyssrc1,
					 0, (acnt * bcnt * ccnt),
					 DMA_TO_DEVICE);

	/*
	 * We use DMA_BIDERCTIONAL on this area since the CPU is both
	 * writing (before DMA) and reading (after DMA) here.
	 */
	dma_sync_single_range_for_device(NULL, dmaphysdest1,
					 0, (acnt * bcnt * ccnt),
					 DMA_BIDIRECTIONAL);

	dma_ch = edma_alloc_channel(event_id, callback1, NULL,
			event_queue);
	if (dma_ch < 0) {
		DMA_PRINTK
		    ("\nedma3_gpio_triggered_dma: edma_alloc_channel failed for dma_ch, error:%d\n",
		     dma_ch);
		return dma_ch;
	}

	param_set.opt = 0;
	param_set.src = (unsigned)dmaphyssrc1;
	param_set.dst = (unsigned)dmaphysdest1;

	param_set.a_b_cnt = (bcnt << 16) | acnt;
	param_set.ccnt = ccnt;

	/* Set B count reload as B count. */
	param_set.link_bcntrld = bcnt << 16;

	/* Setting up the SRC/DES Index */
	param_set.src_dst_bidx = (acnt << 16) | acnt;

	/* A Sync Transfer Mode */
	param_set.src_dst_cidx = (acnt << 16) | acnt;

	/* Enable the Interrupts on Channel 1 */
	param_set.opt |= (ITCINTEN | TCINTEN);
	param_set.opt |= EDMA_TCC(EDMA_CHAN_SLOT(dma_ch));
	edma_write_slot(dma_ch, &param_set);

	numenabled = bcnt * ccnt;

	for (i = 0; i < numenabled; i++) {
		irqraised1 = 0;

		/* Now enable the transfer as many times as calculated above. */
		result = edma_start(dma_ch);
		if (result != 0) {
			DMA_PRINTK
				("edma3_gpio_triggered_dma: edma_start failed for ch %d\n", dma_ch);
			break;
		}

		/* trigger a GPIO event */
		__raw_writel((1 << GPIO_LINE), &g->clr_data);
		__delay(100);
		__raw_writel((1 << GPIO_LINE), &g->set_data);
		__delay(100);

		/* Wait for the Completion ISR. */
		while (irqraised1 == 0u) ;
		if (irqraised1 == 0) {
			/* Some error occured, break from the FOR loop. */
			DMA_PRINTK("edma3_gpio_triggered_dma: "
				   "Event Timeout!\n");
			result = -1;
			break;
		}

		/* Check the status of the completed transfer */
		if (irqraised1 < 0) {
			/* Some error occured, break from the FOR loop. */
			DMA_PRINTK("edma3_gpio_triggered_dma: "
				   "Event Miss Occured!!!\n");
			break;
		}
	}

	if (0 == result) {
		dma_sync_single_range_for_cpu(NULL, dmaphysdest1,
					      0, (acnt * bcnt * ccnt),
					      DMA_FROM_DEVICE);

		for (i = 0; i < (acnt * bcnt * ccnt); i++) {
			if (dmabufsrc1[i] != dmabufdest1[i]) {
				DMA_PRINTK
				    ("\nedma3_gpio_triggered_dma: Data write-read matching failed at = %u\n",
				     i);
				Istestpassed = 0u;
				result = -1;
				break;
			}
		}
		if (i == (acnt * bcnt * ccnt))
			Istestpassed = 1u;

		edma_stop(dma_ch);
		edma_clean_channel(dma_ch);
		edma_free_slot(dma_ch);
		edma_free_channel(dma_ch);
	}

	if (Istestpassed == 1u) {
		DMA_PRINTK
		    ("\nedma3_gpio_triggered_dma: EDMA Data Transfer Successfull \n");
	} else {
		DMA_PRINTK
		    ("\nedma3_gpio_triggered_dma: EDMA Data Transfer Failed \n");
	}

	return result;
}
#endif

module_init(edma_test_init);
module_exit(edma_test_exit);

MODULE_AUTHOR("Texas Instruments");
MODULE_LICENSE("GPL");
