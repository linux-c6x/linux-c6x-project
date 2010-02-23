This is the linux-c6x project

SCOPE:
    This project is intentional simplistic so we can focus on the basics.
    Right now it is just a kernel and one of a couple of root filesystems.
    The simplist rootfs is hello-root.  
    hello-root contains one static app that says hello once per second, and the minimum support to boot that app.
    The hello app is built here as well.  It is very simple and links with a static uClibc that is built as part of the sdk target
    min-root is another rootfs choice.  It uses a full busybox.
    min-root does a real boot typical of a small system.
    busybox is built for use in min-root
    [It is out of scope to build a full system w/ lots of packages.  We will use OpenEmbedded for that.]

STATUS
	Build 2.6.13 kernel based on vlx contract deliver 2 2nd try (vlx-D2.1) + ti mods
	    ti mods:
		add initramfs support
		add cio debug outut console
		option for more debug
		make system fixup
	Builds uClibc and busybox
	Build is only Linux hosted
	Tested on:
	    Ubuntu 9.04, 32 bit 
	    Red Hat Enterprise Linux 4.x, 32 bit
	Requires TI code gen 7.0, tested with GA release
	JTAG Debug is only Windows hosted
	Using CCS4 on Win XP connected to on-board jtag
	Supports following boards:
	    DSK6455
	    EVMC6472
	    EVMC6474
	Boots OK
	configures enet and allows telnet login
	debug via gdbserver works OK, some quirks are expected

PREVIOUS STATUS (these were tru in the past; some may need to be reverified)
	Builds have bene done on Ubuntu 8.04 but not recently 
	Sudo access use to be required but no longer is
	Tested on CCS 6446 simulator in windows, hello-root OK
	Tested a bare metal app w/ timers & interrupts on "kelvin" linux command line sim
	Tried linux on kelvin sim for about an hour or two; could not get it to work
	Tried 6455 config on windows device sim, hangs on enet init, would have to work around
	Tested with TI CGTOOLs 6.0.13 (thats what VLX was using) & 7.0 Alpha

KNOWN ISSUES:
	Must use correct length on command line for initramfs or ensure that any remainer is 0
	    previously used zapmem for this purpose
	CCS memory load of binary file: must set size to 32 bits and file size must be multiple of 4
	    size 8 puts 8 bits from file into 32 bits of target
	    if file length is not mod 4 bytes then random pad characters get used for last word (screws up initramfs parsing)
	We are now using a padded initramfs image as a easy way to take care of the above two items
	DSK6455 kernel hangs waiting for MDIO if ENET cable not connected (even if ENET device not used)
	ofd6x segfaults on hello program when creating a dump
	    dump is informational, not really needed


