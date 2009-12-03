# Top level makefile for linux-c6x project
# Real dumb; always does target and its dependencies
# Any work saving is in the sub-makkefiles

ALL_TARGETS= clib sdk hello rootfs hello-root busybox min-root full-root kernel product
def_target: product
all: $(ALL_TARGETS)

$(ALL_TARGETS): sanity

PRJ=$(LINUX_C6X_PROJECT_DIR)
TOP=$(LINUX_C6X_TOP_DIR)

sanity:
	@if [ -z "$$PRODUCT_DIR" ] ; then echo Does not look like setenv has been setup; exit 1; fi

clib:
	@echo Not building the library yet

sdk:	clib
	if [ -e $(SDK_DIR)/linux-c6x-sdk-marker ] ; then rm -rf $(SDK_DIR); fi
	mkdir -p $(SDK_DIR)
	touch $(SDK_DIR)/linux-c6x-sdk-marker
	(cd $(SDK_DIR); rpm2cpio $(PRJ)/uclibc/uClibc-devel-0.9.28-5jl_nommu.c64xplus.rpm | cpio -i --make-directories)
	@echo the specs for the stock vlx gcc are kind of funny, mush everything together
	cp -pr $(GCC_WRAP_DIR)/* $(SDK_DIR)
	cp -pr $(SDK_DIR)/usr/include/* $(SDK_DIR)/lib/gcc-lib/c6x/3.2.2/include
	cp -pr $(SDK_DIR)/usr/lib/*     $(SDK_DIR)/lib/gcc-lib/c6x/3.2.2

hello:	sdk
	(cd hello; ./mk)

busybox:
	@echo Not building busybox yet

rootfs: $(ROOTFS)

hello-root: hello
	(cd rootfs; sudo ./uncpio hello-root)
	(cp hello/hello.out rootfs/hello-root/bin/hello)
	(cd rootfs; ./mkramfs hello-root)

#not ready for this one
xxx-min-root: busybox
	(cd rootfs; sudo ./uncpio min-root)
	(cp somewhere/busybox rootfs/min-root/bin/busybox)
	(cd rootfs; ./mkramfs hello-root)

# this rule good for full-root or any others that are just used from cpio.gz file
full-root min-root:
	(cd rootfs; sudo ./uncpio $@)
	(cd rootfs; ./mkramfs $@)

kernel: 
	(cd ../linux-c6x; make $(DEFCONFIG))
	(cd ../linux-c6x; make )

product: kernel $(ROOTFS)
	(mkdir -p $(PRODUCT_DIR))
	(cp rootfs/$(ROOTFS).cpio.gz.dat $(PRODUCT_DIR)/)
	(cp ../linux-c6x/vmlinux $(PRODUCT_DIR)/vmlinux.out)
