# Top level makefile for linux-c6x project
# Real dumb; always does target and its dependencies
# Any work saving is in the sub-makefiles
# This is intentional not modular or distributed to keep this simple case in one place
# Real distribution build will be done w/ bitbake

all: product

product: rootfs extra-kernels

DATE = $(shell date +'%Y%m%d')

# These targets can be built little-endian and/or big-endian
TOP_TARGETS = rootfs mtd busybox sdk clib kernels sdk0 clean mtd-clean busybox-clean clib-clean extra-kernels

# These sub-targets build only little-endian or big-endian
ENDIAN_TARGETS = one-rootfs one-mtd one-busybox one-sdk one-clib one-kernels one-sdk0 \
	one-kernels-clean one-uclibc-clean one-mtd-clean one-busybox-clean min-root-clean one-clean \
	one-extra-kernels

$(TOP_TARGETS) product kernel-headers: sanity

sanity:
	@if [ -z "$$LINUX_C6X_TOP_DIR" ] ; then echo Does not look like setenv has been setup; exit 1; fi
	@echo $(if $(ONLY),skipping conditional dependencies,using full dependencies)

$(ENDIAN_TARGETS): endian-sanity

endian-sanity:
	@if [ -z "$(ENDIAN_SUFFIX)" ] ; then echo Must define ENDIAN for this target; exit 1; fi

# If these get called with undefined ENDIAN, build both endians
$(TOP_TARGETS):
	if [ -z $(ENDIAN) ]; then		\
	    $(MAKE) ENDIAN=little KERNEL_HEADERS_ENDIAN=little one-$@;	\
	    $(MAKE) ENDIAN=big KERNEL_HEADERS_ENDIAN=little one-$@;		\
	else					\
	    $(MAKE) ENDIAN=$(ENDIAN) KERNEL_HEADERS_ENDIAN=$(ENDIAN) one-$@;	\
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

PRJ=$(LINUX_C6X_PROJECT_DIR)
TOP=$(LINUX_C6X_TOP_DIR)
LINUX_C6X_BUILD_DIR ?= $(LINUX_C6X_TOP_DIR)/Build
BLD=$(LINUX_C6X_TOP_DIR)/Build
TOOL_WRAP_DIR=$(TOP)/ti-gcc-wrap/tool-wrap

ABI           ?= elf
DSBT_SIZE     ?= 64
KERNELS_TO_BUILD ?= dsk6455 evm7472
EXTRA_KERNELS_TO_BUILD ?=
BUILD_KERNEL_WITH_GCC ?=
BUILD_USERSPACE_WITH_GCC ?=
BUILD_STATIC_BBOX ?= yes
ROOTFS ?= min-root

# ensure all the config ENV vars are exported, even if the definition was from this file
export ABI
export DSBT_SIZE
export HOSTCC
export LINUX_C6X_BUILD_DIR

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

ARCHe		= c6x$(ARCHendian)
ARCH		= $(ARCHe)-$(ARCHabi)
SYSROOT_DIR	= $(SDK_DIR)/$(ARCH)-sysroot

# SDK0 is a compiler only w/o C library. it is used to build kernel and C library
# SDK is SDK0 + c library and is used for busybox and other user apps and libraries
CC_SDK0=$(SDK0_DIR)/bin/$(ARCH)-linux-
CC_GNU=$(GNU_TOOLS_DIR)/bin/c6x-uclinux-

ifeq ($(BUILD_USERSPACE_WITH_GCC),yes)
CC_SDK=$(CC_GNU)
CC_UCLIBC = $(CC_GNU)
UCLIBC_CONFIGNAME = uClibc-0.9.30-cs.config
UCLIBC_SRCDIR = $(TOP)/uclibc-ti-c6x
else
CC_SDK=$(SDK_DIR)/bin/$(ARCH)-linux-
CC_UCLIBC = $(CC_SDK0)
UCLIBC_CONFIGNAME = uClibc-0.9.30-c64xplus-shared.config
UCLIBC_THR_CONFIGNAME = uClibc-0.9.30-c64xplus-shared-thread.config
UCLIBC_SRCDIR = $(TOP)/uClibc
endif
BBOX_CONFIGNAME ?= busybox-1.00-full-c6x.config

# install kernel modules here
MOD_DIR = $(BLD)/rootfs/kernel-modules-$(ARCHe)

# install kernel headers here
HDR_DIR = $(BLD)/kernel-headers
KHDR_DIR = $(HDR_DIR)/usr

# install busybox here
BBOX_DIR = $(BLD)/rootfs/busybox-$(ARCHe)

MTD_SRC = $(TOP)/projects/mtd-utils

# install mtd here
MTD_DIR = $(BLD)/rootfs/mtd-utils-$(ARCHe)

KOBJ_BASE = $(BLD)/kobjs

SYSROOT_TMP_DIR = $(BLD)/tmp-$(ARCH)-sysroot
SYSROOT_TMP_DIR_THREAD = $(BLD)/tmp-$(ARCH)-sysroot-thread

ifneq ($(KNAME),)
KCONF = $(PRJ)/kbuilds/$(KNAME).mk
ifneq ($(wildcard $(KCONF)),)
include $(KCONF)
endif
ifeq ($(KOBJNAME),)
KOBJNAME = $(KNAME)$(ENDIAN_SUFFIX)
endif
KOBJDIR = $(KOBJ_BASE)/$(KOBJNAME)
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
	cp arch/c6x/configs/$(DEFCONFIG) $(KOBJDIR)/.config
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
	make ARCH=c6x O=$(KOBJDIR)/ oldconfig
	make ARCH=c6x O=$(KOBJDIR)/
	make ARCH=c6x O=$(KOBJDIR)/ DEPMOD=$(DEPMOD) INSTALL_MOD_PATH=$(MOD_DIR) modules_install
	cp $(KOBJDIR)/vmlinux $(PRODUCT_DIR)/vmlinux-$(KERNEL_FNAME)
	objcopy -I elf32-$(ENDIAN) -O binary $(PRODUCT_DIR)/vmlinux-$(KERNEL_FNAME) $(PRODUCT_DIR)/vmlinux-$(KERNEL_FNAME).bin

kernel-headers: kernels
	$(SUB_MAKE) -C $(LINUX_C6X_KERNEL_DIR) CROSS_COMPILE=$(CC_SDK0) \
		ENDIAN=$(KERNEL_HEADERS_ENDIAN) KNAME=$(KERNEL_HEADERS_KERNEL) kernel-headers-sub

kernel-headers-sub:
	if [ ! -d $(KHDR_DIR)/include/asm ]; then   \
		mkdir -p $(KHDR_DIR) ;  \
		make -C $(LINUX_C6X_KERNEL_DIR) ARCH=c6x CROSS_COMPILE=$(CC_SDK0) \
		        INSTALL_HDR_PATH=$(KHDR_DIR) O=$(KOBJDIR) headers_install ; \
	fi

one-clib: $(call COND_DEP, sdk0 kernel-headers)
	[ -d $(BLD)/uClibc$(ENDIAN_SUFFIX) ] || mkdir -p $(BLD)/uClibc$(ENDIAN_SUFFIX)
	cp -a $(UCLIBC_SRCDIR)/* $(BLD)/uClibc$(ENDIAN_SUFFIX)
	$(SUB_MAKE) -C $(BLD)/uClibc$(ENDIAN_SUFFIX) CROSS_COMPILE=ensure_not_used CROSS=$(CC_UCLIBC) clib-sub
	if [ "$(BUILD_USERSPACE_WITH_GCC)" != "yes" ] ; then \
		[ -d $(BLD)/uClibc-pthread$(ENDIAN_SUFFIX) ] || mkdir -p $(BLD)/uClibc-pthread$(ENDIAN_SUFFIX) ; \
		cp -a $(UCLIBC_SRCDIR)/* $(BLD)/uClibc-pthread$(ENDIAN_SUFFIX) ; \
		$(SUB_MAKE) -C $(BLD)/uClibc-pthread$(ENDIAN_SUFFIX) CROSS_COMPILE=ensure_not_used CROSS=$(CC_UCLIBC) clib-sub-pthread ; \
	fi

UCLIBC_CONFIG = $(PRJ)/uclibc-configs/$(UCLIBC_CONFIGNAME)

$(BLD)/uClibc$(ENDIAN_SUFFIX)/.config: $(UCLIBC_CONFIG)
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
	    fi \
	fi
	make oldconfig

UCLIBC_THR_CONFIG = $(PRJ)/uclibc-configs/$(UCLIBC_THR_CONFIGNAME)

$(BLD)/uClibc-pthread$(ENDIAN_SUFFIX)/.config: $(UCLIBC_THR_CONFIG)
	cp $(UCLIBC_THR_CONFIG) .config
	make oldconfig

clib-sub: $(BLD)/uClibc$(ENDIAN_SUFFIX)/.config
	make

clib-sub-pthread: $(BLD)/uClibc-pthread$(ENDIAN_SUFFIX)/.config
	make

BBOX_CONFIG = $(BLD)/busybox$(ENDIAN_SUFFIX)/$(BBOX_CONFIGNAME)

one-busybox:  $(call COND_DEP, one-sdk)
	[ -d $(BLD)/busybox$(ENDIAN_SUFFIX) ] || mkdir -p $(BLD)/busybox$(ENDIAN_SUFFIX)
	cp $(PRJ)/busybox-configs/$(BBOX_CONFIGNAME) $(BBOX_CONFIG)
	if [ "$(BUILD_USERSPACE_WITH_GCC)" == "yes" ] ; then \
	    sed -i -e 's,CONFIG_CROSS_COMPILER_PREFIX=*,CONFIG_CROSS_COMPILER_PREFIX="$(CC_SDK)",' \
		   -e 's,-dsbt,-mdsbt -D__DSBT__,' \
		 $(BBOX_CONFIG) ; \
	    if [ "$(ENDIAN)" != "little" ] ; then \
		sed -i -e 's,-D__DSBT__,-D__DSBT__ -mbig-endian,' \
		   $(BBOX_CONFIG) ; \
	    fi \
	fi
	$(SUB_MAKE) -C $(BLD)/busybox$(ENDIAN_SUFFIX) \
		CONF=$(BBOX_CONFIG) CROSS=$(CC_SDK) ENDIAN=$(ENDIAN) busybox-sub ; \

ifeq ($(BUILD_STATIC_BBOX),yes)
BBOX_EXTRA = -static
endif
ifeq ($(BUILD_USERSPACE_WITH_GCC),yes)
ifneq ($(ENDIAN),little)
BBOX_EXTRA += -mbig-endian
endif
endif

BBOX_MAKE = make ARCH=c6x CROSS_COMPILE=$(CC_SDK) KBUILD_SRC=$(TOP)/busybox \
		-f $(TOP)/busybox/Makefile

busybox-sub: $(BLD)/busybox$(ENDIAN_SUFFIX)/.config_done
	rm -rf $(BBOX_DIR)
	mkdir -p $(BBOX_DIR)
	$(BBOX_MAKE) EXTRA_LDFLAGS="$(BBOX_EXTRA)"
	$(BBOX_MAKE) EXTRA_LDFLAGS="$(BBOX_EXTRA)" CONFIG_PREFIX=$(BBOX_DIR) install

$(BLD)/busybox$(ENDIAN_SUFFIX)/.config_done: $(CONF) $(PRJ)/Makefile
	cp $(CONF) .config
	$(BBOX_MAKE) oldconfig
	cp $(CONF) $@

one-mtd: $(call COND_DEP, one-sdk)
	[ -d $(BLD)/mtd-utils$(ENDIAN_SUFFIX) ] || mkdir -p $(BLD)/mtd-utils$(ENDIAN_SUFFIX)
	$(SUB_MAKE) -C $(BLD)/mtd-utils$(ENDIAN_SUFFIX) CROSS=$(CC_SDK) ENDIAN=$(ENDIAN) mtd-sub

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

one-sdk0:
	if [ -e $(SDK0_DIR)/linux-$(ARCHe)-sdk0-prebuilt ] ; then 	\
	    echo using pre-built sdk0;				\
	else	    						\
	    if [ -e $(TOOL_WRAP_DIR)/Makefile ] ; then 		\
		cd $(TOOL_WRAP_DIR); $(MAKE) ENDIAN=$(ENDIAN) ABI=$(ABI) DSBT_SIZE=$(DSBT_SIZE) \
			GCC_C6X_DEST=$(SDK0_DIR) ALIAS=$(ALIAS) all;	\
	    else									\
		echo "You must install the prebuilt sdk0 or the build kit for it";	\
		false;						\
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
	    if [ -e $(SDK0_DIR)/bin/$(ARCH)-linux-gcc ] ; then 	\
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
		make -C $(BLD)/uClibc$(ENDIAN_SUFFIX) CROSS=$(CC_SDK0) PREFIX=$(SYSROOT_TMP_DIR) install ; \
		[ -e $(SYSROOT_TMP_DIR_THREAD) ] || mkdir -p $(SYSROOT_TMP_DIR_THREAD) ; \
		make -C $(BLD)/uClibc-pthread$(ENDIAN_SUFFIX) CROSS=$(CC_SDK0) PREFIX=$(SYSROOT_TMP_DIR_THREAD) install ; \
		mv -f $(BLD)/uClibc-pthread$(ENDIAN_SUFFIX)/lib/libc.a $(BLD)/uClibc-pthread$(ENDIAN_SUFFIX)/lib/libc-pthread.a ; \
		rsync -rlpgocv --ignore-existing $(SYSROOT_TMP_DIR_THREAD)/ $(SYSROOT_TMP_DIR)/ ; \
		rsync -rlpgocv --delete $(SYSROOT_TMP_DIR)/ $(SYSROOT_DIR)/ ; \
	else \
		make -C $(BLD)/uClibc$(ENDIAN_SUFFIX) CROSS=$(CC_GNU) PREFIX=$(SYSROOT_DIR) install ; \
	fi

sdk-clean:
	rm -rf $(SDK_DIR)

one-rootfs: $(ROOTFS)-$(ARCHe) bootblob

min-root-$(ARCHe): productdir $(call COND_DEP, one-busybox) $(call COND_DEP, one-mtd)
	if [ -d $(BLD)/rootfs/$@ -a -e $(BLD)/rootfs/$@-marker ] ; then rm -rf $(BLD)/rootfs/$@; fi
	mkdir -p $(BLD)/rootfs/$@; date > $(BLD)/rootfs/$@-marker
	(cd $(BLD)/rootfs/$@; cpio -i <$(PRJ)/rootfs/min-root-skel.cpio)
	cp -a $(BBOX_DIR)/* $(BLD)/rootfs/$@
	cp -a $(MTD_DIR)/* $(BLD)/rootfs/$@
	cp -a rootfs/min-root-extra/* $(BLD)/rootfs/$@
	cp -a $(MOD_DIR)/* $(BLD)/rootfs/$@
	if [ -n $(EXTRA_ROOT_DIR) ] ; then for dir in $(EXTRA_ROOT_DIR); do cp -a $$dir/rootfs/* $(BLD)/rootfs/$@ ; done ; fi
	(cd $(SYSROOT_DIR) ; tar --exclude='*.a' -cf - lib | (cd $(BLD)/rootfs/$@; tar xf -))
	(cd $(SYSROOT_DIR) ; tar --exclude='*.a' -cf - usr/lib | (cd $(BLD)/rootfs/$@; tar xf -))
	cp rootfs/min-root-devs.cpio $(BLD)/rootfs/$@.cpio
	(cd $(BLD)/rootfs/$@; find . | cpio -H newc -o -A -O ../$@.cpio)
	gzip -c $(BLD)/rootfs/$@.cpio > $(PRODUCT_DIR)/$@.cpio.gz

bootblob: productdir
	cp -a $(PRJ)/bootblob $(PRODUCT_DIR)/

productdir:
	[ -d $(PRODUCT_DIR) ] || mkdir -p $(PRODUCT_DIR)

product-clean:
	rm -rf $(PRODUCT_DIR)

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

one-min-root-clean:
	rm -rf $(BLD)/rootfs/min-root-$(ARCHe)
	rm -rf $(BLD)/rootfs/min-root-$(ARCHe).cpio

one-clean: one-mtd-clean one-busybox-clean one-clib-clean one-sdk-clean one-min-root-clean
	rm -rf $(MOD_DIR) $(HDR_DIR) $(BBOX_DIR)
	rm -rf $(KOBJ_BASE)
	make sdk0-clean
