This is the linux-c6x project

SCOPE:
This project is intentional simplistic so we can focus on the basics.
Right now it is just a kernel and one of a couple of root filesystems.
The simplist rootfs is hello-root.  
hello-root contains one static app that says hello once per second, and the minimum support to boot that app.
The hello app is built here as well.  It is very simple and links with a [for now] pre-existing uClibc.
[It is TODO to rebuild uClibc]
[It is TBD if we build a very simple lib that is just sys_call, write, sleep, exit, and __main]
min-root is another rootfs choice.  It uses a full busybox and has gdbserver as well.
min-root does a real boot typical of a small system.
[It is TODO to rebuild busybox]
linux-root is the linux rootfs from VLX.  It contains a decent mix of stuff for a small system.
[It is out of scope to build something like this here.  We will use OpenEmbedded for that.]

STATUS
	Right now this builds on at least Ubuntu 8.10 and TI RHEL4 
		RHEL4 tested on GT linux farm but should work dal, hou, etc
	Sudo access is no longer required
	Tested on CCS 6446 simulator in windows
		no HW tests yet
		no linux sim yet
	Tested with TI CGTOOLs 6.0.13 (thats what VLX was using) & 7.0 Alpha

GETTING STARTED:
make sure you have git in your system.
	For TI IT managed boxes you should have it in /apps/free/git/*
	export PATH=/apps/free/git/1.6.0.4/bin:$PATH

clone the linux-c6x git trees
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
	[check my-linux-c6x/product for vmlinux.out and hello-root.cpio.gz.dat]

run it
	I have only run this on a Windows CCS 3.3 6446 simulator
	load vmlinux.out
	edit / memory / fill -> memory from 0x81000000 for length of 0x00300000 bytes
	file / data / load -> 
		**** SELECT "addressable module" ***** 
		THEN select file hello-root.cpio.gz.dat
		leave address & length as is
		OK to load
	Hit "Go"
	Watch the blazing fast simulation speed as the simulator boots linux in less than 30 mins.

	*** If you forget to select "addressable unit" the data will be loaded one byte per 32 bits.  
	Open a memory windown to 0x81000000 to see the data

	[TODO convert bin to elf instead of the stupid TI .dat format?]
	[TODO run on real HW. beagleboard?]
	[get runtime command line passing]
	[run in loadTI?]
	[loadTI sim in linux?]
	[loadTI w/ XDS510 on Windows?]
	[CCSv4]
