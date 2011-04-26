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
#include <linux/fs.h>
#include <linux/init.h>
#include <linux/seq_file.h>
#include <linux/proc_fs.h>

/*
 * The sole purpose of this module is to expose a board name to userspace so
 * that test scripts have a reliable way to determine the board on which they
 * are running.
 */
#if defined(CONFIG_ARCH_BOARD_DSK6455)
#define BOARD_NAME "DSK6455"
#elif defined(CONFIG_ARCH_BOARD_EVM6457)
#define BOARD_NAME "EVMC6457"
#elif defined(CONFIG_ARCH_BOARD_EVM6472)
#define BOARD_NAME "EVMC6472"
#elif defined(CONFIG_ARCH_BOARD_EVM6474)
#define BOARD_NAME "EVMC6474"
#elif defined(CONFIG_ARCH_BOARD_EVM6474L)
#define BOARD_NAME "EVMC6474L"
#elif defined(CONFIG_ARCH_BOARD_EVM6678)
#define BOARD_NAME "EVMC6678"
#else
#define BOARD_NAME "UNKNOWN"
#endif

static int test_show(struct seq_file *m, void *v)
{
	seq_printf(m, "%s\n", BOARD_NAME);
}

static int test_open(struct inode *inode, struct file *file)
{
	return single_open(file, test_show, NULL);
}

static const struct file_operations proc_test_file_ops = {
	.owner		= THIS_MODULE,
	.open		= test_open,
	.read		= seq_read,
	.llseek		= seq_lseek,
	.release	= single_release,
};

static int __init test_init(void)
{
	proc_create("boardname", 0, NULL, &proc_test_file_ops);
	return 0;
}

static void __exit test_exit(void)
{
	remove_proc_entry("boardname", NULL);
}

module_init(test_init);
module_exit(test_exit);

MODULE_DESCRIPTION("Board name Driver");
MODULE_LICENSE("GPL");
