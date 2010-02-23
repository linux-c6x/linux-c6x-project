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

ifeq ($(ENDIAN),little)
CC_SDK0=$(SDK0_DIR)/bin/c6x-linux-
CC_SDK=$(SDK_DIR)/bin/c6x-linux-
else
CC_SDK0=$(SDK0_DIR)/bin/c6xeb-linux-
CC_SDK=$(SDK_DIR)/bin/c6xeb-linux-
endif

#GCC library path
SDK_LIB_PATH=$(SDK_DIR)/lib/gcc-lib/c6x/3.2.2
SDK0_LIB_PATH=$(SDK0_DIR)/lib/gcc-lib/c6x/3.2.2
#Path for CIL executables/libraries
SDK_CIL_PATH=$(SDK0_DIR)/cil

#gdb source paths
GDB=$(TOP)/gdb
GDBSERVER=$(GDB)/gdb/gdbserver

#cil source path
CIL=$(TOP)/cil

#binutils path
GCC_C6X=$(TOP)/gcc-c6x
#BIN_UTILS=$(GCC_C6X)/c6x-tools/binutils
#POSTLINKER=$(GCC_C6X)/c6x-tools/postlinker
#COFF_TOOLS=$(GCC_C6X)/c6x-tools/coff-tool
#LIBCOFF=$(GCC_C6X)/c6x-tools/libcoff

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
	@echo $(if $(ONLY),skipping conditional dependencies,using full dependencies)

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

gdb:
	@echo building gdb...
	(cd $(GDB); ./configure --enable-gdbtk  --target=c64xplus-linux --program-prefix=c64xplus-linux- --host=i386-linux --build=i386-linux;)
	(cd $(GDB); make CFLAGS=-O;) 
	cp -f $(GDB)/gdb/gdb $(SDK0_DIR)/bin/c64xplus-linux-gdb
	cp -f $(GDB)/gdb/gdbtui $(SDK0_DIR)/bin/c64xplus-linux-gdbtui

gdb_clean:
	(cd $(GDB); make clean;)

gdbserver:$(call COND_DEP, sdk)
	@echo building gdbserver...
	(cd $(GDBSERVER); CC=$(CROSS)gcc ./configure --host=$(ARCH)-linux --target=$(ARCH)-linux;)
	(cd $(GDBSERVER); make CC=$(CROSS)gcc LDFLAGS=-Wl,-ar,-L$(SDK_LIB_PATH) CFLAGS="-Dfork=vfork";)
	cp -f $(GDBSERVER)/gdbserver $(SDK0_DIR)/bin/c64xplus-linux-gdbserver

gdbserver_clean:
	(cd $(GDBSERVER); make clean;)

gdb-all: gdb gdb-server

gdb-all_clean: gdb_clean gdb-server_clean

cil:
	@if [ -e $(SDK0_DIR)/linux-cil-build-done ] ; then 	\
		echo using pre-built cil objects;		\
	else							\
		if [ -e $(SDK0_DIR)/linux-cil-build-done ] ; then \
		rm -rf $(SDK_CIL_PATH); 			\
		fi;						\
		mkdir -p $(SDK_CIL_PATH);			\
		$(SUB_MAKE) cil_sub;				\
	fi							\

cil_sub:
	@echo configuring cil...
	(cd $(CIL); ./configure --target=i386-linux --prefix=$(SDK_CIL_PATH);) 
	(cd $(CIL); mkdir -p obj; mkdir -p obj/.depend; mkdir -p obj/x86_LINUX;)
	@echo building cil...
	(cd $(CIL); make NATIVECAML=  LINK_FLAGS="-cclib -static" -f Makefile.cil;)
	(cd $(CIL); make NATIVECAML=1 LINK_FLAGS="-cclib -static" -f Makefile.cil;)
#	(cd $(CIL); make LINK_FLAGS="-cclib -static" -f Makefile.cil;)
	@echo installing cil libraries...
	(cd $(CIL); make install;) 
	mkdir -p $(SDK_CIL_PATH)/bin
#	install -m 644 $(CIL)/bin/CilConfig.pm $(SDK_CIL_PATH)/bin
#	install -m 755 $(CIL)/bin/cilly $(SDK_CIL_PATH)/bin
#	install -m 755 $(CIL)/bin/patcher $(SDK_CIL_PATH)/bin
#	install -m 755 $(CIL)/bin/cilly $(SDK_CIL_PATH)/bin
#	install -m 755 $(CIL)/bin/teetwo $(SDK_CIL_PATH)/bin
#	install -m 755 $(CIL)/bin/test-bad $(SDK_CIL_PATH)/bin
	mkdir -p $(SDK_CIL_PATH)/cil/obj/x86_LINUX
	cp -f $(CIL)/obj/x86_LINUX/cilly.asm.exe $(SDK_CIL_PATH)/cil/obj/x86_LINUX

cil_clean:
	rm -rf $(SDK_CIL_PATH)
	rm -f $(SDK0_LIB_PATH)/cilly
	(cd $(CIL); make -f Makefile.cil clean;)

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
	    if [ -e $(SDK0_DIR)/linux-c6x-sdk0-marker ] ; then 	\
		rm -rf $(SDK0_DIR); 				\
	    fi;							\
	    mkdir -p $(SDK0_DIR);				\
	    mkdir -p $(SDK0_DIR)/bin;				\
	    mkdir -p $(SDK0_DIR)/lib;				\
	    $(SUB_MAKE) sdk0_sub;				\
	    touch $(SDK0_DIR)/linux-c6x-sdk0-marker;		\
	fi;							\

sdk0_clean:
	@if [ -e $(SDK0_DIR)/linux-c6x-sdk0-prebuilt ] ; then 	\
	    echo "using pre-built sdk0 (skip clean)";		\
	else	    						\
	    if [ -e $(SDK0_DIR)/linux-c6x-sdk0-marker ] ; then 	\
		rm -rf $(SDK0_DIR); 				\
	    fi;							\
	fi							\

sdk0_sub:
	@echo not really building up SDK0 yet
	cp -pr $(GCC_WRAP_DIR)/* $(SDK0_DIR)
# Just remove the bin and lib folders from this since we are going to populate
# them as part of the build	
	rm -rf $(SDK0_DIR)/bin/* $(SDK0_DIR)/lib/gcc-lib/*
	$(SUB_MAKE) cil
	(cd $(GCC_C6X); make GNU_DIR=$(TOP)/gnu-gcc CGTOOLS_SRC=$(GCC_WRAP_DIR)/cgtools CIL_C6X_DIR=$(SDK_CIL_PATH) TOP_ENDIAN=$(ENDIAN) all;) 
	cp -pr $(GCC_C6X)/bin/* $(SDK0_DIR)/bin
	cp -pr $(GCC_C6X)/lib/gcc-lib/* $(SDK0_DIR)/lib/gcc-lib

gcc-c6x_clean:
	(cd $(GCC_C6X); make CIL_C6X_DIR=$(SDK_CIL_PATH) clean;)

sdk0_clean: cil_clean gcc-c6x_clean
	if [ -e $(SDK0_DIR)/linux-c6x-sdk0-marker ] ; then rm -rf $(SDK0_DIR); fi

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
ifeq ($(ENDIAN),little)
	cp -pr $(SDK_DIR)/usr/include/* $(SDK_DIR)/lib/gcc-lib/c6x/3.2.2/include
	cp -pr $(SDK_DIR)/usr/lib/*     $(SDK_DIR)/lib/gcc-lib/c6x/3.2.2
else
	cp -pr $(SDK_DIR)/usr/include/* $(SDK_DIR)/lib/gcc-lib/c6xeb/3.2.2/include
	cp -pr $(SDK_DIR)/usr/lib/*     $(SDK_DIR)/lib/gcc-lib/c6xeb/3.2.2
endif

sdk-prebuilt-clib:	sdk0 sdk-fresh
	(cd $(SDK_DIR); rpm2cpio $(PRJ)/uclibc/uClibc-devel-0.9.28-5jl_nommu.c64xplus.rpm | cpio -i --make-directories)
	(cd $(SDK_DIR); rpm2cpio $(PRJ)/uclibc/uClibc-kernheaders-1.0-3jl_nommu.c64xplus.rpm | cpio -i --make-directories)
	@echo the specs for the stock vlx gcc are kind of funny, mush everything together
	cp -pr $(SDK0_DIR)/* $(SDK_DIR)
ifeq ($(ENDIAN),little)
	cp -pr $(SDK_DIR)/usr/include/* $(SDK_DIR)/lib/gcc-lib/c6x/3.2.2/include
	cp -pr $(SDK_DIR)/usr/lib/*     $(SDK_DIR)/lib/gcc-lib/c6x/3.2.2
else
	cp -pr $(SDK_DIR)/usr/include/* $(SDK_DIR)/lib/gcc-lib/c6xeb/3.2.2/include
	cp -pr $(SDK_DIR)/usr/lib/*     $(SDK_DIR)/lib/gcc-lib/c6xeb/3.2.2
endif

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
	$(SUB_MAKE) sdk0_clean
	if [ -e $(SDK_DIR)/linux-c6x-sdk-marker ] ; then rm -rf $(SDK_DIR); fi
	rm $(PRODUCT_DIR)/*.cpio.gz $(PRODUCT_DIR)/*.pad.bin $(PRODUCT_DIR)/vmlinux.out*

