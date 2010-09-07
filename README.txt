This is the Linux-c6x project.
version: linux-c6x-0.7.x

SCOPE:
    This project is intentionally simplistic so we can focus on the basics.
    Right now it is just a set of kernel variants and a root filesystem called
    min-root. It uses a full busybox.
    min-root does a real boot typical of a small system.
    busybox is built for use in min-root

    YES Linux-kernel	2.6.34
    YES uClibc
    YES busybox		1.17.1
    YES C6455, C6472, C6474 based 
    YES single core running Linux
    YES Ethernet (all) and UART (evmc6472)

    NO c++
    NO pthreads
    NO gdb
    NO Linux running on multiple cores
    NO Explicit support of RTOS on other cores.
    NO other peripherals / interfaces
    NO Full distribution with lots of packages

ISSUES:
    A full gcc based toolchain is not available for this version of Linux-c6x.

    The TI compiler used for this release is an Alpha version of CGT 7.2.

    Current TI compilers do not accept all GCC language extensions used in
    the kernel, uClibc, and busybox.

    For these reasons a custom "tool wrapper" toolchain is used.  This tool-
    chain is built as part of the sdk0 build process.  This toolchain wraps
    the TI compiler with a frontend that does common command line option 
    translation and uses a customized version of the CIL project to do C to
    C translation.

    A gcc-3.x host compiler must be used when building SDK0 due to the version
    of gcc used in the tool wrappers.  The following are known to work:
	default gcc on RHEL4
	gcc-3.4 from Ubuntu 9.04 on Ubuntu 9.04 or Ubuntu 10.04
	gcc 3.4 based gnupro-04r2-4 toolchain (on a RHEL5 system)

    64 bit host systems have been known to cause issues, especially for SDK0 
    builds.

    Most of the binutils built by sdk0 are not useful as they don't support 
    c6x-elf.  Only the utils found in sdk0/bin are expected to be used.

    Some features in busybox do not work with the current toolchain.  If you 
    customize the configuration of busybox be prepared to work around build 
    issues and do your own testing.

BUILDING:

    Quick Steps:

    1) Run ./setup 
	[It will copy setenv.example to setenv and make some configurations.]

    2) Edit setenv to make any manual configuration changes

    3) Run ./setup

    4) Run make to build all targets.


    One of the variables in setenv is KERNELS_TO_BUILD. This is a space separated list
    of kernels to build. The names in the list correspond to makefile fragments found
    in the kbuilds directory. For example KERNELS_TO_BUILD="dsk6455" refers to
    kbuilds/dsk6455.mk which will be included by the top-level makefile during kernel
    builds. These makefile fragments control a number of things in the kernel build.
    The available variables are:

      DEFCONFIG 
         The name of the kernel config file to use (found in kernel source
         tree at arch/c6x/configs).

      LOCALVERSION
         This is a fixed string which is added to the base kernel version
         to form the full kernel version. For example, building a 2.6.34
         kernel with LOCALVERION=-dsk6455 will result in a full kernel
         version of 2.6.34-dsk6455.

      CMDLINE
         Overrides the CONFIG_CMDLINE found in $(DEFCONFIG)

      PRODVERSION
         An extra string to append to the kernel name when copying vmlinux to the
         product directory. The kernel filename in the product directory ends up
         being (for a 2.6.34 kernel): vmlinux-2.6.34$(LOCALVERION)$(PRODVERSION)

      CONFIGPATCH
         Name of an optional patch file used to patch $(DEFCONFIG). The patchfile
         must be located in the kbuilds directory.

      CONFIGSCRIPT
         Name of an optional shell script to be run after $(DEFCONFIG) is copied
         to the kernel build directory. This shell script must be located in the
         kbuilds directory. See kbuilds/initramfs.sh for an example.

      CONFIGARGS
         A list of arguments to pass the $(CONFIGSCRIPT) when it is run. The first
         argument to $(CONFIGSCRIPT) is always the full pathname to the kernel
         .config file. $(CONFIGARGS) follows after that.

      KOBJNAME
        This is the name of the kernel object directory. Kernels are built out of
        tree and the objects are placed in $(TOP)/kobjs/$(KOBJNAME). By default,
        KOBJNAME is the same as the name used in KERNELS_TO_BUILD with .el or .eb
        added depending on endianess of the build. Overriding this is useful when
        the variant being built only modifies config items which do not effect
        kernel modules. That is, when one variant can use the same modules as some
        other variant. This is the case when only $(CMDLINE) changes, or when using
        an initramfs instead of NFS root. See dsk6455-initramfs.mk for an
        example of how this is used to point to the objdir used by the dsk6455.mk
        file. This greatly speeds up building since minor changes like cmdline
        won't require a full rebuild of the kernel.


    Makefile fragments are provided to build kernels for the DSK6455, EVMC6472,
    and EVMC6474.  

    Example variants include initramfs and romfs versions.  The initramfs
    versions includes the min-root cpio image directly into the kernel.  The 
    romfs variant will look for and use a romfs, ext2, or ext3 filesystem image
    immediately following the kernel in memory.  However look at bootblob for
    another way to combine a kernel and a filesystem that does not require
    rebuilding.
