# Top level makefile for linux-c6x project
# Real dumb; always does target and its dependencies
# Any work saving is in the sub-makefiles
# This is intentional not modular or distributed to keep this simple case in one place
# Real distribution build will be done w/ bitbake

ifeq ($(BO),)

# the normal case
def-target: product

else

# if BO=target specified, print the build order w/o doing anything
BUILD_ORDER_TARGETS = $(BO)
def-target: build-order

endif

all: product syslink-all

product: rootfs modules extra-kernels bootblobs

DATE ?= $(shell date +'%Y%m%d')
export DATE

BUILD_USER 	?= $(USER)
BUILD_NAME 	?= dev-$(BUILD_USER)-$(DATE)
BUILD_SUFFIX 	?= -$(BUILD_NAME)
export BUILD_NAME
export BUILD_SUFFIX
export BUILD_USER

V ?= 0
TV ?= $(V)
TOP_VERBOSE ?= $(TV)
export TOP_VERBOSE

ifeq ($(TOP_VERBOSE),0)
QUIET=@
MAKEFLAGS += --no-print-directory
else
QUIET=
endif

BUILD_ORDER_TARGETS ?= "product"
build-order:
	@$(SUB_MAKE) -n $(BUILD_ORDER_TARGETS) 2>&1 | grep "^\*\*\*"

# These targets are valid user command line targets and depend on ENDIAN and FLOAT
TOP_ENDIAN_FLOAT_TARGETS = mtd rio busybox package sdk clib sdk0 clean mtd-clean rio-clean \
	busybox-clean packages-clean clib-clean bootblobs elf-loader mcsdk-demo ltp \
	syslink-user syslink-demo syslink-all min-root mcsdk-demo-root full-root ltp-root

# These are internal sub-targets to support TOP_ENDIAN_FLOAT targets
ENDIAN_FLOAT_TARGETS = $(add-prefix one-,$(TOP_ENDIAN_FLOAT_TARGETS))

SYSLINK_RTOS_TARGETS= syslink-rtos-demo syslink-rtos-all \
	syslink-rtos-ipc syslink-rtos-platform \
	syslink-rtos-notify syslink-rtos-messageq

# These targets are valid user command line targets and depend on ENDIAN and not on FLOAT
TOP_ENDIAN_TARGETS = kernels modules extra-kernels syslink-kernel $(SYSLINK_RTOS_TARGETS)

# These are internal sub-targets to support TOP_ENDIAN targets
ENDIAN_TARGETS = $(add-prefix one-,$(TOP_ENDIAN_TARGETS)) $(add-prefix one-,$(SYSLINK_RTOS_TARGETS))

# These targets are only valid when ENDIAN and KNAME are specificly defined
ENDIAN_KERNEL_TARGETS = one-kernel one-module one-one-syslink-kernel $(add-prefix one-one-,$(SYSLINK_RTOS_TARGETS))

# These targets are only valid when ENDIAN, FLOAT and KNAME are specificly defined
ENDIAN_FLOAT_KERNEL_TARGETS = one-one-syslink-user one-one-syslink-demo one-one-syslink-all

# These targets don't depend on ENDIAN, FLOAT, or KERNEL
TOP_NONE_TARGETS = product rootfs packages all kernel-headers rpm

# all TOP level targets, if the target is not here it is not meant to be one the user command line
TOP_TARGETS = TOP_ENDIAN_FLOAT_TARGETS TOP_ENDIAN_TARGETS TOP_ENDIAN_KERNEL_TARGETS TOP_NONE_TARGETS

$(TOP_TARGETS): sanity

sanity:
	$(QUIET)if [ -z "$$LINUX_C6X_TOP_DIR" ] ; then echo Does not look like setenv has been setup; exit 1; fi
	+$(QUIET)echo $(if $(ONLY),skipping conditional dependencies,using full dependencies)

$(ENDIAN_FLOAT_TARGETS): endian-float-sanity

endian-float-sanity:
	$(QUIET)if [ -z "$(ENDIAN_SUFFIX)" ] || [ -z "$(FLOAT)" ] \
	 || [ "$(ENDIAN)" == "both" ] || [ "$(FLOAT)" == "both" ] \
	 || [ "$(ENDIAN)" == "none" ] || [ "$(FLOAT)" == "none" ] \
	 ; then \
		echo Must define ENDIAN and FLOAT for this target; \
		exit 1; \
	fi

$(ENDIAN_TARGETS): endian-sanity

endian-sanity:
	$(QUIET)if [ -z "$(ENDIAN_SUFFIX)" ] || \
		   [ "$(ENDIAN)" == "both" ] || \
	           [ "$(ENDIAN)" == "none" ] ; then \
		echo "Must define ENDIAN for this target" ; \
		exit 1; \
	fi

$(ENDIAN_KERNEL_TARGETS): endian-kernel-sanity

endian-kernel-sanity:
	$(QUIET)if [ -z "$(ENDIAN_SUFFIX)" ] || [ -z "$(KNAME)" ] || \
		[ "$(ENDIAN)" == "both" ]    || \
		[ "$(ENDIAN)" == "none" ]    || [ "$(KNAME)" == "none" ] ; then \
		echo "Must define ENDIAN and KNAME for this target" ; \
		exit 1; \
	fi

$(NONE_TARGETS): none-sanity


none-sanity:
	true

# For these expand out to all settings of ENDIAN and FLOAT specified
$(TOP_ENDIAN_FLOAT_TARGETS):
	+$(QUIET)if [ -z "$(ENDIAN)" ] || [ "$(ENDIAN)" == "both" ]; then				\
	    if [ -z "$(FLOAT)" ] || [ "$(FLOAT)" == "both" ] ; then					\
		$(SUB_MAKE) ENDIAN=little FLOAT=soft KERNEL_HEADERS_ENDIAN=little one-$@	|| exit 2;	\
		$(SUB_MAKE) ENDIAN=big FLOAT=soft KERNEL_HEADERS_ENDIAN=little one-$@	|| exit 2;	\
		$(SUB_MAKE) ENDIAN=little FLOAT=hard KERNEL_HEADERS_ENDIAN=little one-$@	|| exit 2;	\
		$(SUB_MAKE) ENDIAN=big FLOAT=hard KERNEL_HEADERS_ENDIAN=little one-$@	|| exit 2;	\
	    else											\
		$(SUB_MAKE) ENDIAN=little FLOAT=$(FLOAT) KERNEL_HEADERS_ENDIAN=little one-$@ || exit 2;	\
		$(SUB_MAKE) ENDIAN=big FLOAT=$(FLOAT) KERNEL_HEADERS_ENDIAN=little one-$@   || exit 2;	\
	    fi												\
	else												\
	    if [ -z "$(FLOAT)" ] || [ "$(FLOAT)" == "both" ] ; then					\
		$(SUB_MAKE) ENDIAN=$(ENDIAN) FLOAT=soft KERNEL_HEADERS_ENDIAN=$(ENDIAN) one-$@ || exit 2;	\
		$(SUB_MAKE) ENDIAN=$(ENDIAN) FLOAT=hard KERNEL_HEADERS_ENDIAN=$(ENDIAN) one-$@ || exit 2;	\
	    else											\
		$(SUB_MAKE) ENDIAN=$(ENDIAN) FLOAT=$(FLOAT) KERNEL_HEADERS_ENDIAN=$(ENDIAN) one-$@ || exit 2; \
	    fi												\
	fi

# For these expand out to all settings of ENDIAN specified
$(TOP_ENDIAN_TARGETS):
	+$(QUIET)if [ -z "$(ENDIAN)" ] || [ "$(ENDIAN)" == "both" ]; then				\
		$(SUB_MAKE) ENDIAN=little FLOAT=none KERNEL_HEADERS_ENDIAN=little one-$@ || exit 2;	\
		$(SUB_MAKE) ENDIAN=big FLOAT=none KERNEL_HEADERS_ENDIAN=little one-$@    || exit 2;	\
	else												\
		$(SUB_MAKE) ENDIAN=$(ENDIAN) FLOAT=none KERNEL_HEADERS_ENDIAN=$(ENDIAN) one-$@ || exit 2; \
	fi

ifeq ($(ENDIAN),little)
ARCHendian     = 
ENDIAN_SUFFIX  = .el
else
ifeq ($(ENDIAN),big)
ARCHendian     = eb
ENDIAN_SUFFIX  = .eb
else
ENDIAN =
endif
endif

#
# hard-float/soft-float support
#
ifeq ($(FLOAT),soft)
ARCHfloat      =
FLOAT_SUFFIX   =
else
ifeq ($(FLOAT),hard)
ARCHfloat      = -hf
FLOAT_SUFFIX   = _hardfp
else
FLOAT =
FLOAT_SUFFIX   =
endif
endif

FULL_SUFFIX=$(ENDIAN_SUFFIX)$(FLOAT_SUFFIX)

PRJ=$(LINUX_C6X_PROJECT_DIR)
TOP=$(LINUX_C6X_TOP_DIR)
LINUX_C6X_BUILD_DIR ?= $(LINUX_C6X_TOP_DIR)/Build
BLD=$(LINUX_C6X_TOP_DIR)/Build
TOOL_WRAP_DIR=$(TOP)/ti-gcc-wrap/tool-wrap
RPM_CROSS_DIR=$(BLD)/packages$(FULL_SUFFIX)

ABI           ?= elf
DSBT_SIZE     ?= 64
KERNELS_TO_BUILD ?= evmc6678
EXTRA_KERNELS_TO_BUILD ?=
BUILD_KERNEL_WITH_GCC ?= yes
BUILD_USERSPACE_WITH_GCC ?= yes
BUILD_STATIC_BBOX ?= yes
ROOTFS ?= min-root
DEPMOD	?= /sbin/depmod
BOOTBLOBS ?=
SYSLINK_KERNEL_MODULES_TO_BUILD ?= 
HOSTCC ?= gcc

# ensure all the config ENV vars are exported, even if the definition was from this file
export ABI
export DSBT_SIZE
export HOSTCC
export LINUX_C6X_BUILD_DIR
export RPM_CROSS_DIR

# Kernel build to use for kernel headers
#
# Headers do not change based on board or endian, so pick one kernel
# build and endian to use for kernel headers.
#
KERNEL_HEADERS_KERNEL=$(firstword $(KERNELS_TO_BUILD))
ifeq ($(ENDIAN),big)
KERNEL_HEADERS_ENDIAN ?= big
else
KERNEL_HEADERS_ENDIAN ?= little
endif

# asserts for supported configs in this release
ifneq ($(BUILD_USERSPACE_WITH_GCC),yes)
$(error only GCC supported for userspace)
endif

ifneq ($(BUILD_KERNEL_WITH_GCC),yes)
$(error only GCC supported for kernel)
endif

ifeq ($(ABI),coff)
$(error COFF not supported (and never shall be again))
else
ARCHabi        = elf
EXTRA_CFLAGS=-dsbt
endif

ARCHe		= $(ARCH)$(ARCHendian)
ARCHef          = $(ARCHe)$(ARCHfloat)
FARCH		= $(ARCHe)-$(ARCHabi)
ifeq ($(FLOAT),hard)
# If compiling for C6x with hard float, we consider that as c66x for RPM
RPM_ARCH        = c66x$(ARCHendian)
else
RPM_ARCH        = $(ARCH)$(ARCHendian)
endif

# SDK0 is a compiler only w/o C library. it is used to build kernel and C library
# SDK is SDK0 + c library and is used for busybox and other user apps and libraries

CC_CGT_SDK0=$(SDK0_DIR)/bin/$(FARCH)-linux-
CC_CGT_SDK=$(SDK_DIR)/bin/$(FARCH)-linux-
CC_GCC_SDK0=$(GNU_TOOLS_DIR)/bin/$(ARCH)-uclinux-
CC_GCC_SDK=$(SDK_DIR)/bin/$(ARCH)-uclinux-

ifeq ($(BUILD_KERNEL_WITH_GCC),yes)
CC_SDK0=$(CC_GCC_SDK0)
else
CC_SDK0=$(CC_CGT_SDK0)
endif

ifeq ($(BUILD_USERSPACE_WITH_GCC),yes)
CC_SDK=$(CC_GCC_SDK)
CC_UCLIBC = $(CC_GCC_SDK0)
UCLIBC_CONFIGNAME = uClibc-0.9.30-cs.config
UCLIBC_SRCDIR = $(UCLIBC_DIR)
BUILD_STATIC_BBOX =
ifeq ($(ENDIAN),little)
SYSROOT_DIR_SUBPATH_ENDIAN = $(ARCH)-uclinux/libc
else
SYSROOT_DIR_SUBPATH_ENDIAN = $(ARCH)-uclinux/libc/be
endif
ifeq ($(FLOAT),hard)
SYSROOT_DIR_SUBPATH     = $(SYSROOT_DIR_SUBPATH_ENDIAN)/c674x
else
SYSROOT_DIR_SUBPATH     = $(SYSROOT_DIR_SUBPATH_ENDIAN)
endif
SYSROOT_DIR     = $(SDK_DIR)/$(SYSROOT_DIR_SUBPATH)
SYSROOT_HDR_DIR	= $(SDK_DIR)/$(ARCH)-uclinux/libc
else
CC_SDK=$(CC_CGT_SDK)
CC_UCLIBC = $(CC_CGT_SDK0)
UCLIBC_CONFIGNAME = uClibc-0.9.30-c64xplus-shared.config
UCLIBC_THR_CONFIGNAME = uClibc-0.9.30-c64xplus-shared-thread.config
UCLIBC_SRCDIR = $(UCLIBC_DIR)
SYSROOT_DIR	= $(SDK_DIR)/$(FARCH)-sysroot
endif

BBOX_CONFIGNAME ?= busybox-1.00-full-$(ARCH).config

USERSPACE_CFLAGS   = -O2 -g -mdsbt
USERSPACE_LDFLAGS  = -mdsbt
ifeq ($(ENDIAN),big)
USERSPACE_CFLAGS  += -mbig-endian
USERSPACE_LDFLAGS += -mbig-endian
endif
ifeq ($(FLOAT),hard)
USERSPACE_CFLAGS  += -march=c674x
USERSPACE_LDFLAGS += -march=c674x
endif

ifeq ($(ENDIAN),little)
GDBSERVER = $(GNU_TOOLS_DIR)/c6x-uclinux/libc/usr/bin/gdbserver
else
GDBSERVER = $(GNU_TOOLS_DIR)/c6x-uclinux/libc/be/usr/bin/gdbserver
endif

# install kernel headers here
HDR_DIR = $(BLD)/kernel-headers
KHDR_DIR = $(HDR_DIR)/usr

# install busybox here
BBOX_DIR = $(BLD)/rootfs/busybox-$(ARCHef)

MTD_SRC = $(TOP)/projects/mtd-utils

# install mtd here
MTD_DIR = $(BLD)/rootfs/mtd-utils-$(ARCHef)

RIO_SRC = $(TOP)/projects/rio-utils

#install mcsdk demo here
MCSDK_DEMO_DIR=$(TOP)/projects/c6x-linux-mcsdk-demo

# install rio  here
RIO_DIR = $(BLD)/rootfs/rio-utils-$(ARCHef)

# install syslink stuff here
SYSLINK_DEMO_DIR = $(BLD)/rootfs/syslink-demo-$(KNAME)-$(ARCHef)
SYSLINK_ALL_DIR  = $(BLD)/rootfs/syslink-all-$(KNAME)-$(ARCHef)

PACKAGES_SRC = $(TOP)/projects/packages/
PACKAGES_BIN = $(TOP)/projects/package-downloads/
PACKAGES_DIR = $(BLD)/rootfs/packages-$(ARCHef)

TESTING_DIR = $(PRJ)/testing
TESTMOD_SRC = $(TESTING_DIR)/modules

KOBJ_BASE = $(BLD)/kobjs

SYSROOT_TMP_DIR = $(BLD)/tmp-$(FARCH)-sysroot
SYSROOT_TMP_DIR_THREAD = $(BLD)/tmp-$(FARCH)-sysroot-thread

ifneq ($(KNAME),)
KCONF = $(PRJ)/kbuilds/$(KNAME).mk
ifneq ($(wildcard $(KCONF)),)
include $(KCONF)
endif
ifeq ($(KOBJNAME),)
KOBJNAME = $(KNAME)$(ENDIAN_SUFFIX)
endif
KOBJDIR = $(KOBJ_BASE)/$(KOBJNAME)
KTESTOBJDIR = $(KOBJ_BASE)/test-$(KOBJNAME)
endif

SUB_MAKE=$(MAKE) -f $(PRJ)/Makefile

ONLY=
COND_DEP=$(if $(ONLY),,$(1))

########  kernels
kernels: $(call COND_DEP, sdk0)
one-kernels:
	+$(QUIET)for kname in $(KERNELS_TO_BUILD) ; do \
		if ! $(SUB_MAKE) KNAME=$$kname one-kernel ; then \
			echo "Build of kernel $$kname Failed" ; \
			exit 2; \
		fi \
	done


modules: $(call COND_DEP, kernels syslink-kernel)
one-modules:
	+$(QUIET)for kname in $(KERNELS_TO_BUILD) ; do \
		if ! $(SUB_MAKE) KNAME=$$kname one-module ; then \
			echo "Package of modules for $$kname Failed" ; \
			exit 2; \
		fi \
	done


extra-kernels: $(call COND_DEP, rootfs)
one-extra-kernels:
	+$(QUIET)for kname in $(EXTRA_KERNELS_TO_BUILD) ; do \
		if ! $(SUB_MAKE) KNAME=$$kname one-kernel ; then \
			echo "Build of extra kernel $$kname Failed" ; \
			exit 2; \
		fi \
	done

one-kernel: productdir
	+$(QUIET)echo "********** kernel $(KNAME) ENDIAN=$(ENDIAN)"
	+$(SUB_MAKE) -C $(LINUX_C6X_KERNEL_DIR) CROSS_COMPILE=$(CC_SDK0) KNAME=$(KNAME) kernel-sub ; \

KERNEL_FNAME=`cat $(KOBJDIR)/include/config/kernel.release`$(PRODVERSION)
# install kernel modules here
MOD_DIR = $(KOBJ_BASE)/modules-$(KERNEL_FNAME)
TEST_MOD_DIR = $(KOBJ_BASE)/test-modules-$(KERNEL_FNAME)
kernel-sub:
	$(QUIET)if [ -z "$(KNAME)" ] ; then echo Must define KNAME for this target; exit 1; fi
	[ -d $(KOBJDIR) ] || mkdir -p $(KOBJDIR)
	cp arch/$(ARCH)/configs/$(DEFCONFIG) $(KOBJDIR)/.config
	[ -z "$(CONFIGPATCH)" ] || patch -p1 -d $(KOBJDIR) -i $(PRJ)/kbuilds/$(CONFIGPATCH)
	[ -z "$(CONFIGSCRIPT)" ] || $(PRJ)/kbuilds/$(CONFIGSCRIPT) $(KOBJDIR)/.config $(CONFIGARGS)
	[ "$(ENDIAN)" == "little" ] || \
	   sed -i -e 's,# CONFIG_CPU_BIG_ENDIAN is not set,CONFIG_CPU_BIG_ENDIAN=y,' $(KOBJDIR)/.config
	[ "$(BUILD_KERNEL_WITH_GCC)" != "yes" ] || \
	   sed -i -e 's,CONFIG_TI_C6X_COMPILER=y,# CONFIG_TI_C6X_COMPILER is not set,' \
		-e 's,CONFIG_TI_C6X_LINKER=y,# CONFIG_TI_C6X_LINKER is not set,' \
		$(KOBJDIR)/.config
	[ -z "$(LOCALVERSION)" ] || \
	   sed -i -e 's,CONFIG_LOCALVERSION=.*,CONFIG_LOCALVERSION="$(LOCALVERSION)",' $(KOBJDIR)/.config
	[ -z "$(CMDLINE)" ] || \
	   sed -i -e 's%CONFIG_CMDLINE=.*%CONFIG_CMDLINE="$(CMDLINE)"%' $(KOBJDIR)/.config
	make ARCH=$(ARCH) O=$(KOBJDIR)/ oldconfig
	make ARCH=$(ARCH) O=$(KOBJDIR)/
	make ARCH=$(ARCH) O=$(KOBJDIR)/ DEPMOD=$(DEPMOD) INSTALL_MOD_PATH=$(MOD_DIR) modules_install
	mkdir -p $(KTESTOBJDIR) ; \
	cp -r $(TESTMOD_SRC)/* $(KTESTOBJDIR) ; \
	make ARCH=$(ARCH) O=$(KOBJDIR)/ M=$(KTESTOBJDIR) DEPMOD=$(DEPMOD) \
		INSTALL_MOD_PATH=$(TEST_MOD_DIR) modules modules_install ; \
	cp $(KOBJDIR)/vmlinux $(PRODUCT_DIR)/vmlinux-$(KERNEL_FNAME)
	objcopy -I elf32-$(ENDIAN) -O binary $(PRODUCT_DIR)/vmlinux-$(KERNEL_FNAME) $(PRODUCT_DIR)/vmlinux-$(KERNEL_FNAME).bin

one-module: productdir
	+$(QUIET)echo "********** modules $(KNAME) ENDIAN=$(ENDIAN)"
	if [ -d $(MOD_DIR)      ] ; then (cd $(MOD_DIR);      tar czf $(PRODUCT_DIR)/modules-$(KERNEL_FNAME).tar.gz      * ); fi
	if [ -d $(TEST_MOD_DIR) ] ; then (cd $(TEST_MOD_DIR); tar czf $(PRODUCT_DIR)/test-modules-$(KERNEL_FNAME).tar.gz * ); fi

kernel-headers: kernels
	+$(QUIET)echo "********** $@"
	+$(SUB_MAKE) -C $(LINUX_C6X_KERNEL_DIR) CROSS_COMPILE=$(CC_SDK0) \
		ENDIAN=$(KERNEL_HEADERS_ENDIAN) KNAME=$(KERNEL_HEADERS_KERNEL) kernel-headers-sub

kernel-headers-sub:
	if [ ! -d $(KHDR_DIR)/include/asm ]; then   \
		mkdir -p $(KHDR_DIR) ;  \
		make -C $(LINUX_C6X_KERNEL_DIR) ARCH=$(ARCH) CROSS_COMPILE=$(CC_SDK0) \
		        INSTALL_HDR_PATH=$(KHDR_DIR) O=$(KOBJDIR) headers_install ; \
	fi

one-kernels-clean:
	+for kname in $(KERNELS_TO_BUILD) ; do \
		$(SUB_MAKE) -C $(LINUX_C6X_KERNEL_DIR) CROSS_COMPILE=$(CC_SDK0) KNAME=$$kname kernel-clean-sub ; \
	done

kernel-clean-sub:
	rm -rf $(KOBJDIR)

########  C library
clib: $(call COND_DEP, sdk0 kernel-headers)
one-clib:
	+$(QUIET)echo "********** clib ENDIAN=$(ENDIAN) FLOAT=$(FLOAT)"
	[ -d $(BLD)/uClibc$(FULL_SUFFIX) ] || mkdir -p $(BLD)/uClibc$(FULL_SUFFIX)
	cp -a $(UCLIBC_SRCDIR)/* $(BLD)/uClibc$(FULL_SUFFIX)
	$(SUB_MAKE) -C $(BLD)/uClibc$(FULL_SUFFIX) CROSS_COMPILE=ensure_not_used CROSS=$(CC_UCLIBC) clib-sub
	if [ "$(BUILD_USERSPACE_WITH_GCC)" != "yes" ] ; then \
		[ -d $(BLD)/uClibc-pthread$(FULL_SUFFIX) ] || mkdir -p $(BLD)/uClibc-pthread$(FULL_SUFFIX) ; \
		cp -a $(UCLIBC_SRCDIR)/* $(BLD)/uClibc-pthread$(FULL_SUFFIX) ; \
		+$(SUB_MAKE) -C $(BLD)/uClibc-pthread$(FULL_SUFFIX) CROSS_COMPILE=ensure_not_used CROSS=$(CC_UCLIBC) clib-sub-pthread ; \
	fi

UCLIBC_CONFIG = $(PRJ)/uclibc-configs/$(UCLIBC_CONFIGNAME)

$(BLD)/uClibc$(FULL_SUFFIX)/.config: $(UCLIBC_CONFIG)
	cp $(UCLIBC_CONFIG) .config
	if [ "$(BUILD_USERSPACE_WITH_GCC)" == "yes" ] ; then \
	    sed -i -e 's,USE_TI_C6X_COMPILER=y,# USE_TI_C6X_COMPILER is not set,' \
		   -e 's,USE_TI_C6X_LINKER=y,# USE_TI_C6X_LINKER is not set,' \
	    	   -e 's,CROSS_COMPILER_PREFIX=*,CROSS_COMPILER_PREFIX="$(CROSS)",' \
		   .config ; \
	    if [ "$(ENDIAN)" != "little" ] ; then \
		    sed -i -e 's,ARCH_LITTLE_ENDIAN=y,ARCH_BIG_ENDIAN=y,' \
			   -e 's,ARCH_WANTS_LITTLE_ENDIAN=y,# ARCH_WANTS_LITTLE_ENDIAN is not set,' \
			   -e 's,# ARCH_WANTS_BIG_ENDIAN is not set,ARCH_WANTS_BIG_ENDIAN=y,' \
		   .config ; \
	    fi ; \
	    if [ "$(FLOAT)" == "hard" ] ; then \
		    sed -i -e 's,UCLIBC_HAS_SOFT_FLOAT=y,# UCLIBC_HAS_SOFT_FLOAT is not set,' \
			   -e 's,# UCLIBC_HAS_FPU is not set,UCLIBC_HAS_FPU=y,' \
			   -e 's,UCLIBC_EXTRA_CFLAGS=*,UCLIBC_EXTRA_CFLAGS="-march=c674x",' \
		   .config ; \
	    fi \
	fi
	make oldconfig

UCLIBC_THR_CONFIG = $(PRJ)/uclibc-configs/$(UCLIBC_THR_CONFIGNAME)

$(BLD)/uClibc-pthread$(FULL_SUFFIX)/.config: $(UCLIBC_THR_CONFIG)
	cp $(UCLIBC_THR_CONFIG) .config
	make oldconfig

clib-sub: $(BLD)/uClibc$(FULL_SUFFIX)/.config
	make

clib-sub-pthread: $(BLD)/uClibc-pthread$(FULL_SUFFIX)/.config
	make

one-clib-clean:
	rm -rf $(BLD)/uClibc$(FULL_SUFFIX)
	rm -rf $(BLD)/uClibc-pthread$(FULL_SUFFIX)

########  SDKs

# SDK0 (if used or needed) is just the compiler w/o any C libraries and 
# is needed to build the kernel
# SDK0 is not built if you have a prebuilt toolchain
# Currently GCC is always precompiled 
one-sdk0:
	+$(QUIET)echo "********** sdk0 ENDIAN=$(ENDIAN) FLOAT=$(FLOAT)"
	$(QUIET)if [ -e $(SDK0_DIR)/linux-$(ARCHe)-sdk0-prebuilt ] ; then 	\
	    echo "using pre-built sdk0";				\
	else	    						\
	    if [ "$(BUILD_KERNEL_WITH_GCC)" != "yes" ] ; then  \
		    if [ -e $(TOOL_WRAP_DIR)/Makefile ] ; then 	\
			cd $(TOOL_WRAP_DIR); $(MAKE) ENDIAN=$(ENDIAN) ABI=$(ABI) DSBT_SIZE=$(DSBT_SIZE) \
				GCC_C6X_DEST=$(SDK0_DIR) ALIAS=$(ALIAS) all;	\
		    else					\
			echo "You must install the prebuilt sdk0 or the build kit for it";	\
			false;					\
		fi;						\
	    fi;							\
	fi;							

sdk0-keep:
	$(QUIET)touch $(SDK0_DIR)/linux-c6x-sdk0-prebuilt
	$(QUIET)touch $(SDK0_DIR)/linux-c6xeb-sdk0-prebuilt

sdk0-unkeep:
	$(QUIET)rm -f $(SDK0_DIR)/linux-c6x-sdk0-prebuilt
	$(QUIET)rm -f $(SDK0_DIR)/linux-c6xeb-sdk0-prebuilt

sdk0-clean:
	$(QUIET)if [ -e $(SDK0_DIR)/linux-c6x-sdk0-prebuilt ] ; then 	\
	    echo "using pre-built sdk0 (skip clean)";		\
	else	    						\
	    if [ -e $(SDK0_DIR)/bin/$(FARCH)-linux-gcc ] ; then 	\
		rm -rf $(SDK0_DIR); 				\
	    fi;							\
	    if [ -e $(TOOL_WRAP_DIR)/Makefile ] ; then 		\
		cd $(TOOL_WRAP_DIR); $(MAKE) ENDIAN=$(ENDIAN) ABI=$(ABI) GCC_C6X_DEST=$(SDK0_DIR) ALIAS=$(ALIAS) clean;	\
	    fi;							\
	fi							\

# SDK is the toolchain plus the fundamental libraries and is needed to build the userspace components
sdk: $(call COND_DEP, sdk0 clib)
one-sdk:
	+$(QUIET)echo "********** sdk ENDIAN=$(ENDIAN) FLOAT=$(FLOAT)"
	[ -e $(SYSROOT_DIR) ] || mkdir -p $(SYSROOT_DIR)
        # Just updating with new files. Re-visit it later as needed
	+$(QUIET)if [ "$(BUILD_USERSPACE_WITH_GCC)" != "yes" ] ; then \
		$(SUB_MAKE) one-sdk-cgt ; \
	else \
		$(SUB_MAKE) one-sdk-gcc ; \
	fi

one-sdk-cgt:
	[ -e $(SYSROOT_TMP_DIR) ] || mkdir -p $(SYSROOT_TMP_DIR)
	cp -a $(SDK0_DIR)/* $(SDK_DIR)
	[ -d $(SYSROOT_TMP_DIR)/usr/include/asm ] || cp -a $(KHDR_DIR) $(SYSROOT_TMP_DIR)
	(cd $(SDK_DIR)/bin; ls c6x-* | cut -d\- -f4 | sort -u | xargs -i ln -sf $(ARCH)-elf-linux-"{}" $(ARCH)-linux-"{}" )
	(cd $(SDK_DIR)/bin; ls c6xeb-* | cut -d\- -f4 | sort -u | xargs -i ln -sf $(ARCH)eb-elf-linux-"{}" $(ARCH)eb-linux-"{}" )
	make -C $(BLD)/uClibc$(FULL_SUFFIX) CROSS=$(CC_SDK0) PREFIX=$(SYSROOT_TMP_DIR) install
	[ -e $(SYSROOT_TMP_DIR_THREAD) ] || mkdir -p $(SYSROOT_TMP_DIR_THREAD)
	make -C $(BLD)/uClibc-pthread$(FULL_SUFFIX) CROSS=$(CC_SDK0) PREFIX=$(SYSROOT_TMP_DIR_THREAD) install
	mv -f $(BLD)/uClibc-pthread$(FULL_SUFFIX)/lib/libc.a $(BLD)/uClibc-pthread$(FULL_SUFFIX)/lib/libc-pthread.a
	rsync -rlpgocv --ignore-existing $(SYSROOT_TMP_DIR_THREAD)/ $(SYSROOT_TMP_DIR)/
	rsync -rlpgocv --delete $(SYSROOT_TMP_DIR)/ $(SYSROOT_DIR)/

one-sdk-gcc:
	cp -a $(GNU_TOOLS_DIR)/{bin,lib,libexec,share} $(SDK_DIR)
	cp -a $(GNU_TOOLS_DIR)/$(ARCH)-uclinux/{bin,lib,share,include} $(SDK_DIR)/$(ARCH)-uclinux
	[ -d $(SYSROOT_HDR_DIR)/usr/include/asm ] || cp -a $(KHDR_DIR) $(SYSROOT_HDR_DIR)
	(cd $(SDK_DIR)/bin; ls | cut -d\- -f3 | sort -u | xargs -i ln -sf $(ARCH)-uclinux-"{}" $(ARCH)-linux-"{}" )
	(cd $(SDK_DIR)/bin; ls | cut -d\- -f3 | sort -u | xargs -i ln -sf $(ARCH)-uclinux-"{}" $(ARCH)eb-linux-"{}" )
	[ -d $(SYSROOT_DIR)/lib ] || mkdir -p $(SYSROOT_DIR)/lib
	[ -d $(SYSROOT_DIR)/usr/lib ] || mkdir -p $(SYSROOT_DIR)/usr/lib
	make -C $(BLD)/uClibc$(FULL_SUFFIX) CROSS=$(CC_UCLIBC) PREFIX=$(SYSROOT_DIR) install
	if [ "$(SYSROOT_DIR)" != "$(SYSROOT_HDR_DIR)" ]; then \
	    cp -r $(SYSROOT_DIR)/usr/include/* $(SYSROOT_HDR_DIR)/usr/include ; \
	    rm -rf $(SYSROOT_DIR)/usr/include ; \
	fi
	cp -a $(GNU_TOOLS_DIR)/$(SYSROOT_DIR_SUBPATH)/usr/lib/libstdc++.a $(SYSROOT_DIR)/usr/lib/

sdk-clean:
	rm -rf $(SDK_DIR)

one-sdk-clean:
	rm -rf $(SYSROOT_DIR)
	[ -d $(SDK_DIR)/c6x-sysroot -o -d $(SDK_DIR)/c6xeb-sysroot ] || rm -rf $(SDK_DIR)

########  Busybox
BBOX_CONFIG = $(BLD)/busybox$(FULL_SUFFIX)/$(BBOX_CONFIGNAME)

busybox:   $(call COND_DEP, sdk)
one-busybox:
	+$(QUIET)echo "********** busybox ENDIAN=$(ENDIAN) FLOAT=$(FLOAT)"
	[ -d $(BLD)/busybox$(FULL_SUFFIX) ] || mkdir -p $(BLD)/busybox$(FULL_SUFFIX)
	cp $(PRJ)/busybox-configs/$(BBOX_CONFIGNAME) $(BBOX_CONFIG)
	if [ "$(BUILD_USERSPACE_WITH_GCC)" == "yes" ] ; then \
	    sed -i -e 's,CONFIG_CROSS_COMPILER_PREFIX=*,CONFIG_CROSS_COMPILER_PREFIX="$(CC_SDK)",' \
		   -e 's,-dsbt,-mdsbt -D__DSBT__,' \
		 $(BBOX_CONFIG) ; \
	    if [ "$(ENDIAN)" != "little" ] ; then \
		sed -i -e 's,-D__DSBT__,-D__DSBT__ -mbig-endian,' \
		   $(BBOX_CONFIG) ; \
	    fi ; \
	    if [ "$(FLOAT)" == "hard" ] ; then \
		sed -i -e 's,-D__DSBT__,-D__DSBT__ -march=c674x,' \
		   $(BBOX_CONFIG) ; \
	    fi \
	fi
	$(SUB_MAKE) -C $(BLD)/busybox$(FULL_SUFFIX) \
		CONF=$(BBOX_CONFIG) CROSS=$(CC_SDK) ENDIAN=$(ENDIAN) FLOAT=$(FLOAT) busybox-sub ; \

ifeq ($(BUILD_STATIC_BBOX),yes)
BBOX_EXTRA = -static
endif
ifeq ($(BUILD_USERSPACE_WITH_GCC),yes)
ifneq ($(ENDIAN),little)
BBOX_EXTRA += -mbig-endian
endif
endif

BBOX_MAKE = make ARCH=$(ARCH) CROSS_COMPILE=$(CC_SDK) KBUILD_SRC=$(TOP)/busybox \
		-f $(TOP)/busybox/Makefile

busybox-sub: $(BLD)/busybox$(FULL_SUFFIX)/.config_done
	rm -rf $(BBOX_DIR)
	mkdir -p $(BBOX_DIR)
	$(BBOX_MAKE) EXTRA_LDFLAGS="$(BBOX_EXTRA)"
	$(BBOX_MAKE) EXTRA_LDFLAGS="$(BBOX_EXTRA)" CONFIG_PREFIX=$(BBOX_DIR) install

$(BLD)/busybox$(FULL_SUFFIX)/.config_done: $(CONF) $(PRJ)/Makefile
	cp $(CONF) .config
	$(BBOX_MAKE) oldconfig
	cp $(CONF) $@

one-busybox-clean:
	rm -rf $(BLD)/busybox$(FULL_SUFFIX)

########  Other userspace components
### MTD
mtd: $(call COND_DEP, sdk)
one-mtd: 
	+$(QUIET)echo "********** mtd ENDIAN=$(ENDIAN) FLOAT=$(FLOAT)"
	[ -d $(BLD)/mtd-utils$(FULL_SUFFIX) ] || mkdir -p $(BLD)/mtd-utils$(FULL_SUFFIX)
	$(SUB_MAKE) -C $(BLD)/mtd-utils$(FULL_SUFFIX) CROSS=$(CC_SDK) ENDIAN=$(ENDIAN) mtd-sub

MTD_LDFLAGS = $(USERSPACE_LDFLAGS) -static
MTD_CFLAGS = $(USERSPACE_CFLAGS)

MTD_MAKE = make -C $(MTD_SRC) CROSS=$(CC_SDK) SUBDIRS= DESTDIR=$(MTD_DIR) \
	BUILDDIR=$(BLD)/mtd-utils$(FULL_SUFFIX) LDFLAGS="$(MTD_LDFLAGS)" CFLAGS="$(MTD_CFLAGS)"

mtd-sub:
	rm -rf $(MTD_DIR)
	mkdir -p $(MTD_DIR)
	$(MTD_MAKE) install

one-mtd-clean:
	rm -rf $(BLD)/mtd-utils$(FULL_SUFFIX)

### mcsdk-demo
one-mcsdk-demo:
	+$(QUIET)echo "********** mcsdk-demo ENDIAN=$(ENDIAN) FLOAT=$(FLOAT)"
	if [ -d $(MCSDK_DEMO_DIR) ]; then \
		[ -d $(BLD)/mcsdk-demo$(FULL_SUFFIX) ] || mkdir -p $(BLD)/mcsdk-demo$(FULL_SUFFIX) ; \
		cp -a $(MCSDK_DEMO_DIR)/* $(BLD)/mcsdk-demo$(FULL_SUFFIX) ; \
		(cd $(BLD)/mcsdk-demo$(FULL_SUFFIX); make CROSS=$(CC_SDK) ENDIAN=$(ENDIAN) FLOAT=$(FLOAT)) ; \
	else \
		echo "install $(MCSDK_DEMO_DIR) and re-run build"; \
		exit; \
	fi

one-mcsdk-demo-clean:
	rm -rf $(BLD)/mcsdk-demo$(FULL_SUFFIX)

### mcoreloader
elf-loader: $(call COND_DEP, sdk)
one-elf-loader:
	+$(QUIET)echo "********** mcoreloader ENDIAN=$(ENDIAN) FLOAT=$(FLOAT)"
# TODO currently support only C6678. So hard coded
	[ -d $(BLD)/elf-loader$(FULL_SUFFIX) ] || mkdir -p $(BLD)/elf-loader$(FULL_SUFFIX) ; \
	cp -a $(TOP)/linux-c6x-project/tools/elfloader/* $(BLD)/elf-loader$(FULL_SUFFIX) ; \
	(cd $(BLD)/elf-loader$(FULL_SUFFIX); make DEVICE=C6678 CROSS=$(CC_SDK) ENDIAN=$(ENDIAN) FLOAT=$(FLOAT) ) ;

one-elf-loader-clean:
	rm -rf $(BLD)/elf-loader$(FULL_SUFFIX)

### RapidIO utilities
RIO_CFLAGS = $(USERSPACE_CFLAGS)

rio: $(call COND_DEP, sdk)
one-rio:
	+$(QUIET)echo "********** rio ENDIAN=$(ENDIAN) FLOAT=$(FLOAT)"
	[ -d $(BLD)/rio-utils$(FULL_SUFFIX) ] || mkdir -p $(BLD)/rio-utils$(FULL_SUFFIX)
	make -f $(RIO_SRC)/Makefile -C $(RIO_SRC) CC="$(CC_SDK)gcc" EXTRA_CFLAGS="$(RIO_CFLAGS)" BUILDIR=$(BLD)/rio-utils$(FULL_SUFFIX) DESTDIR=$(RIO_DIR)
	make -f $(RIO_SRC)/Makefile -C $(RIO_SRC) CC="$(CC_SDK)gcc" EXTRA_CFLAGS="$(RIO_CFLAGS)" BUILDIR=$(BLD)/rio-utils$(FULL_SUFFIX) DESTDIR=$(RIO_DIR) install

one-rio-clean:
	rm -rf $(BLD)/rio-utils$(FULL_SUFFIX)

### LTP
ltp: $(call COND_DEP, sdk)
one-ltp:
	+$(QUIET)echo "********** ltp ENDIAN=$(ENDIAN) FLOAT=$(FLOAT)"
	[ -d $(BLD)/ltp$(FULL_SUFFIX) ] || mkdir -p $(BLD)/ltp$(FULL_SUFFIX)
	(cd $(PRJ)/testing/ltp; make TOP_DIR=${TOP} ENDIAN=${ENDIAN} FLOAT=${FLOAT} GCC=true all);\
	cp $(BLD)/ltp$(FULL_SUFFIX)/testdriver ${TOP}/product

one-ltp-clean:
	rm -rf $(BLD)/ltp$(FULL_SUFFIX)

### Packages built with cross rpm
rpm: $(BLD)/rpm-done.txt

$(SDK_DIR)/rpm: $(BLD)/rpm-done.txt

$(BLD)/rpm-done.txt:
	+$(QUIET)echo "********** rpm"
	$(PRJ)/cross-rpm/build-rpm.sh

rpm-clean:
	rm -rf $(BLD)/rpm-done.txt
	rm -rf $(BLD)/rpm-4.0.4
	rm -rf $(SDK_DIR)/rpm


$(PKG_LIST): $(call COND_DEP, rpm sdk)
	+$(SUB_MAKE) PKG_LIST="$@" package

packages:  $(PKG_LIST)

package:
one-package:
	+$(QUIET)echo "********** package $(PKG_LIST) ENDIAN=$(ENDIAN) FLOAT=$(FLOAT)"
	$(QUIET)if [ "$(BUILD_USERSPACE_WITH_GCC)" != "yes" ] ; then echo "cannot build packages without GCC"; exit 1; fi
	mkdir -p $(RPM_CROSS_DIR)/tmp
	mkdir -p $(RPM_CROSS_DIR)/db
	mkdir -p $(RPM_CROSS_DIR)/SOURCES
	mkdir -p $(RPM_CROSS_DIR)/SPECS
	mkdir -p $(RPM_CROSS_DIR)/SRPMS
	mkdir -p $(RPM_CROSS_DIR)/RPMS
	mkdir -p $(RPM_CROSS_DIR)/BUILD
	cp -flr $(PACKAGES_SRC)/*/* $(RPM_CROSS_DIR)/SOURCES/
	cp -fl $(PACKAGES_BIN)/* $(RPM_CROSS_DIR)/SOURCES/
	cp -fl $(PACKAGES_SRC)/*/*.spec $(RPM_CROSS_DIR)/SPECS/
	(export CROSS_ROOTDEVDIR=$(SYSROOT_DIR) ;$(PRJ)/cross-rpm/pkg_build_all $(RPM_ARCH))
	[ -d $(PACKAGES_DIR) ] || mkdir -p $(PACKAGES_DIR)
	(export CROSS_ROOTDIR=$(PACKAGES_DIR) ; $(PRJ)/cross-rpm/pkg_install_linuxroot $(RPM_ARCH))

one-packages-clean:
	rm -rf $(RPM_CROSS_DIR)

SYSLINK_PLATFORMS = evmc6678 evmc6670 evmc6472 evmc6474 evmc6474-lite
###  Syslink targets
ifeq ($(BUILD_SYSLINK),yes)
SYSLINKS_TO_BUILD = $(filter $(SYSLINK_PLATFORMS),$(KERNELS_TO_BUILD))
else
SYSLINKS_TO_BUILD = ""
endif

MID_SYSLINK_TARGETS = one-syslink-kernel one-syslink-user \
	one-syslink-rtos-demo one-syslink-rtos-all	\
	one-syslink-rtos-ipc  one-syslink-rtos-platform \
	one-syslink-rtos-notify one-syslink-rtos-messageq \
	one-syslink-demo one-syslink-all

SYSLINK_DEMO_RTOS_SAMPLES=syslink-rtos-notify syslink-rtos-messageq

syslink: syslink-all
syslink-demo: syslink-kernel syslink-user syslink-rtos-demo
syslink-all:  syslink-kernel syslink-user syslink-rtos-all
syslink-kernel:   $(call COND_DEP, kernels)
syslink-user:     $(call COND_DEP, sdk)
syslink-rtos-demo: $(SYSLINK_DEMO_RTOS_SAMPLES)
$(SYSLINK_DEMO_RTOS_SAMPLES): syslink-rtos-ipc syslink-rtos-platform

$(MID_SYSLINK_TARGETS):
	+$(QUIET)for kname in $(SYSLINKS_TO_BUILD) ; do \
		if ! $(SUB_MAKE) IS_SYSLINK_BUILD=1 KNAME=$$kname one-$@ ; then \
			echo "Build of $@ for $$kname Failed" ; \
			exit 2; \
		fi \
	done

one-one-syslink-rtos-demo:
	$(QUIET)true

syslink-clean:
	for kname in $(SYSLINKS_TO_BUILD) ; do \
		rm -rf $(BLD)/syslink_$$kname* ; \
	done

include $(PRJ)/scripts/Makefile.syslink

########  Root filesystems
rootfs: bootblob $(ROOTFS) bootblob

min-root: $(call COND_DEP, busybox mtd)
one-min-root: min-root-$(ARCHef)
min-root-$(ARCHef): productdir
	+$(QUIET)echo "********** min-root ENDIAN=$(ENDIAN) FLOAT=$(FLOAT)"
	if [ -d $(BLD)/rootfs/$@ -a -e $(BLD)/rootfs/$@-marker ] ; then rm -rf $(BLD)/rootfs/$@; fi
	mkdir -p $(BLD)/rootfs/$@; date > $(BLD)/rootfs/$@-marker
	(cd $(BLD)/rootfs/$@; cpio -i <$(PRJ)/rootfs/min-root-skel.cpio)
	cp -a rootfs/min-root-extra/* $(BLD)/rootfs/$@
	cp -a $(BBOX_DIR)/* $(BLD)/rootfs/$@
	cp -a $(MTD_DIR)/* $(BLD)/rootfs/$@
	#cp -a $(MOD_DIR)/* $(BLD)/rootfs/$@
	if [ -n $(EXTRA_ROOT_DIR) ] ; then for dir in $(EXTRA_ROOT_DIR); do cp -a $$dir/rootfs/* $(BLD)/rootfs/$@ ; done ; fi
	if [ -e $(GDBSERVER) ] ; then cp $(GDBSERVER) $(BLD)/rootfs/$@/usr/bin ; fi
	(cd $(SYSROOT_DIR) ; tar --exclude='*.a' -cf - lib | (cd $(BLD)/rootfs/$@; tar xf -))
	(cd $(SYSROOT_DIR) ; tar --exclude='*.a' -cf - usr/lib | (cd $(BLD)/rootfs/$@; tar xf -))
	cp rootfs/min-root-devs.cpio $(BLD)/rootfs/$@.cpio
	(cd $(BLD)/rootfs/$@; find . | cpio -H newc -o -A -O ../$@.cpio)
	gzip -c $(BLD)/rootfs/$@.cpio > $(PRODUCT_DIR)/$@.cpio.gz

mcsdk-demo-root: $(call COND_DEP, busybox mtd mcsdk-demo syslink-demo elf-loader)
one-mcsdk-demo-root: mcsdk-demo-root-$(ARCHef)
mcsdk-demo-root-$(ARCHef): productdir
	+$(QUIET)echo "********** mcsdk-root ENDIAN=$(ENDIAN) FLOAT=$(FLOAT)"
	if [ -d $(BLD)/rootfs/$@ -a -e $(BLD)/rootfs/$@-marker ] ; then rm -rf $(BLD)/rootfs/$@; fi
	mkdir -p $(BLD)/rootfs/$@; date > $(BLD)/rootfs/$@-marker
	(cd $(BLD)/rootfs/$@; cpio -i <$(PRJ)/rootfs/min-root-skel.cpio)
	cp -a rootfs/min-root-extra/* $(BLD)/rootfs/$@
	rm -rf $(BLD)/rootfs/$@/web
	# call mcsdk demo install
	(cd $(BLD)/mcsdk-demo$(FULL_SUFFIX); make CROSS=$(CC_SDK) ENDIAN=$(ENDIAN) FLOAT=$(FLOAT) INSTALL_PREFIX=$(BLD)/rootfs/$@ install )
	(cd $(BLD)/elf-loader$(FULL_SUFFIX); make CROSS=$(CC_SDK) ENDIAN=$(ENDIAN) FLOAT=$(FLOAT) INSTALL_PREFIX=$(BLD)/rootfs/$@/usr/bin install )
	#cp -a $(SYSLINK_DEMO_DIR)/* $(BLD)/rootfs/$@
	cp -a $(BBOX_DIR)/* $(BLD)/rootfs/$@
	cp -a $(MTD_DIR)/* $(BLD)/rootfs/$@
	#cp -a $(MOD_DIR)/* $(BLD)/rootfs/$@
	if [ -n $(EXTRA_ROOT_DIR) ] ; then for dir in $(EXTRA_ROOT_DIR); do cp -a $$dir/rootfs/* $(BLD)/rootfs/$@ ; done ; fi
	(cd $(SYSROOT_DIR) ; tar --exclude='*.a' -cf - lib | (cd $(BLD)/rootfs/$@; tar xf -))
	(cd $(SYSROOT_DIR) ; tar --exclude='*.a' -cf - usr/lib | (cd $(BLD)/rootfs/$@; tar xf -))
	cp rootfs/min-root-devs.cpio $(BLD)/rootfs/$@.cpio
	(cd $(BLD)/rootfs/$@; find . | cpio -H newc -o -A -O ../$@.cpio)
	gzip -c $(BLD)/rootfs/$@.cpio > $(PRODUCT_DIR)/$@.cpio.gz

full-root: $(call COND_DEP, busybox mtd rio packages)
one-full-root: full-root-$(ARCHef)
full-root-$(ARCHef): productdir
	+$(QUIET)echo "********** full-root ENDIAN=$(ENDIAN) FLOAT=$(FLOAT)"
	if [ -d $(BLD)/rootfs/$@ -a -e $(BLD)/rootfs/$@-marker ] ; then rm -rf $(BLD)/rootfs/$@; fi
	mkdir -p $(BLD)/rootfs/$@; date > $(BLD)/rootfs/$@-marker
	(cd $(BLD)/rootfs/$@; cpio -i <$(PRJ)/rootfs/min-root-skel.cpio)
	cp -a rootfs/min-root-extra/* $(BLD)/rootfs/$@
	cp -a $(BBOX_DIR)/* $(BLD)/rootfs/$@
	cp -a $(MTD_DIR)/* $(BLD)/rootfs/$@
	cp -a $(RIO_DIR)/* $(BLD)/rootfs/$@
	cp -a $(PACKAGES_DIR)/* $(BLD)/rootfs/$@
	#cp -a $(MOD_DIR)/* $(BLD)/rootfs/$@
	if [ -n $(EXTRA_ROOT_DIR) ] ; then for dir in $(EXTRA_ROOT_DIR); do cp -a $$dir/rootfs/* $(BLD)/rootfs/$@ ; done ; fi
	if [ -e $(GDBSERVER) ] ; then cp $(GDBSERVER) $(BLD)/rootfs/$@/usr/bin ; fi
	(cd $(SYSROOT_DIR) ; tar --exclude='*.a' -cf - lib | (cd $(BLD)/rootfs/$@; tar xf -))
	(cd $(SYSROOT_DIR) ; tar --exclude='*.a' -cf - usr/lib | (cd $(BLD)/rootfs/$@; tar xf -))
	cp rootfs/min-root-devs.cpio $(BLD)/rootfs/$@.cpio
	(cd $(BLD)/rootfs/$@; find . | cpio -H newc -o -A -O ../$@.cpio)
	gzip -c $(BLD)/rootfs/$@.cpio > $(PRODUCT_DIR)/$@.cpio.gz

ltp-root: $(call COND_DEP, busybox mtd syslink-all ltp)
one-ltp-root: ltp-root-$(ARCHef)
ltp-root-$(ARCHef): productdir
	+$(QUIET)echo "********** ltp-root ENDIAN=$(ENDIAN) FLOAT=$(FLOAT)"
	if [ -d $(BLD)/rootfs/$@ -a -e $(BLD)/rootfs/$@-marker ] ; then rm -rf $(BLD)/rootfs/$@; fi
	mkdir -p $(BLD)/rootfs/$@; date > $(BLD)/rootfs/$@-marker
	(cd $(BLD)/rootfs/$@; cpio -i <$(PRJ)/rootfs/min-root-skel.cpio)
	cp -a rootfs/min-root-extra/* $(BLD)/rootfs/$@
	cp -a $(BBOX_DIR)/* $(BLD)/rootfs/$@
	cp -a $(MTD_DIR)/* $(BLD)/rootfs/$@
	#cp -a $(SYSLINK_ALL_DIR)/* $(BLD)/rootfs/$@
	#cp -a $(MOD_DIR)/* $(BLD)/rootfs/$@
	if [ -n $(EXTRA_ROOT_DIR) ] ; then for dir in $(EXTRA_ROOT_DIR); do cp -a $$dir/rootfs/* $(BLD)/rootfs/$@ ; done ; fi
	if [ -e $(GDBSERVER) ] ; then cp $(GDBSERVER) $(BLD)/rootfs/$@/usr/bin ; fi
	cp $(TESTING_DIR)/scripts/* $(BLD)/rootfs/$@/bin
	mkdir -p $(BLD)/rootfs/$@/opt/testing
	cp -r $(TESTING_DIR)/images $(BLD)/rootfs/$@/opt/testing
	cp -r $(BLD)/ltp$(FULL_SUFFIX)/bin/* $(BLD)/rootfs/$@/bin 
	cp -r $(BLD)/ltp$(FULL_SUFFIX)/opt/* $(BLD)/rootfs/$@/opt
	cp  -f $(BLD)/ltp$(FULL_SUFFIX)/mnt/* $(BLD)/rootfs/$@/mnt ; \
	(cd $(SYSROOT_DIR) ; tar --exclude='*.a' -cf - lib | (cd $(BLD)/rootfs/$@; tar xf -))
	(cd $(SYSROOT_DIR) ; tar --exclude='*.a' -cf - usr/lib | (cd $(BLD)/rootfs/$@; tar xf -))
	cp rootfs/min-root-devs.cpio $(BLD)/rootfs/$@.cpio
	(cd $(BLD)/rootfs/$@; find . | cpio -H newc -o -A -O ../$@.cpio)
	gzip -c $(BLD)/rootfs/$@.cpio > $(PRODUCT_DIR)/$@.cpio.gz

one-min-root-clean:
	rm -rf $(BLD)/rootfs/min-root-$(ARCHef)
	rm -rf $(BLD)/rootfs/min-root-$(ARCHef).cpio

one-full-root-clean:
	rm -rf $(BLD)/rootfs/full-root-$(ARCHef)
	rm -rf $(BLD)/rootfs/full-root-$(ARCHef).cpio

one-ltp-root-clean:
	rm -rf $(BLD)/rootfs/ltp-root-$(ARCHef)
	rm -rf $(BLD)/rootfs/ltp-root-$(ARCHef).cpio

one-mcsdk-demo-root-clean:
	rm -rf $(BLD)/rootfs/mcsdk-demo-root-$(ARCHef)
	rm -rf $(BLD)/rootfs/mcsdk-demo-root-$(ARCHef).cpio

########  Bootblobs
bootblob: productdir
	cp -a $(PRJ)/scripts/bootblob $(PRODUCT_DIR)/
	cp -a $(PRJ)/scripts/make-filesystem $(PRODUCT_DIR)/

bootblobs: bootblob
one-bootblobs: productdir
	+$(QUIET)for this_blob in $(BOOTBLOBS) ; do \
		if [ -r $(PRJ)/bootblob-templates/$${this_blob} ]; then \
			$(SUB_MAKE) -C $(PRODUCT_DIR) BOOTBLOB_FILE=$${this_blob} one-this-bootblob; \
		else	\
			echo "No template to build bootblob $${this_blob}"; false; \
		fi; \
	done

# this include and target below only make sense on the recursive makes started from the target above
# BOOTBLOB_FILE should always be undefined for the top level make
ifneq ($(BOOTBLOB_FILE),)
# TODO: invoke template to have it calculate dependencies
endif

.PHONY: one-this-bootblobs
one-this-bootblob: $(BOOTBLOB_DEPENDENCIES)
	+$(QUIET)echo "********** bootblob $(BOOTBLOB_FILE) ENDIAN=$(ENDIAN) FLOAT=$(FLOAT)"
	./bootblob $(BOOTBLOB_FILE)

########  Directory targets
productdir:
	[ -d $(PRODUCT_DIR) ] || mkdir -p $(PRODUCT_DIR)

product-clean:
	rm -rf $(PRODUCT_DIR)

########  Top level clean targets
one-clean: one-mtd-clean one-rio-clean one-busybox-clean one-clib-clean one-sdk-clean one-min-root-clean one-full-root-clean one-ltp-clean one-ltp-root-clean one-mcsdk-demo-clean one-mcsdk-demo-root-clean one-elf-loader-clean one-syslink-clean
	rm -rf $(MOD_DIR) $(HDR_DIR) $(BBOX_DIR)
	rm -rf $(KOBJ_BASE)
	+$(SUB_MAKE) sdk0-clean

