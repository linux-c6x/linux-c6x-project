This is the linux-c6x project

SCOPE:
This project is intentional simplistic so we can focus on the basics.
Right now it is just a kernel and one of a couple of root filesystems.
The simplist rootfs is hello-root.  
hello-root contains one static app that says hello once per second, and the minimum support to boot that app.
The hello app is built here as well.  It is very simple and links with a [for now] pre-existing uClibc.
[It is TODO to rebuild uClibc]
min-root is another rootfs choice.  It uses a full busybox.
min-root does a real boot typical of a small system.
[It is TODO to rebuild busybox]
[It is out of scope to build a full system w/ lots of packages.  We will use OpenEmbedded for that.]

STATUS
	Build 2.6.13 kernel based on ni-3.0 + my mods
	Use prebuilt uClibc & busybox from VLX
	Build is only Linux hosted
	Tested on Ubuntu 9.04 and TI code gen 7.0 alpha
	Debug is only Windows hosted
	Using CCS4 on Win XP connected to on board jtag of DSK6455 evm
	Boots OK
	TODO: configure enet and telnet

PREVIOUS STATUS (these were tru in the past; some may need to be reverified)
	Builds have bene done on Ubuntu 8.04 and TI RHEL 4 but not recently 
		RHEL4 tested on GT linux farm but should work dal, hou, etc
	Sudo access use to be required but no longer is
	Tested on CCS 6446 simulator in windows, hello-root OK
	Tested a bare metal app w/ timers & interrupts on "kelvin" linux command line sim
	Tried linux on kelvin sim for about an hour or two; could not get it to work
	Tried 6455 config on windows device sim, hangs on enet init, would have to work around
	Tested with TI CGTOOLs 6.0.13 (thats what VLX was using) & 7.0 Alpha

KNOWN ISSUES:
	CCS memory load of binary file: must set size to 32 bits and file size must be multiple of 4
	    size 8 puts 8 bits from file into 32 bits of target
	    if file length is not mod 4 bytes then random pad characters get used for last word (screws up initramfs parsing)
	DSK6455 kernel hangs waiting for MDIO if ENET cable not connected (even if ENET device not used)
	ofd6x segfaults on hello program when creating a dump
	    dump is informational, not really needed


GETTING STARTED:
On Linux host...

make sure you have git in your system.
	For TI IT managed boxes you should have it in /apps/free/git/*
	export PATH=/apps/free/git/1.6.0.4/bin:$PATH

get TI Code Generation 7.0:
	The version I have tested with is here:
	    http://gtwmills.gt.design.ti.com/c6x-linux/ti/cgtool/
	The "best" (but currently unknown) version is here:
	    http://syntaxerror.dal.design.ti.com/release/releases/c60/rel7_0_0_beta2/build/install/
	I install this in ~/opt/cg6x_7_0_0A  (or B2 for beta)

clone the linux-c6x git trees  (will need about 2GB disk space)
	mkdir my-linux-c6x; cd my-linux-c6x
	git clone git://gitweb.dal.design.ti.com/linux-c6x/internal-only/linux-c6x
	git clone git://gitweb.dal.design.ti.com/linux-c6x/internal-only/linux-c6x-project
	git clone git://gitweb.dal.design.ti.com/linux-c6x/internal-only/tool-wrap
	[TODO script for this? use repo?]

setup your instalation
	cd linux-c6x-project
	./setup
	[edit setenv; point to CGTOOLS]
	./setup

build it
	source setenv
	make product
	[check my-linux-c6x/product for vmlinux.out and min-root.pad.bin]

<extra steps for CCSV3>
        cd experiments/zapmem
        ./mk    #to build .out version of zapmem.
        cd ../../rootfs
        ./bin2tidat2.plx min-root.pad.bin  #to build a .dat file that CCSV3
can read in.
on Windows host...

get CCSv4 & test:  (see below for what to do with CCSv3)
    [document where]
    [install]
    [create C make project]
    [create target configuration for onboard JTAG for DSK6455]
    [set dsk6455 as default & active]
    [make sure board has power & enet and usb cables connected]
    [Target -> launch TI debuger]
    [Target -> connect]
    [mount linux machine via samba or copy files in "product" dir]
    [Target -> load program -> zapmem.elf]
    [run, see counsole output]

boot (or debug) linux:
    [continue in  debugger as above]
    [Target -> load program -> vmlinux.out]
    [Takes about a min (unless high latency file share, see above)]
    [Edit default command line (see below) if desired]
    [Open a Memory window, right click, select load memory, browse for min-root.pad.bin, set address to 0xE1000000, set size to 32, OK]
    [Takes about a min]
    [run, debug on CCS console, no input allowed]


< if using CCSv3 (un-offical..) >
    same as above but load and run zapmem.out instead of .elf
    instead of loading memory window with min-root,  use ccsv3 data command to
load min-root.pad.bin.dat into 0xe1000000

<changing linux default_command_line>
   before running linux.out,open a memory window and enter
"default_command_line" as address.  
   switch display format to "char".  This should show you the default command
line string.
   use memory window to:
    - change mac address by altering default mac address after  "emac_addr=" 
    - [static ip] change ip address by altering  address after "ip="
    - [DHCP] enable dhcp by removing ip address after "ip=" 
    - Other IP stuff: see net/ipv4/ipconfig.c for format of ip= substring




