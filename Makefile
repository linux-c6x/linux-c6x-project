# Top level makefile for linux-c6x project
# Real dumb; always does target and its dependencies
# Any work saving is in the sub-makefiles
# This is intentional not modular or distributed to keep this simple case in one place
# Real distribution build will be done w/ bitbake

all: product

product: rootfs extra-kernels

DATE = $(shell date +'%Y%m%d')

# These targets can be built little-endian and/or big-endian
TOP_TARGETS = rootfs mtd rio busybox packages sdk clib kernels sdk0 clean mtd-clean rio-clean busybox-clean packages-clean clib-clean extra-kernels

# These sub-targets build only little-endian or big-endian
ENDIAN_TARGETS = one-rootfs one-mtd one-rio one-busybox one-sdk one-clib one-kernels one-sdk0 \
	one-kernels-clean one-uclibc-clean one-mtd-clean one-rio-clean one-busybox-clean min-root-clean full-root-clean one-clean \
	one-extra-kernels one-packages one-packages-clean

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
RPM_CROSS_DIR=$(BLD)/packages$(ENDIAN_SUFFIX)

ABI           ?= elf
DSBT_SIZE     ?= 64
KERNELS_TO_BUILD ?= dsk6455 evm7472
EXTRA_KERNELS_TO_BUILD ?=
BUILD_KERNEL_WITH_GCC ?=
BUILD_USERSPACE_WITH_GCC ?=
BUILD_STATIC_BBOX ?= yes
ROOTFS ?= min-root

# SysLink kernel samples to build
SYSLINK_KERNEL_SAMPLES_TO_BUILD ?= notify gateMP heapBufMP heapMemMP listMP messageQ sharedRegion
# SysLink user land samples to build
SYSLINK_USER_SAMPLES_TO_BUILD ?= procMgr $(SYSLINK_KERNEL_SAMPLES_TO_BUILD)


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
FARCH		= $(ARCHe)-$(ARCHabi)

# SDK0 is a compiler only w/o C library. it is used to build kernel and C library
# SDK is SDK0 + c library and is used for busybox and other user apps and libraries
CC_SDK0=$(SDK0_DIR)/bin/$(FARCH)-linux-
CC_GNU=$(GNU_TOOLS_DIR)/bin/$(ARCH)-uclinux-

ifeq ($(BUILD_USERSPACE_WITH_GCC),yes)
CC_SDK=$(SDK_DIR)/bin/$(ARCH)-uclinux-
CC_UCLIBC = $(CC_GNU)
UCLIBC_CONFIGNAME = uClibc-0.9.30-cs.config
UCLIBC_SRCDIR = $(TOP)/uclibc-ti-$(ARCH)
ifeq ($(ENDIAN),little)
SYSROOT_DIR	= $(SDK_DIR)/$(ARCH)-uclinux/libc
else
SYSROOT_DIR	= $(SDK_DIR)/$(ARCH)-uclinux/libc/be
endif
else
CC_SDK=$(SDK_DIR)/bin/$(FARCH)-linux-
CC_UCLIBC = $(CC_SDK0)
UCLIBC_CONFIGNAME = uClibc-0.9.30-c64xplus-shared.config
UCLIBC_THR_CONFIGNAME = uClibc-0.9.30-c64xplus-shared-thread.config
UCLIBC_SRCDIR = $(TOP)/uClibc
SYSROOT_DIR	= $(SDK_DIR)/$(FARCH)-sysroot
endif
BBOX_CONFIGNAME ?= busybox-1.00-full-$(ARCH).config

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

RIO_SRC = $(TOP)/projects/rio-utils

# install rio  here
RIO_DIR = $(BLD)/rootfs/rio-utils-$(ARCHe)

PACKAGES_SRC = $(TOP)/projects/packages/
PACKAGES_BIN = $(TOP)/projects/package-downloads/
PACKAGES_DIR = $(BLD)/rootfs/packages-$(ARCHe)

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

BBOX_MAKE = make ARCH=$(ARCH) CROSS_COMPILE=$(CC_SDK) KBUILD_SRC=$(TOP)/busybox \
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
	(export CROSS_ROOTDEVDIR=$(SYSROOT_DIR) ;$(PRJ)/cross-rpm/pkg_build_all $(ARCHe) )
	[ -d $(PACKAGES_DIR) ] || mkdir -p $(PACKAGES_DIR)
	(export CROSS_ROOTDIR=$(PACKAGES_DIR) ; $(PRJ)/cross-rpm/pkg_install_linuxroot $(ARCHe))


$(SDK_DIR)/rpm:
	$(PRJ)/build-rpm.sh

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
		cp -a $(GNU_TOOLS_DIR)/$(ARCH)-uclinux/{bin,lib,share} $(SDK_DIR)/$(ARCH)-uclinux ; \
		[ -d $(SYSROOT_DIR)/usr/include/asm ] || cp -a $(KHDR_DIR) $(SYSROOT_DIR) ; \
		(cd $(SDK_DIR)/bin; ls | cut -d\- -f3 | sort -u | xargs -i ln -sf $(ARCH)-uclinux-"{}" $(ARCH)-linux-"{}" ) ; \
		(cd $(SDK_DIR)/bin; ls | cut -d\- -f3 | sort -u | xargs -i ln -sf $(ARCH)-uclinux-"{}" $(ARCH)eb-linux-"{}" ) ; \
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
	cp -a $(RIO_DIR)/* $(BLD)/rootfs/$@
	cp -a rootfs/min-root-extra/* $(BLD)/rootfs/$@
	cp -a $(MOD_DIR)/* $(BLD)/rootfs/$@
	if [ -n $(EXTRA_ROOT_DIR) ] ; then for dir in $(EXTRA_ROOT_DIR); do cp -a $$dir/rootfs/* $(BLD)/rootfs/$@ ; done ; fi
	(cd $(SYSROOT_DIR) ; tar --exclude='*.a' -cf - lib | (cd $(BLD)/rootfs/$@; tar xf -))
	(cd $(SYSROOT_DIR) ; tar --exclude='*.a' -cf - usr/lib | (cd $(BLD)/rootfs/$@; tar xf -))
	cp rootfs/min-root-devs.cpio $(BLD)/rootfs/$@.cpio
	(cd $(BLD)/rootfs/$@; find . | cpio -H newc -o -A -O ../$@.cpio)
	gzip -c $(BLD)/rootfs/$@.cpio > $(PRODUCT_DIR)/$@.cpio.gz

full-root-$(ARCHe): productdir $(call COND_DEP, one-busybox) $(call COND_DEP, one-mtd) $(call COND_DEP, one-rio) $(call COND_DEP, one-packages)
	if [ -d $(BLD)/rootfs/$@ -a -e $(BLD)/rootfs/$@-marker ] ; then rm -rf $(BLD)/rootfs/$@; fi
	mkdir -p $(BLD)/rootfs/$@; date > $(BLD)/rootfs/$@-marker
	(cd $(BLD)/rootfs/$@; cpio -i <$(PRJ)/rootfs/min-root-skel.cpio)
	cp -a $(BBOX_DIR)/* $(BLD)/rootfs/$@
	cp -a $(MTD_DIR)/* $(BLD)/rootfs/$@
	cp -a $(RIO_DIR)/* $(BLD)/rootfs/$@
	cp -a $(PACKAGES_DIR)/* $(BLD)/rootfs/$@
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
	rm -rf $(BLD)/rootfs/min-root-$(ARCHe)
	rm -rf $(BLD)/rootfs/min-root-$(ARCHe).cpio

one-full-root-clean:
	rm -rf $(BLD)/rootfs/full-root-$(ARCHe)
	rm -rf $(BLD)/rootfs/full-root-$(ARCHe).cpio

one-clean: one-mtd-clean one-rio-clean one-busybox-clean one-clib-clean one-sdk-clean one-min-root-clean one-full-root-clean
	rm -rf $(MOD_DIR) $(HDR_DIR) $(BBOX_DIR)
	rm -rf $(KOBJ_BASE)
	make sdk0-clean


# SysLink build targets
ifeq ($(SYSLINK_PLATFORM),C6472)
SYSLINK_PLATFORM=C6472
KDIR=$(LINUX_C6X_TOP_DIR)/Build/kobjs/evmc6472.el
else
ifeq ($(SYSLINK_PLATFORM),C6474)
SYSLINK_PLATFORM=C6474
KDIR=$(LINUX_C6X_TOP_DIR)/Build/kobjs/evmc6474.el
endif
endif

syslink-help:
	@echo "First edit and source setenv for SysLink variables"
	@echo
	@echo "Following SysLink targets available:-"
	@echo "syslink-kernel - for building syslink and sample kernel modules"
	@echo "syslink-user - for building syslink library and user land samples"
	@echo "syslink-all - build all targets"
	@echo "syslink-kernel-clean - clean kernel and sample modules"
	@echo "syslink-user-clean - clean user land and sample exe files"
	@echo "syslink-clean - clean all targets"
	@echo
	@echo "syslink files are installed under product/<platform>/"

syslink-kernel:
ifeq ($(SYSLINK_PLATFORM),)
	@echo "No SYSLINK_PLATFORM defined"; \
	false;
endif
	if [ ! -d $(SYSLINK_ROOT) ] ; then echo "Install SysLink before build"; false ; fi
	if [ ! -d $(IPC_DIR) ] ; then echo "Install IPC package before build"; false ; fi
	@echo "building syslink kernel module"
	(cd $(SYSLINK_ROOT)/ti/syslink/utils/hlos/knl/Linux; \
	make ARCH=$(ARCH) CROSS_COMPILE=$(CC_SDK0) SYSLINK_PLATFORM=$(SYSLINK_PLATFORM) \
	KDIR=$(KDIR) IPC_DIR=$(IPC_DIR));

# build all kernel sample modules
	for module_name in $(SYSLINK_KERNEL_SAMPLES_TO_BUILD) ; do \
		echo building $$module_name; \
		(cd $(SYSLINK_ROOT)/ti/syslink/samples/hlos/$$module_name/knl/Linux; \
		make ARCH=$(ARCH) CROSS_COMPILE=$(CC_SDK0) SYSLINK_PLATFORM=$(SYSLINK_PLATFORM) \
		KDIR=$(KDIR) IPC_DIR=$(IPC_DIR)) \
	done;

syslink-user:
	if [ ! -d $(SYSLINK_ROOT) ] ; then echo "Install SysLink before build"; false ; fi
	if [ ! -d $(IPC_DIR) ] ; then echo "Install IPC package before build"; false ; fi
	@echo "building user syslink library"
	(cd $(SYSLINK_ROOT)/ti/syslink/utils/hlos/usr/Linux; \
	make TOOLCHAIN_PREFIX=$(CC_SDK) SYSLINK_PLATFORM=$(SYSLINK_PLATFORM) \
	KDIR=$(KDIR) IPC_DIR=$(IPC_DIR))
	for module_name in $(SYSLINK_USER_SAMPLES_TO_BUILD) ; do \
		echo building $$module_name; \
		(cd $(SYSLINK_ROOT)/ti/syslink/samples/hlos/$$module_name/usr/Linux; \
		make TOOLCHAIN_PREFIX=$(CC_SDK) SYSLINK_PLATFORM=$(SYSLINK_PLATFORM) \
		KDIR=$(KDIR) IPC_DIR=$(IPC_DIR)) \
	done	

syslink-all:syslink-kernel syslink-user syslink-install

syslink-install:
	[ -d $(PRODUCT_DIR) ] || echo "no product directory"
	[ -d $(PRODUCT_DIR)/syslink_$(SYSLINK_PLATFORM) ] || mkdir -p $(PRODUCT_DIR)/syslink_$(SYSLINK_PLATFORM)
	@echo "Installing user land sample exe files"
	cp -f $(SYSLINK_ROOT)/ti/syslink/lib/samples/*.exe $(PRODUCT_DIR)/syslink_$(SYSLINK_PLATFORM)/
	@echo "Installing kernel and sample modules"
	cp -f $(SYSLINK_ROOT)/ti/syslink/lib/modules/$(SYSLINK_PLATFORM)/*.ko \
		 $(PRODUCT_DIR)/syslink_$(SYSLINK_PLATFORM)/

syslink-kernel-clean:
	(cd $(SYSLINK_ROOT)/ti/syslink/utils/hlos/knl/Linux; \
	make ARCH=$(ARCH) CROSS_COMPILE=$(CC_SDK0) SYSLINK_PLATFORM=$(SYSLINK_PLATFORM) \
	KDIR=$(KDIR) IPC_DIR=$(IPC_DIR) clean)
	rm -rf $(PRODUCT_DIR)/syslink_$(SYSLINK_PLATFORM)/*.ko

syslink-user-clean:
	@echo "cleaning user syslink library"
	(cd $(SYSLINK_ROOT)/ti/syslink/utils/hlos/usr/Linux; \
	make TOOLCHAIN_PREFIX=$(CC_SDK) SYSLINK_PLATFORM=$(SYSLINK_PLATFORM) \
	KDIR=$(KDIR) IPC_DIR=$(IPC_DIR) clean)
	for module_name in $(SYSLINK_USER_SAMPLES_TO_BUILD) ; do \
		echo cleaning $$module_name; \
		(cd $(SYSLINK_ROOT)/ti/syslink/samples/hlos/$$module_name/usr/Linux; \
		make TOOLCHAIN_PREFIX=$(CC_SDK) SYSLINK_PLATFORM=$(SYSLINK_PLATFORM) \
		KDIR=$(KDIR) IPC_DIR=$(IPC_DIR) clean) \
	done	
	rm -rf $(PRODUCT_DIR)/syslink_$(SYSLINK_PLATFORM)/*.exe

syslink-clean:syslink-kernel-clean syslink-user-clean
