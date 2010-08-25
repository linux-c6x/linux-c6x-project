This is the linux-c6x project

SCOPE:
    This project is intentionally simplistic so we can focus on the basics.
    Right now it is just a set of kernel variants and a root filesystem called
    min-root. It uses a full busybox.
    min-root does a real boot typical of a small system.
    busybox is built for use in min-root

ISSUES
    Builds of SDK0 are problematic due to the version of gcc used in the too wrappers.
    For the purpose of the move to 2.6.34 and ELF DSBT support, the SDK0 was built on
    a RHEL5 system but using a gcc 3.4 based gnupro-04r2-4 toolchain. This SDK0 was
    used as the basis for building the rest of the system components.

    Kernel builds require c6x-elf-as to be in $PATH. This is the FSF binutils version
    of the assembler and is used only for building in the initramfs binary blob. It is
    not used to assemble any code.

BUILDING

    Quick Steps:

    1) Copy setenv.example to setenv and edit for the local configuration.

    2) Run ./setup

    3) Run make to build all targets.


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
        and initramfs instead of NFS root. See dsk6455-initramfs.mk for an
        example of how this is used to point to the objdir used by the dsk6455.mk
        file. This greatly speeds up building since minor changes like cmdline
        won't require a full rebuild of the kernel.


Makefile fragments are provided to build kernels for the DSK6455 and EVMC6472
boards. Variants include initramfs versions with min-root initramfs and a romfs
variant which will look for and use a romfs, ext2, or ext3 filesystem blob
immediately following the kernel in memory.
