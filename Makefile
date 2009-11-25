# Top level makefile for linux-c6x project
# Real dumb; always does target and its dependencies
# Any work saving is in the sub-makefiles
# This is intentional not modular or distributed to keep this simple case in one place
# Real distribution build will be done w/ bitbake

ALL_TARGETS= sdk0 kernel clib sdk hello busybox hello-root min-root product zapmem
def_target: product
all: $(ALL_TARGETS)
.PHONY: $(ALL_TARGETS) clean kernel-sub clib-sub busybox-sub

$(ALL_TARGETS): sanity

PRJ=$(LINUX_C6X_PROJECT_DIR)
TOP=$(LINUX_C6X_TOP_DIR)

# SDK0 is a compiler only w/o C library. it is used to build kernel and C library
# SDK is compiler & c library and is used for busybox and other user apps and libraries
CC_SDK0=$(SDK0_DIR)/bin/c6x-linux-
CC_SDK=$(SDK_DIR)/bin/c6x-linux-

SUB_MAKE=$(MAKE) -f $(PRJ)/Makefile

ONLY=
COND_DEP=$(if $(ONLY),,$(1))

ifeq ("$(DEBUG)","")
    K_DEBUG_LINE=\\\# CONFIG_DEBUG_INFO is not set
else
    K_DEBUG_LINE=CONFIG_DEBUG_INFO=y
endif


sanity:
	@if [ -z "$$LINUX_C6X_TOP_DIR" ] ; then echo Does not look like setenv has been setup; exit 1; fi
	echo $(if $(ONLY),skipping conditional dependencies,using full dependencies)

kernel: $(call COND_DEP, sdk0)
	$(SUB_MAKE) -C $(TOP)/linux-c6x CROSS=should_not_be_used- CROSS_COMPILE=$(CC_SDK0) kernel-sub

kernel-sub: 
	make $(DEFCONFIG)
	mv .config .config.before
	grep -v "CONFIG_DEBUG_INFO[= ]" .config.before >.config
	echo $(K_DEBUG_LINE) >> .config
	make

clib: $(call COND_DEP, sdk0 kernel)
	$(SUB_MAKE) -C $(TOP)/uClibc CROSS_COMPILE=ensure_not_used CROSS=$(CC_SDK0) clib-sub

clib-sub:
	cp uClibc-0.9.28-c64xplus.config .config
	make oldconfig
	make

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
	if [ -e $(SDK0_DIR)/linux-c6x-sdk0-marker ] ; then rm -rf $(SDK0_DIR); fi
	mkdir -p $(SDK0_DIR)
	touch $(SDK0_DIR)/linux-c6x-sdk0-marker
	@echo not really building up SDK0 yet
	cp -pr $(GCC_WRAP_DIR)/* $(SDK0_DIR)

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
	cp -pr $(SDK_DIR)/usr/include/* $(SDK_DIR)/lib/gcc-lib/c6x/3.2.2/include
	cp -pr $(SDK_DIR)/usr/lib/*     $(SDK_DIR)/lib/gcc-lib/c6x/3.2.2

sdk-prebuilt-clib:	sdk0 sdk-fresh
	(cd $(SDK_DIR); rpm2cpio $(PRJ)/uclibc/uClibc-devel-0.9.28-5jl_nommu.c64xplus.rpm | cpio -i --make-directories)
	(cd $(SDK_DIR); rpm2cpio $(PRJ)/uclibc/uClibc-kernheaders-1.0-3jl_nommu.c64xplus.rpm | cpio -i --make-directories)
	@echo the specs for the stock vlx gcc are kind of funny, mush everything together
	cp -pr $(SDK0_DIR)/* $(SDK_DIR)
	cp -pr $(SDK_DIR)/usr/include/* $(SDK_DIR)/lib/gcc-lib/c6x/3.2.2/include
	cp -pr $(SDK_DIR)/usr/lib/*     $(SDK_DIR)/lib/gcc-lib/c6x/3.2.2

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
	(cd rootfs; ./mkcpio $@ $@-1; gzip -c $@-1.cpio $@-devs.cpio >$@.cpio.gz)
	(cd rootfs; dd if=/dev/zero of=$@.pad.bin bs=1024 count=4096; dd conv=notrunc seek=0 if=$@.cpio.gz of=$@.pad.bin)

min-root-prebuilt-busybox:
	(cd rootfs; ./uncpio $@-skel $@)
	(cp rootfs/min-root-pgms/busybox.full rootfs/$@/bin/)
	(cp -rp rootfs/min-root-extra/* rootfs/$@)
	(cd rootfs; ./mkcpio $@ $@-1; gzip -c $@-1.cpio $@-devs.cpio >$@.cpio.gz)
	(cd rootfs; dd if=/dev/zero of=$@.pad.bin bs=1024 count=4096; dd conv=notrunc seek=0 if=$@.cpio.gz of=$@.pad.bin)

zapmem:
	(cd experiments/zapmem; ./mk-elf)

product: kernel $(ROOTFS) zapmem
	(mkdir -p $(PRODUCT_DIR))
	(cp rootfs/$(ROOTFS).cpio.gz rootfs/$(ROOTFS).pad.bin $(PRODUCT_DIR)/)
	(cp ../linux-c6x/vmlinux $(PRODUCT_DIR)/vmlinux.out)
	(cp experiments/zapmem/zapmem.elf $(PRODUCT_DIR)/)

clean:
	make -C ../linux-c6x clean
	make -C ../uClibc    clean
	make -C ../busybox   clean
	make -C ../linux-c6x clean
	if [ -e $(SDK0_DIR)/linux-c6x-sdk0-marker ] ; then rm -rf $(SDK0_DIR); fi
	if [ -e $(SDK_DIR)/linux-c6x-sdk-marker ] ; then rm -rf $(SDK_DIR); fi
	rm $(PRODUCT_DIR)/*.cpio.gz $(PRODUCT_DIR)/*.pad.bin $(PRODUCT_DIR)/vmlinux.out*
    