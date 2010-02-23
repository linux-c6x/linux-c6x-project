# Top level makefile for linux-c6x project
# Real dumb; always does target and its dependencies
# Any work saving is in the sub-makefiles
# This is intentional not modular or distributed to keep this simple case in one place
# Real distribution build will be done w/ bitbake

ALL_TARGETS= sdk0 kernel clib sdk hello busybox hello-root min-root product zapmem
def_target: product

.PHONY: $(ALL_TARGETS) all clean kernel-sub clib-sub busybox-sub one which_one

all:
	@if [ x$(ABI) == x"BOTH" ]; then 	\
	    $(MAKE) ABI=coff all;		\
	    $(MAKE) ABI=elf  all;   		\
	elif [ x$(ENDIAN)  == x"BOTH" ]; then	\
	    $(MAKE) ENDIAN=little all;		\
	    $(MAKE) ENDIAN=big	all;		\
	else					\
	    $(MAKE) one;			\
	fi

PRJ=$(LINUX_C6X_PROJECT_DIR)
TOP=$(LINUX_C6X_TOP_DIR)
TOOL_WRAP_DIR=$(TOP)/ti-gcc-wrap/tool-wrap

ENDIAN        := little
ABI           := coff

ifeq ($(ENDIAN),little)
ARCHendian     = 
else
ARCHendian     = eb
endif

ifeq ($(ABI),coff)
ARCHabi        = coff
else
ARCHabi        = elf
endif

ARCHe		= c6x$(ARCHendian)
ARCH		= $(ARCHe)-$(ARCHabi)

# SDK0 is a compiler only w/o C library. it is used to build kernel and C library
# SDK is compiler & c library and is used for busybox and other user apps and libraries
CC_SDK0=$(SDK0_DIR)/bin/$(ARCH)-linux-
CC_SDK=$(SDK_DIR)/bin/$(ARCH)-linux-

SUB_MAKE=$(MAKE) -f $(PRJ)/Makefile

ONLY=
COND_DEP=$(if $(ONLY),,$(1))

ifeq ("$(DEBUG)","")
    K_DEBUG_LINE=\\\# CONFIG_DEBUG_INFO is not set
else
    K_DEBUG_LINE=CONFIG_DEBUG_INFO=y
endif


one: which_one $(ALL_TARGETS)

which_one:
	@echo ENDIAN=$(ENDIAN) ABI=$(ABI) ARCH=$(ARCH)

$(ALL_TARGETS): sanity

sanity:
	@if [ -z "$$LINUX_C6X_TOP_DIR" ] ; then echo Does not look like setenv has been setup; exit 1; fi
	@echo $(if $(ONLY),skipping conditional dependencies,using full dependencies)

kernel: $(call COND_DEP, sdk0)
	$(SUB_MAKE) -C $(TOP)/linux-c6x CROSS=should_not_be_used- CROSS_COMPILE=$(CC_SDK0) kernel-sub

kernel-sub: 
	ARCH=c6x make $(DEFCONFIG)
	mv .config .config.before
	grep -v "CONFIG_DEBUG_INFO[= ]" .config.before >.config
	echo $(K_DEBUG_LINE) >> .config
	ARCH=c6x make

clib: $(call COND_DEP, sdk0 kernel)
	$(SUB_MAKE) -C $(TOP)/uClibc CROSS_COMPILE=ensure_not_used CROSS=$(CC_SDK0) clib-sub

clib-sub:
	cp uClibc-0.9.28-c64xplus.config .config
	make oldconfig
	make

# Have not finished hooking this in yet
gdbserver:$(call COND_DEP, sdk)
	@echo building gdbserver...
	(cd $(GDBSERVER); CC=$(CROSS)gcc ./configure --host=$(ARCH)-linux --target=$(ARCH)-linux;)
	(cd $(GDBSERVER); make CC=$(CROSS)gcc LDFLAGS=-Wl,-ar,-L$(SDK_LIB_PATH) CFLAGS="-Dfork=vfork";)
	mkdir -p $(SDK0_DIR)/target/$(ARCH)
	cp -f $(GDBSERVER)/gdbserver $(SDK0_DIR)/target/$(ARCH)/gdbserver

busybox: $(call COND_DEP, sdk)
	$(SUB_MAKE) -C ../busybox CONF=busybox-1.00-full-c6x.config CROSS=$(CC_SDK) busybox-sub

busybox-sub:
	mkdir -p $(PRJ)/rootfs/busybox-image
	sed -e "s|@CROSS_COMPILE@|$(CROSS)|g" \
	    -e "s|@CFLAGS@|-D__uClinux__=1|g" \
	    "$(CONF)" > .config
	make oldconfig
	make dep
	make EXTRA_LDFLAGS="-Wl,-ar" STRIP=true
	make PREFIX=$(PRJ)/rootfs/busybox-image install

sdk0:
	@if [ -e $(SDK0_DIR)/linux-c6x-sdk0-prebuilt ] ; then 	\
	    echo using pre-built sdk0;				\
	else	    						\
	    if [ -e $(TOOL_WRAP_DIR)/Makefile ] ; then 		\
		rm -rf $(SDK0_DIR); 				\
		cd $(TOOL_WRAP_DIR); $(MAKE) ENDIAN=$(ENDIAN) ABI=$(ABI) GCC_C6X_DEST=$(SDK0_DIR) ALIAS=$(ALIAS) all;	\
	    else									\
		echo "You must install the prebuilt sdk0 or the build kit for it";	\
		false;						\
	    fi;							\
	fi;							

sdk0-keep:
	touch $(SDK0_DIR)/linux-c6x-sdk0-prebuilt

sdk0-unkeep:
	-rm $(SDK0_DIR)/linux-c6x-sdk0-prebuilt

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

sdk:	sdk0 sdk-fresh clib sdk-clib sdk-kernel-headers sdk-mashup

sdk-fresh:
	if [ -e $(SDK_DIR)/linux-c6x-sdk-marker ] ; then rm -rf $(SDK_DIR); fi
	mkdir -p $(SDK_DIR)/usr
	touch $(SDK_DIR)/linux-c6x-sdk-marker

sdk-clib:
	make -C $(TOP)/uClibc CROSS_COMPILE=ensure_not_used CROSS=$(CC_SDK0) PREFIX=$(SDK_DIR) install

sdk-kernel-headers:
	# Copy the required header files
	(cd $(TOP)/linux-c6x/; \
		find include/linux include/asm include/asm-generic -follow -type f ! -name "*.hdep" | \
		cpio -pduL $(SDK_DIR)/usr)
	# Set correct access rights
	find $(SDK_DIR)/usr -type d -exec chmod 755 {} \;
	find $(SDK_DIR)/usr ! -type d -exec chmod 644 {} \;

sdk-mashup:
	@echo the specs for the stock vlx gcc are kind of funny, mush everything together
	cp -pr $(SDK0_DIR)/* $(SDK_DIR)
	cp -pr $(SDK_DIR)/usr/include/* $(SDK_DIR)/lib/gcc-lib/$(ARCH)/3.2.2/include
	cp -pr $(SDK_DIR)/usr/lib/*     $(SDK_DIR)/lib/gcc-lib/$(ARCH)/3.2.2

sdk-clean:
	if [ -e $(SDK_DIR)/linux-c6x-sdk-marker ] ; then rm -rf $(SDK_DIR); fi

rootfs: $(ROOTFS)

hello:	$(call COND_DEP, sdk)
	(cd hello; ./mk)

hello-root: $(call COND_DEP, hello)
	# start fresh after we verify we have the dir we expect
	if [ -d $(PRJ)/rootfs/$@ -a -e $(PRJ)/rootfs/mkcpio ] ; then rm -rf $(PRJ)/rootfs/$@; fi
	(cd rootfs; ./uncpio $@-skel $@)
	(cp hello/hello.out rootfs/hello-root/bin/hello)
#	(cp -rp rootfs/$@-extra/* rootfs/$@)
	(cd rootfs; ./mkcpio $@ $@-1; gzip -c $@-1.cpio $@-devs.cpio >$@.cpio.gz)
	(cd rootfs; dd if=/dev/zero of=$@.pad.bin bs=1024 count=4096; dd conv=notrunc seek=0 if=$@.cpio.gz of=$@.pad.bin)

min-root: $(call COND_DEP, busybox)
	# start fresh after we verify we have the dir we expect
	if [ -d $(PRJ)/rootfs/$@ -a -e $(PRJ)/rootfs/mkcpio ] ; then rm -rf $(PRJ)/rootfs/$@; fi
	mkdir -p $(SDK_DIR)
	touch $(SDK_DIR)/linux-c6x-sdk-marker
	(cd rootfs; ./uncpio $@-skel $@)
	(cp -rp rootfs/busybox-image/* rootfs/$@/)
	(cp -rp rootfs/$@-extra/* rootfs/$@)
	(cp rootfs/min-root-pgms/gdbserver rootfs/$@/bin/)
# not yet (cp $(SDK0)/target/$(ARCH)/gdbserver rootfs/$@/bin/)
	(cd rootfs; ./mkcpio $@ $@-1; gzip -c $@-1.cpio $@-devs.cpio >$@.cpio.gz)
	(cd rootfs; dd if=/dev/zero of=$@.pad.bin bs=1024 count=4096; dd conv=notrunc seek=0 if=$@.cpio.gz of=$@.pad.bin)

zapmem:
	(cd experiments/zapmem; ./mk-elf)

product: kernel $(ROOTFS)
	(mkdir -p $(PRODUCT_DIR))
	(cp rootfs/$(ROOTFS).cpio.gz rootfs/$(ROOTFS).pad.bin $(PRODUCT_DIR)/)
	(cp ../linux-c6x/vmlinux $(PRODUCT_DIR)/vmlinux.out)

clean:
	ARCH=c6x make -C ../linux-c6x clean
	make -C ../uClibc    clean
	make -C ../busybox   clean
	$(SUB_MAKE) sdk0-clean
	$(SUB_MAKE) sdk-clean
	rm $(PRODUCT_DIR)/*.cpio.gz $(PRODUCT_DIR)/*.pad.bin $(PRODUCT_DIR)/vmlinux.out*

