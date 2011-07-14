# Top level makefile for linux-c6x project
# Real dumb; always does target and its dependencies
# Any work saving is in the sub-makefiles
# This is intentional not modular or distributed to keep this simple case in one place
# Real distribution build will be done w/ bitbake

def-target: product

all: product syslink-all 

product: rootfs extra-kernels bootblobs

DATE = $(shell date +'%Y%m%d')

# These targets can be built little-endian and/or big-endian and hard or soft floating point ABI
TOP_TARGETS = rootfs mtd rio busybox packages sdk clib kernels sdk0 clean mtd-clean rio-clean \
	busybox-clean packages-clean clib-clean extra-kernels bootblobs elf-loader mcsdk-demo

# These sub-targets build only one endian/float setting
ENDIAN_TARGETS = one-rootfs one-mtd one-rio one-busybox one-sdk one-clib one-kernels one-sdk0 \
	one-kernels-clean one-uclibc-clean one-mtd-clean one-rio-clean one-busybox-clean \
	min-root-clean full-root-clean one-clean \
	one-extra-kernels one-packages one-packages-clean one-ltp one-ltp-clean \
	one-elf-loader one-mcsdk-demo

$(TOP_TARGETS) product kernel-headers: sanity

sanity:
	@if [ -z "$$LINUX_C6X_TOP_DIR" ] ; then echo Does not look like setenv has been setup; exit 1; fi
	@echo $(if $(ONLY),skipping conditional dependencies,using full dependencies)

$(ENDIAN_TARGETS): endian-sanity

endian-sanity:
	@if [ -z "$(ENDIAN_SUFFIX)" ] || [ -z "$(FLOAT)" ] ; then echo Must define ENDIAN and FLOAT for this target; exit 1; fi

# For these expand out to all settings of ENDIAN and FLOAT specified
$(TOP_TARGETS):
	@if [ -z "$(ENDIAN)" ] || [ "$(ENDIAN)" == "both" ]; then					\
	    if [ -z "$(FLOAT)" ] || [ "$(FLOAT)" == "both" ] ; then					\
		$(MAKE) ENDIAN=little FLOAT=soft KERNEL_HEADERS_ENDIAN=little one-$@;		\
		$(MAKE) ENDIAN=big FLOAT=soft KERNEL_HEADERS_ENDIAN=little one-$@;		\
		$(MAKE) ENDIAN=little FLOAT=hard KERNEL_HEADERS_ENDIAN=little one-$@;		\
		$(MAKE) ENDIAN=big FLOAT=hard KERNEL_HEADERS_ENDIAN=little one-$@;		\
	    else										\
		$(MAKE) ENDIAN=little FLOAT=$(FLOAT) KERNEL_HEADERS_ENDIAN=little one-$@;	\
		$(MAKE) ENDIAN=big FLOAT=$(FLOAT) KERNEL_HEADERS_ENDIAN=little one-$@;		\
	    fi											\
	else											\
	    if [ -z "$(FLOAT)" ] || [ "$(FLOAT)" == "both" ] ; then					\
		$(MAKE) ENDIAN=$(ENDIAN) FLOAT=soft KERNEL_HEADERS_ENDIAN=$(ENDIAN) one-$@;	\
		$(MAKE) ENDIAN=$(ENDIAN) FLOAT=hard KERNEL_HEADERS_ENDIAN=$(ENDIAN) one-$@;	\
	    else										\
		$(MAKE) ENDIAN=$(ENDIAN) FLOAT=$(FLOAT) KERNEL_HEADERS_ENDIAN=$(ENDIAN) one-$@;	\
	    fi											\
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
endif
endif

PRJ=$(LINUX_C6X_PROJECT_DIR)
TOP=$(LINUX_C6X_TOP_DIR)
LINUX_C6X_BUILD_DIR ?= $(LINUX_C6X_TOP_DIR)/Build
BLD=$(LINUX_C6X_TOP_DIR)/Build
TOOL_WRAP_DIR=$(TOP)/ti-gcc-wrap/tool-wrap
RPM_CROSS_DIR=$(BLD)/packages$(ENDIAN_SUFFIX)$(FLOAT_SUFFIX)

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


ifeq ($(ABI),coff)
ARCHabi        = coff
EXTRA_CFLAGS=
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
CC_SDK0=$(SDK0_DIR)/bin/$(FARCH)-linux-
CC_GNU=$(GNU_TOOLS_DIR)/bin/$(ARCH)-uclinux-

ifeq ($(BUILD_USERSPACE_WITH_GCC),yes)
CC_SDK=$(SDK_DIR)/bin/$(ARCH)-uclinux-
CC_UCLIBC = $(CC_GNU)
UCLIBC_CONFIGNAME = uClibc-0.9.30-cs.config
UCLIBC_SRCDIR = $(TOP)/gcc-$(ARCH)-uclibc
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
CC_SDK=$(SDK_DIR)/bin/$(FARCH)-linux-
CC_UCLIBC = $(CC_SDK0)
UCLIBC_CONFIGNAME = uClibc-0.9.30-c64xplus-shared.config
UCLIBC_THR_CONFIGNAME = uClibc-0.9.30-c64xplus-shared-thread.config
UCLIBC_SRCDIR = $(TOP)/uClibc
SYSROOT_DIR	= $(SDK_DIR)/$(FARCH)-sysroot
endif
BBOX_CONFIGNAME ?= busybox-1.00-full-$(ARCH).config

ifeq ($(ENDIAN),little)
GDBSERVER = $(GNU_TOOLS_DIR)/c6x-uclinux/libc/usr/bin/gdbserver
else
GDBSERVER = $(GNU_TOOLS_DIR)/c6x-uclinux/libc/be/usr/bin/gdbserver
endif

# install kernel modules here
MOD_DIR = $(BLD)/rootfs/kernel-modules-$(ARCHe)

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

one-kernels: productdir $(call COND_DEP, sdk0)
	for kname in $(KERNELS_TO_BUILD) ; do \
		if [ "$(BUILD_KERNEL_WITH_GCC)" = "yes" ] ; then \
			$(SUB_MAKE) -C $(LINUX_C6X_KERNEL_DIR) CROSS_COMPILE=$(CC_GNU) KNAME=$$kname kernel-sub ; \
		else \
			$(SUB_MAKE) -C $(LINUX_C6X_KERNEL_DIR) CROSS_COMPILE=$(CC_SDK0) KNAME=$$kname kernel-sub ; \
		fi \
	done


one-syslink:
	if [ -d $(SYSLINK_ROOT) ] ; then \
		for kname in $(SYSLINK_KERNEL_MODULES_TO_BUILD) ; do \
			echo Building SysLink kernel module for $$kname ; \
			mkdir -p $(BLD)/syslink_$$kname$(ENDIAN_SUFFIX) ; \
			cp -a $(SYSLINK_ROOT)/* $(BLD)/syslink_$$kname$(ENDIAN_SUFFIX) ; \
			if [ "$$kname" = "evmc6678" ]; then \
			$(SUB_MAKE) syslink-demo-all SYSLINK_TO_BUILD=evmc6678 SYSLINK_ROOT=$(BLD)/syslink_$$kname$(ENDIAN_SUFFIX) ; \
			fi ; \
			if [ "$$kname" = "evmc6670" ]; then \
			$(SUB_MAKE) syslink-demo-all SYSLINK_TO_BUILD=evmc6670 SYSLINK_ROOT=$(BLD)/syslink_$$kname$(ENDIAN_SUFFIX) ; \
			fi ; \
		done ; \
	else \
		echo "SysLink package not installed" ; \
	fi ;

one-syslink-clean:
	for kname in $(SYSLINK_KERNEL_MODULES_TO_BUILD) ; do \
	rm -rf $(BLD)/syslink_$$kname$(ENDIAN_SUFFIX) ; \
	done

one-extra-kernels: productdir
	for kname in $(EXTRA_KERNELS_TO_BUILD) ; do \
		if [ "$(BUILD_KERNEL_WITH_GCC)" = "yes" ] ; then \
			$(SUB_MAKE) -C $(LINUX_C6X_KERNEL_DIR) CROSS_COMPILE=$(CC_GNU) KNAME=$$kname kernel-sub ; \
		else \
			$(SUB_MAKE) -C $(LINUX_C6X_KERNEL_DIR) CROSS_COMPILE=$(CC_SDK0) KNAME=$$kname kernel-sub ; \
		fi \
	done

KERNEL_FNAME=`cat $(KOBJDIR)/include/config/kernel.release`$(PRODVERSION)
kernel-sub:
	@if [ -z "$(KNAME)" ] ; then echo Must define KNAME for this target; exit 1; fi
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
	if [ "$(ROOTFS)" == "ltp-root" ]; then \
		mkdir -p $(KTESTOBJDIR) ; \
		cp -r $(TESTMOD_SRC)/* $(KTESTOBJDIR) ; \
		make ARCH=$(ARCH) O=$(KOBJDIR)/ M=$(KTESTOBJDIR) DEPMOD=$(DEPMOD) \
			INSTALL_MOD_PATH=$(MOD_DIR) modules modules_install ; \
	fi
	cp $(KOBJDIR)/vmlinux $(PRODUCT_DIR)/vmlinux-$(KERNEL_FNAME)
	objcopy -I elf32-$(ENDIAN) -O binary $(PRODUCT_DIR)/vmlinux-$(KERNEL_FNAME) $(PRODUCT_DIR)/vmlinux-$(KERNEL_FNAME).bin

kernel-headers: kernels
	$(SUB_MAKE) -C $(LINUX_C6X_KERNEL_DIR) CROSS_COMPILE=$(CC_SDK0) \
		ENDIAN=$(KERNEL_HEADERS_ENDIAN) KNAME=$(KERNEL_HEADERS_KERNEL) kernel-headers-sub

kernel-headers-sub:
	if [ ! -d $(KHDR_DIR)/include/asm ]; then   \
		mkdir -p $(KHDR_DIR) ;  \
		make -C $(LINUX_C6X_KERNEL_DIR) ARCH=$(ARCH) CROSS_COMPILE=$(CC_SDK0) \
		        INSTALL_HDR_PATH=$(KHDR_DIR) O=$(KOBJDIR) headers_install ; \
	fi

one-ltp:
	[ -d $(BLD)/ltp$(ENDIAN_SUFFIX) ] || mkdir -p $(BLD)/ltp$(ENDIAN_SUFFIX)
	if [ "$(BUILD_USERSPACE_WITH_GCC)" == "yes" ] ; then \
		(cd $(PRJ)/testing/ltp; make TOP_DIR=${TOP} ENDIAN=${ENDIAN} GCC=true all);\
	else \
		(cd $(PRJ)/testing/ltp; make TOP_DIR=${TOP} ABI=${ABI} all);\
	fi
	cp $(BLD)/ltp$(ENDIAN_SUFFIX)/testdriver ${TOP}/product

one-ltp-clean:
	rm -rf $(BLD)/ltp$(ENDIAN_SUFFIX)

one-clib: $(call COND_DEP, sdk0 kernel-headers)
	[ -d $(BLD)/uClibc$(ENDIAN_SUFFIX)$(FLOAT_SUFFIX) ] || mkdir -p $(BLD)/uClibc$(ENDIAN_SUFFIX)$(FLOAT_SUFFIX)
	cp -a $(UCLIBC_SRCDIR)/* $(BLD)/uClibc$(ENDIAN_SUFFIX)$(FLOAT_SUFFIX)
	$(SUB_MAKE) -C $(BLD)/uClibc$(ENDIAN_SUFFIX)$(FLOAT_SUFFIX) CROSS_COMPILE=ensure_not_used CROSS=$(CC_UCLIBC) clib-sub
	if [ "$(BUILD_USERSPACE_WITH_GCC)" != "yes" ] ; then \
		[ -d $(BLD)/uClibc-pthread$(ENDIAN_SUFFIX) ] || mkdir -p $(BLD)/uClibc-pthread$(ENDIAN_SUFFIX) ; \
		cp -a $(UCLIBC_SRCDIR)/* $(BLD)/uClibc-pthread$(ENDIAN_SUFFIX) ; \
		$(SUB_MAKE) -C $(BLD)/uClibc-pthread$(ENDIAN_SUFFIX) CROSS_COMPILE=ensure_not_used CROSS=$(CC_UCLIBC) clib-sub-pthread ; \
	fi

UCLIBC_CONFIG = $(PRJ)/uclibc-configs/$(UCLIBC_CONFIGNAME)

$(BLD)/uClibc$(ENDIAN_SUFFIX)$(FLOAT_SUFFIX)/.config: $(UCLIBC_CONFIG)
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

$(BLD)/uClibc-pthread$(ENDIAN_SUFFIX)/.config: $(UCLIBC_THR_CONFIG)
	cp $(UCLIBC_THR_CONFIG) .config
	make oldconfig

clib-sub: $(BLD)/uClibc$(ENDIAN_SUFFIX)$(FLOAT_SUFFIX)/.config
	make

clib-sub-pthread: $(BLD)/uClibc-pthread$(ENDIAN_SUFFIX)/.config
	make

BBOX_CONFIG = $(BLD)/busybox$(ENDIAN_SUFFIX)$(FLOAT_SUFFIX)/$(BBOX_CONFIGNAME)

one-busybox:  $(call COND_DEP, one-sdk)
	[ -d $(BLD)/busybox$(ENDIAN_SUFFIX)$(FLOAT_SUFFIX) ] || mkdir -p $(BLD)/busybox$(ENDIAN_SUFFIX)$(FLOAT_SUFFIX)
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
	$(SUB_MAKE) -C $(BLD)/busybox$(ENDIAN_SUFFIX)$(FLOAT_SUFFIX) \
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

busybox-sub: $(BLD)/busybox$(ENDIAN_SUFFIX)$(FLOAT_SUFFIX)/.config_done
	rm -rf $(BBOX_DIR)
	mkdir -p $(BBOX_DIR)
	$(BBOX_MAKE) EXTRA_LDFLAGS="$(BBOX_EXTRA)"
	$(BBOX_MAKE) EXTRA_LDFLAGS="$(BBOX_EXTRA)" CONFIG_PREFIX=$(BBOX_DIR) install

$(BLD)/busybox$(ENDIAN_SUFFIX)$(FLOAT_SUFFIX)/.config_done: $(CONF) $(PRJ)/Makefile
	cp $(CONF) .config
	$(BBOX_MAKE) oldconfig
	cp $(CONF) $@

one-mtd: $(call COND_DEP, one-sdk)
	[ -d $(BLD)/mtd-utils$(ENDIAN_SUFFIX) ] || mkdir -p $(BLD)/mtd-utils$(ENDIAN_SUFFIX)
	$(SUB_MAKE) -C $(BLD)/mtd-utils$(ENDIAN_SUFFIX) CROSS=$(CC_SDK) ENDIAN=$(ENDIAN) mtd-sub

one-mcsdk-demo: 
	if [ -d $(MCSDK_DEMO_DIR) ]; then \
	[ -d $(BLD)/mcsdk-demo$(ENDIAN_SUFFIX)$(FLOAT_SUFFIX) ] || mkdir -p $(BLD)/mcsdk-demo$(ENDIAN_SUFFIX)$(FLOAT_SUFFIX) ; \
	cp -a $(MCSDK_DEMO_DIR)/* $(BLD)/mcsdk-demo$(ENDIAN_SUFFIX)$(FLOAT_SUFFIX) ; \
	(cd $(BLD)/mcsdk-demo$(ENDIAN_SUFFIX)$(FLOAT_SUFFIX); make CROSS=$(CC_SDK) ENDIAN=$(ENDIAN) FLOAT=$(FLOAT)) ; \
	else \
		echo "install $(MCSDK_DEMO_DIR) and re-run build"; \
		exit; \
	fi

one-mcsdk-demo-clean:
	rm -rf $(BLD)/mcsdk-demo$(ENDIAN_SUFFIX)$(FLOAT_SUFFIX)

one-elf-loader: $(call COND_DEP, one-sdk)
# TODO currently support only C6678. So hard coded
	[ -d $(BLD)/elf-loader$(ENDIAN_SUFFIX)$(FLOAT_SUFFIX) ] || mkdir -p $(BLD)/elf-loader$(ENDIAN_SUFFIX)$(FLOAT_SUFFIX) ; \
	cp -a $(TOP)/linux-c6x-project/tools/elfloader/* $(BLD)/elf-loader$(ENDIAN_SUFFIX)$(FLOAT_SUFFIX) ; \
	(cd $(BLD)/elf-loader$(ENDIAN_SUFFIX)$(FLOAT_SUFFIX); make DEVICE=C6678 CROSS=$(CC_SDK) ENDIAN=$(ENDIAN) FLOAT=$(FLOAT) ) ;

one-elf-loader-clean:
	rm -rf $(BLD)/elf-loader$(ENDIAN_SUFFIX)$(FLOAT_SUFFIX)

ifeq ($(BUILD_USERSPACE_WITH_GCC),yes)
MTD_LDFLAGS = -mdsbt -static
MTD_CFLAGS = -O2 -g -mdsbt
ifneq ($(ENDIAN),little)
MTD_LDFLAGS += -mbig-endian
MTD_CFLAGS += -mbig-endian
endif
else
MTD_LDFLAGS = -dsbt -static
MTD_CFLAGS = -O1 -g -dsbt
endif

MTD_MAKE = make -C $(MTD_SRC) CROSS=$(CC_SDK) SUBDIRS= DESTDIR=$(MTD_DIR) \
	LDFLAGS="$(MTD_LDFLAGS)" CFLAGS="$(MTD_CFLAGS)"

mtd-sub:
	rm -rf $(MTD_DIR)
	mkdir -p $(MTD_DIR)
	$(MTD_MAKE) install

ifeq ($(BUILD_USERSPACE_WITH_GCC),yes)
RIO_CFLAGS = -O3 -mdsbt
ifneq ($(ENDIAN),little)
RIO_CFLAGS += -mbig-endian
endif
else
RIO_CFLAGS = -dsbt
endif

one-rio: $(call COND_DEP, one-sdk)
	[ -d $(BLD)/rio-utils$(ENDIAN_SUFFIX) ] || mkdir -p $(BLD)/rio-utils$(ENDIAN_SUFFIX)
	make -f $(RIO_SRC)/Makefile -C $(RIO_SRC) CC="$(CC_SDK)gcc" EXTRA_CFLAGS="$(RIO_CFLAGS)" BUILDIR=$(BLD)/rio-utils$(ENDIAN_SUFFIX) DESTDIR=$(RIO_DIR)
	make -f $(RIO_SRC)/Makefile -C $(RIO_SRC) CC="$(CC_SDK)gcc" EXTRA_CFLAGS="$(RIO_CFLAGS)" BUILDIR=$(BLD)/rio-utils$(ENDIAN_SUFFIX) DESTDIR=$(RIO_DIR) install

one-packages: $(SDK_DIR)/rpm
	@if [ "$(BUILD_USERSPACE_WITH_GCC)" != "yes" ] ; then echo "cannot build packages without GCC"; exit 1; fi
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

$(SDK_DIR)/rpm:
	$(PRJ)/build-rpm.sh

one-sdk0:
	@if [ -e $(SDK0_DIR)/linux-$(ARCHe)-sdk0-prebuilt ] ; then 	\
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
	@touch $(SDK0_DIR)/linux-c6x-sdk0-prebuilt
	@touch $(SDK0_DIR)/linux-c6xeb-sdk0-prebuilt

sdk0-unkeep:
	@rm -f $(SDK0_DIR)/linux-c6x-sdk0-prebuilt
	@rm -f $(SDK0_DIR)/linux-c6xeb-sdk0-prebuilt

sdk0-clean:
	@if [ -e $(SDK0_DIR)/linux-c6x-sdk0-prebuilt ] ; then 	\
	    echo "using pre-built sdk0 (skip clean)";		\
	else	    						\
	    if [ -e $(SDK0_DIR)/bin/$(FARCH)-linux-gcc ] ; then 	\
		rm -rf $(SDK0_DIR); 				\
	    fi;							\
	    if [ -e $(TOOL_WRAP_DIR)/Makefile ] ; then 		\
		cd $(TOOL_WRAP_DIR); $(MAKE) ENDIAN=$(ENDIAN) ABI=$(ABI) GCC_C6X_DEST=$(SDK0_DIR) ALIAS=$(ALIAS) clean;	\
	    fi;							\
	fi							\

one-sdk: sdk0 one-clib
	[ -e $(SYSROOT_DIR) ] || mkdir -p $(SYSROOT_DIR)
        # Just updating with new files. Re-visit it later as needed
	if [ "$(BUILD_USERSPACE_WITH_GCC)" != "yes" ] ; then \
		[ -e $(SYSROOT_TMP_DIR) ] || mkdir -p $(SYSROOT_TMP_DIR) ; \
		cp -a $(SDK0_DIR)/* $(SDK_DIR) ; \
		[ -d $(SYSROOT_TMP_DIR)/usr/include/asm ] || cp -a $(KHDR_DIR) $(SYSROOT_TMP_DIR) ; \
		(cd $(SDK_DIR)/bin; ls c6x-* | cut -d\- -f4 | sort -u | xargs -i ln -sf $(ARCH)-elf-linux-"{}" $(ARCH)-linux-"{}" ) ; \
		(cd $(SDK_DIR)/bin; ls c6xeb-* | cut -d\- -f4 | sort -u | xargs -i ln -sf $(ARCH)eb-elf-linux-"{}" $(ARCH)eb-linux-"{}" ) ; \
		make -C $(BLD)/uClibc$(ENDIAN_SUFFIX) CROSS=$(CC_SDK0) PREFIX=$(SYSROOT_TMP_DIR) install ; \
		[ -e $(SYSROOT_TMP_DIR_THREAD) ] || mkdir -p $(SYSROOT_TMP_DIR_THREAD) ; \
		make -C $(BLD)/uClibc-pthread$(ENDIAN_SUFFIX) CROSS=$(CC_SDK0) PREFIX=$(SYSROOT_TMP_DIR_THREAD) install ; \
		mv -f $(BLD)/uClibc-pthread$(ENDIAN_SUFFIX)/lib/libc.a $(BLD)/uClibc-pthread$(ENDIAN_SUFFIX)/lib/libc-pthread.a ; \
		rsync -rlpgocv --ignore-existing $(SYSROOT_TMP_DIR_THREAD)/ $(SYSROOT_TMP_DIR)/ ; \
		rsync -rlpgocv --delete $(SYSROOT_TMP_DIR)/ $(SYSROOT_DIR)/ ; \
	else \
		cp -a $(GNU_TOOLS_DIR)/{bin,lib,libexec,share} $(SDK_DIR) ; \
		cp -a $(GNU_TOOLS_DIR)/$(ARCH)-uclinux/{bin,lib,share,include} $(SDK_DIR)/$(ARCH)-uclinux ; \
		[ -d $(SYSROOT_HDR_DIR)/usr/include/asm ] || cp -a $(KHDR_DIR) $(SYSROOT_HDR_DIR) ; \
		(cd $(SDK_DIR)/bin; ls | cut -d\- -f3 | sort -u | xargs -i ln -sf $(ARCH)-uclinux-"{}" $(ARCH)-linux-"{}" ) ; \
		(cd $(SDK_DIR)/bin; ls | cut -d\- -f3 | sort -u | xargs -i ln -sf $(ARCH)-uclinux-"{}" $(ARCH)eb-linux-"{}" ) ; \
		[ -d $(SYSROOT_DIR)/lib ] || mkdir -p $(SYSROOT_DIR)/lib; \
		[ -d $(SYSROOT_DIR)/usr/lib ] || mkdir -p $(SYSROOT_DIR)/usr/lib; \
		make -C $(BLD)/uClibc$(ENDIAN_SUFFIX)$(FLOAT_SUFFIX) CROSS=$(CC_GNU) PREFIX=$(SYSROOT_DIR) install ; \
		if [ "$(SYSROOT_DIR)" != "$(SYSROOT_HDR_DIR)" ]; then \
		    cp -r $(SYSROOT_DIR)/usr/include/* $(SYSROOT_HDR_DIR)/usr/include ; \
		    rm -rf $(SYSROOT_DIR)/usr/include ; \
		fi; \
		cp -a $(GNU_TOOLS_DIR)/$(SYSROOT_DIR_SUBPATH)/usr/lib/libstdc++.a $(SYSROOT_DIR)/usr/lib/; \
	fi

sdk-clean:
	rm -rf $(SDK_DIR)

one-rootfs: productdir bootblob
	for this_rootfs in $(ROOTFS) ; do \
		$(SUB_MAKE) $${this_rootfs}-$(ARCHef); \
	done

min-root-$(ARCHef): productdir $(call COND_DEP, one-busybox) $(call COND_DEP, one-mtd)
	if [ -d $(BLD)/rootfs/$@ -a -e $(BLD)/rootfs/$@-marker ] ; then rm -rf $(BLD)/rootfs/$@; fi
	mkdir -p $(BLD)/rootfs/$@; date > $(BLD)/rootfs/$@-marker
	(cd $(BLD)/rootfs/$@; cpio -i <$(PRJ)/rootfs/min-root-skel.cpio)
	cp -a rootfs/min-root-extra/* $(BLD)/rootfs/$@
	cp -a $(BBOX_DIR)/* $(BLD)/rootfs/$@
	cp -a $(MTD_DIR)/* $(BLD)/rootfs/$@
	cp -a $(MOD_DIR)/* $(BLD)/rootfs/$@
	if [ -n $(EXTRA_ROOT_DIR) ] ; then for dir in $(EXTRA_ROOT_DIR); do cp -a $$dir/rootfs/* $(BLD)/rootfs/$@ ; done ; fi
	if [ -e $(GDBSERVER) ] ; then cp $(GDBSERVER) $(BLD)/rootfs/$@/usr/bin ; fi
	(cd $(SYSROOT_DIR) ; tar --exclude='*.a' -cf - lib | (cd $(BLD)/rootfs/$@; tar xf -))
	(cd $(SYSROOT_DIR) ; tar --exclude='*.a' -cf - usr/lib | (cd $(BLD)/rootfs/$@; tar xf -))
	cp rootfs/min-root-devs.cpio $(BLD)/rootfs/$@.cpio
	(cd $(BLD)/rootfs/$@; find . | cpio -H newc -o -A -O ../$@.cpio)
	gzip -c $(BLD)/rootfs/$@.cpio > $(PRODUCT_DIR)/$@.cpio.gz

mcsdk-demo-root-$(ARCHef): productdir $(call COND_DEP, one-busybox) $(call COND_DEP, one-mtd) $(call COND_DEP, one-mcsdk-demo) $(call COND_DEP, one-syslink) $(call COND_DEP, one-elf-loader)
	if [ -d $(BLD)/rootfs/$@ -a -e $(BLD)/rootfs/$@-marker ] ; then rm -rf $(BLD)/rootfs/$@; fi
	mkdir -p $(BLD)/rootfs/$@; date > $(BLD)/rootfs/$@-marker
	(cd $(BLD)/rootfs/$@; cpio -i <$(PRJ)/rootfs/min-root-skel.cpio)
	cp -a rootfs/min-root-extra/* $(BLD)/rootfs/$@
	rm -rf $(BLD)/rootfs/$@/web
	# call mcsdk demo install
	(cd $(BLD)/mcsdk-demo$(ENDIAN_SUFFIX)$(FLOAT_SUFFIX); make CROSS=$(CC_SDK) ENDIAN=$(ENDIAN) FLOAT=$(FLOAT) INSTALL_PREFIX=$(BLD)/rootfs/$@ install )
	(cd $(BLD)/elf-loader$(ENDIAN_SUFFIX)$(FLOAT_SUFFIX); make CROSS=$(CC_SDK) ENDIAN=$(ENDIAN) FLOAT=$(FLOAT) INSTALL_PREFIX=$(BLD)/rootfs/$@/usr/bin install )
	# Install syslink executables and modules
	for kname in $(SYSLINK_KERNEL_MODULES_TO_BUILD) ; do \
		mkdir -p $(BLD)/rootfs/$@/opt/syslink_$$kname${ENDIAN_SUFFIX} ; \
		cp -a $(PRODUCT_DIR)/syslink_$$kname${ENDIAN_SUFFIX}/messageq* $(BLD)/rootfs/$@/opt/syslink_$$kname${ENDIAN_SUFFIX} ; \
		cp -a $(PRODUCT_DIR)/syslink_$$kname${ENDIAN_SUFFIX}/notify* $(BLD)/rootfs/$@/opt/syslink_$$kname${ENDIAN_SUFFIX} ; \
		cp -a $(PRODUCT_DIR)/syslink_$$kname${ENDIAN_SUFFIX}/procmgrapp_release $(BLD)/rootfs/$@/opt/syslink_$$kname${ENDIAN_SUFFIX} ; \
		cp -a $(PRODUCT_DIR)/syslink_$$kname${ENDIAN_SUFFIX}/syslink.ko $(BLD)/rootfs/$@/opt/syslink_$$kname${ENDIAN_SUFFIX} ; \
		if [ "$$kname" == "evmc6678" ] ; then \
			cp $(PRJ)/scripts/syslink/messageq*_8_core.sh $(BLD)/rootfs/$@/opt/syslink_$$kname${ENDIAN_SUFFIX} ; \
			cp $(PRJ)/scripts/syslink/notify*_8_core.sh $(BLD)/rootfs/$@/opt/syslink_$$kname${ENDIAN_SUFFIX} ; \
			cp $(PRJ)/scripts/syslink/procmgr_load_messageqapp_8_core.sh $(BLD)/rootfs/$@/opt/syslink_$$kname${ENDIAN_SUFFIX} ; \
			cp $(PRJ)/scripts/syslink/procmgr_load_notifyapp_8_core.sh $(BLD)/rootfs/$@/opt/syslink_$$kname${ENDIAN_SUFFIX} ; \
			$(STRIP_CGT) $(BLD)/rootfs/$@/opt/syslink_$$kname${ENDIAN_SUFFIX}/*.xe66 ; \
		fi ; \
		if [ "$$kname" == "evmc6670" ] ; then \
			cp $(PRJ)/scripts/syslink/messageq*_4_core.sh $(BLD)/rootfs/$@/opt/syslink_$$kname${ENDIAN_SUFFIX} ; \
			cp $(PRJ)/scripts/syslink/notify*_4_core.sh $(BLD)/rootfs/$@/opt/syslink_$$kname${ENDIAN_SUFFIX} ; \
			cp $(PRJ)/scripts/syslink/procmgr_load_messageqapp_4_core.sh $(BLD)/rootfs/$@/opt/syslink_$$kname${ENDIAN_SUFFIX} ; \
			cp $(PRJ)/scripts/syslink/procmgr_load_notifyapp_4_core.sh $(BLD)/rootfs/$@/opt/syslink_$$kname${ENDIAN_SUFFIX} ; \
			$(STRIP_CGT) $(BLD)/rootfs/$@/opt/syslink_$$kname${ENDIAN_SUFFIX}/*.xe66 ; \
		fi ; \
		rm -rf $(BLD)/rootfs/$@/opt/syslink_$$kname${ENDIAN_SUFFIX}/messageqapp_debug ; \
		rm -rf $(BLD)/rootfs/$@/opt/syslink_$$kname${ENDIAN_SUFFIX}/notifyapp_debug ; \
	done
	cp -a $(BBOX_DIR)/* $(BLD)/rootfs/$@
	cp -a $(MTD_DIR)/* $(BLD)/rootfs/$@
	cp -a $(MOD_DIR)/* $(BLD)/rootfs/$@
	if [ -n $(EXTRA_ROOT_DIR) ] ; then for dir in $(EXTRA_ROOT_DIR); do cp -a $$dir/rootfs/* $(BLD)/rootfs/$@ ; done ; fi
	(cd $(SYSROOT_DIR) ; tar --exclude='*.a' -cf - lib | (cd $(BLD)/rootfs/$@; tar xf -))
	(cd $(SYSROOT_DIR) ; tar --exclude='*.a' -cf - usr/lib | (cd $(BLD)/rootfs/$@; tar xf -))
	cp rootfs/min-root-devs.cpio $(BLD)/rootfs/$@.cpio
	(cd $(BLD)/rootfs/$@; find . | cpio -H newc -o -A -O ../$@.cpio)
	gzip -c $(BLD)/rootfs/$@.cpio > $(PRODUCT_DIR)/$@.cpio.gz

full-root-$(ARCHef): productdir $(call COND_DEP, one-busybox) $(call COND_DEP, one-mtd) $(call COND_DEP, one-rio) $(call COND_DEP, one-packages)
	if [ -d $(BLD)/rootfs/$@ -a -e $(BLD)/rootfs/$@-marker ] ; then rm -rf $(BLD)/rootfs/$@; fi
	mkdir -p $(BLD)/rootfs/$@; date > $(BLD)/rootfs/$@-marker
	(cd $(BLD)/rootfs/$@; cpio -i <$(PRJ)/rootfs/min-root-skel.cpio)
	cp -a rootfs/min-root-extra/* $(BLD)/rootfs/$@
	cp -a $(BBOX_DIR)/* $(BLD)/rootfs/$@
	cp -a $(MTD_DIR)/* $(BLD)/rootfs/$@
	cp -a $(RIO_DIR)/* $(BLD)/rootfs/$@
	cp -a $(PACKAGES_DIR)/* $(BLD)/rootfs/$@
	cp -a $(MOD_DIR)/* $(BLD)/rootfs/$@
	if [ -n $(EXTRA_ROOT_DIR) ] ; then for dir in $(EXTRA_ROOT_DIR); do cp -a $$dir/rootfs/* $(BLD)/rootfs/$@ ; done ; fi
	if [ -e $(GDBSERVER) ] ; then cp $(GDBSERVER) $(BLD)/rootfs/$@/usr/bin ; fi
	(cd $(SYSROOT_DIR) ; tar --exclude='*.a' -cf - lib | (cd $(BLD)/rootfs/$@; tar xf -))
	(cd $(SYSROOT_DIR) ; tar --exclude='*.a' -cf - usr/lib | (cd $(BLD)/rootfs/$@; tar xf -))
	cp rootfs/min-root-devs.cpio $(BLD)/rootfs/$@.cpio
	(cd $(BLD)/rootfs/$@; find . | cpio -H newc -o -A -O ../$@.cpio)
	gzip -c $(BLD)/rootfs/$@.cpio > $(PRODUCT_DIR)/$@.cpio.gz

ltp-root-$(ARCHef): productdir $(call COND_DEP, one-busybox) $(call COND_DEP, one-mtd) $(call COND_DEP, one-ltp)
	if [ -d $(BLD)/rootfs/$@ -a -e $(BLD)/rootfs/$@-marker ] ; then rm -rf $(BLD)/rootfs/$@; fi
	mkdir -p $(BLD)/rootfs/$@; date > $(BLD)/rootfs/$@-marker
	(cd $(BLD)/rootfs/$@; cpio -i <$(PRJ)/rootfs/min-root-skel.cpio)
	cp -a rootfs/min-root-extra/* $(BLD)/rootfs/$@
	cp -a $(BBOX_DIR)/* $(BLD)/rootfs/$@
	cp -a $(MTD_DIR)/* $(BLD)/rootfs/$@
	cp -a $(MOD_DIR)/* $(BLD)/rootfs/$@
	if [ -n $(EXTRA_ROOT_DIR) ] ; then for dir in $(EXTRA_ROOT_DIR); do cp -a $$dir/rootfs/* $(BLD)/rootfs/$@ ; done ; fi
	if [ -e $(GDBSERVER) ] ; then cp $(GDBSERVER) $(BLD)/rootfs/$@/usr/bin ; fi
	cp $(TESTING_DIR)/scripts/* $(BLD)/rootfs/$@/bin
	mkdir -p $(BLD)/rootfs/$@/opt/testing
	cp -r $(TESTING_DIR)/images $(BLD)/rootfs/$@/opt/testing
	cp -r $(BLD)/ltp$(ENDIAN_SUFFIX)/bin/* $(BLD)/rootfs/$@/bin 
	cp -r $(BLD)/ltp$(ENDIAN_SUFFIX)/opt/* $(BLD)/rootfs/$@/opt
	cp  -f $(BLD)/ltp$(ENDIAN_SUFFIX)/mnt/* $(BLD)/rootfs/$@/mnt ; \
	(cd $(SYSROOT_DIR) ; tar --exclude='*.a' -cf - lib | (cd $(BLD)/rootfs/$@; tar xf -))
	(cd $(SYSROOT_DIR) ; tar --exclude='*.a' -cf - usr/lib | (cd $(BLD)/rootfs/$@; tar xf -))
	cp rootfs/min-root-devs.cpio $(BLD)/rootfs/$@.cpio
	(cd $(BLD)/rootfs/$@; find . | cpio -H newc -o -A -O ../$@.cpio)
	gzip -c $(BLD)/rootfs/$@.cpio > $(PRODUCT_DIR)/$@.cpio.gz

########  Bootblob 
bootblob: productdir
	cp -a $(PRJ)/bootblob $(PRODUCT_DIR)/
	chmod +x $(PRODUCT_DIR)/bootblob

one-bootblobs: productdir bootblob
	for this_blob in $(BOOTBLOBS) ; do \
		if [ -r $(PRJ)/bootblob-specs/$${this_blob}.mk ]; then \
			$(SUB_MAKE) -C $(PRODUCT_DIR) BOOTBLOB_FILE=$${this_blob} one-this-bootblob; \
		else	\
			echo "No spec to build bootblob $${this_blob}"; false; \
		fi; \
	done

# this include and target below only make sense on the recursive makes started from the target above
# BOOTBLOB_FILE should always be undefined for the top level make
ifneq ($(BOOTBLOB_FILE),)
include $(PRJ)/bootblob-specs/$(BOOTBLOB_FILE).mk
endif

.PHONY: one-this-bootblobs
one-this-bootblob: $(BOOTBLOB_DEPENDENCIES)
	echo Building bootblob $(BOOTBLOB_FILE)
	$(BOOTBLOB_CMD)

########  Misc and clean targets
productdir:
	[ -d $(PRODUCT_DIR) ] || mkdir -p $(PRODUCT_DIR)

product-clean:
	rm -rf $(PRODUCT_DIR)

rpm-clean:
	rm -rf $(BLD)/rpm-4.0.4
	rm -rf $(SDK_DIR)/rpm

kernel-clean-sub:
	rm -rf $(KOBJDIR)

one-kernels-clean:
	for kname in $(KERNELS_TO_BUILD) ; do \
		$(SUB_MAKE) -C $(LINUX_C6X_KERNEL_DIR) CROSS_COMPILE=$(CC_SDK0) KNAME=$$kname kernel-clean-sub ; \
	done

one-sdk-clean:
	rm -rf $(SYSROOT_DIR)
	[ -d $(SDK_DIR)/c6x-sysroot -o -d $(SDK_DIR)/c6xeb-sysroot ] || rm -rf $(SDK_DIR)

one-clib-clean:
	rm -rf $(BLD)/uClibc$(ENDIAN_SUFFIX)
	rm -rf $(BLD)/uClibc-pthread$(ENDIAN_SUFFIX)

one-busybox-clean:
	rm -rf $(BLD)/busybox$(ENDIAN_SUFFIX)

one-mtd-clean:
	rm -rf $(BLD)/mtd-utils$(ENDIAN_SUFFIX)

one-rio-clean:
	rm -rf $(BLD)/rio-utils$(ENDIAN_SUFFIX)

one-packages-clean:
	rm -rf $(RPM_CROSS_DIR)

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

one-clean: one-mtd-clean one-rio-clean one-busybox-clean one-clib-clean one-sdk-clean one-min-root-clean one-full-root-clean one-ltp-clean one-ltp-root-clean one-mcsdk-demo-clean one-mcsdk-demo-root-clean one-elf-loader-clean one-syslink-clean
	rm -rf $(MOD_DIR) $(HDR_DIR) $(BBOX_DIR)
	rm -rf $(KOBJ_BASE)
	make sdk0-clean

# for Building SysLink
-include Makefile.syslink
