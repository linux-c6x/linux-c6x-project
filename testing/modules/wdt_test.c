/*
 * Copyright (C) 2011 Texas Instruments Incorporated
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation version 2.
 *
 * This program is distributed "as is" WITHOUT ANY WARRANTY of any
 * kind, whether express or implied; without even the implied warranty
 * of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 */
#include <linux/module.h>
#include <linux/moduleparam.h>
#include <linux/types.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/miscdevice.h>
#include <linux/watchdog.h>
#include <linux/init.h>
#include <linux/bitops.h>
#include <linux/platform_device.h>
#include <linux/spinlock.h>
#include <linux/uaccess.h>
#include <linux/io.h>
#include <linux/device.h>
#include <linux/clk.h>
#include <linux/slab.h>
#include <linux/sysctl.h>

#include <asm/timer.h>

/*
 * The sole purpose of this module is to expose the watchdog timer status
 * to userspace through /proc/sys/watchdog/status. A script in userspace
 * can use that to see if/when the watchdog expires.
 */

#define MODULE_NAME "WDT_TEST: "

#if defined(CONFIG_SOC_TMS320C6455)
#define WDTIMER TIMER_BASE(TIMER_0)
#elif defined(CONFIG_SOC_TMS320C6457)
#define WDTIMER TIMER_BASE(TIMER_1)
#elif defined(CONFIG_SOC_TMS320C6472)
#define WDTIMER TIMER_BASE(TIMER_0 + get_coreid())
#elif defined(CONFIG_SOC_TMS320C6474)
#define WDTIMER TIMER_BASE(TIMER_5 - get_coreid())
#else
#error "Unknown SoC"
#endif

static int test_proc_dointvec(struct ctl_table *table, int write,
			      void __user *buffer, size_t *lenp, loff_t *ppos);

#define WDTCR	0x28

static int wdflag;

static struct ctl_table_header *wdt_hdr;

static struct ctl_table test_table[] = {
	{
		.procname	= "status",
		.data		= &wdflag,
		.maxlen		= sizeof(int),
		.mode		= 0444,
		.proc_handler	= test_proc_dointvec,
	},
	{ }
};

struct ctl_path test_ctl_path[] = {
	{ .procname = "watchdog", },
	{ },
};

static int test_proc_dointvec(struct ctl_table *table, int write,
			      void __user *buffer, size_t *lenp, loff_t *ppos)
{
	unsigned long val;

	if (!write) {
		val = ioread32(WDTIMER + WDTCR);
		switch(val) {
		case 0:
			/* disabled */
			wdflag = 0;
			break;
		case 0xda7e0000:
			/* enabled */
			wdflag = 1;
			break;
		case 0xda7e8000:
			/* expired */
			wdflag = 2;
			break;
		default:
			/* something else */
			wdflag = val;
			break;
		}
	}

	return proc_dointvec(table, write, buffer, lenp, ppos);
}

static int __init test_init(void)
{

	wdt_hdr = register_sysctl_paths(test_ctl_path, test_table);
	if (wdt_hdr == NULL)
		return -ENOMEM;

	return 0;
}

static void __exit test_exit(void)
{
	unregister_sysctl_table(wdt_hdr);
}

module_init(test_init);
module_exit(test_exit);

MODULE_AUTHOR("Mark Salter");
MODULE_DESCRIPTION("Watchdog Test Driver");

MODULE_LICENSE("GPL");
