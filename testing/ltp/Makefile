# *************     LTP Build top level Makefile ****************************

BUILD_DIR=$(TOP_DIR)/Build
PFX=$(TOP_DIR)/sdk/bin
# directory where LTP source tarball is located, if not CWD.
LTP_TOP=$(TOP_DIR)/projects/ltp
LTP_SRCDIR=$(LTP_TOP)/src
ifeq ($(ENDIAN),little)
BE=""
INSTPFX=$(BUILD_DIR)/ltp.el
INSTPFX_SRC=$(INSTPFX)/ltp-full-20101031
else
INSTPFX=$(BUILD_DIR)/ltp.eb
INSTPFX_SRC=$(INSTPFX)/ltp-full-20101031
BE="big"
endif

# Use gcc if GCC defined, otherwise assume TI compiler
ifeq ($(GCC),"true")
GCC=true
else
GCC=
endif

# Set to elf or coff.  Only needed with TI compiler
ifeq ($(ABI),elf)
FMT=elf
else
FMT=coff
endif

# Number of parallel makes to run, use /proc/cpuinfo if undefined
#DASHJ=1

UCLINUX=1
DASHJ=""

CFLAGS = -DCONFIG_COLDFIRE -DHAVE_STRUCT_PTRACE_REGS
ifeq ($(GCC), "")
ifeq ($(ENDIAN),little)
TARGET=c6x-${FMT}-linux
CFLAGS += -dsbt --gcc
LDFLAGS = -dsbt --gcc -static
else
TARGET = c6xeb-${FMT}-linux
LDFLAGS = -Wl,--reread_libs -Wl,-ar -lm
endif
else
TARGET=c6x-uclinux
ifeq ($(ENDIAN),big)
CFLAGS += -mbig-endian
endif
LDFLAGS=$(CFLAGS)
endif

AR=${PFX}/${TARGET}-ar
AS=${PFX}/${TARGET}-as
CC=${PFX}/${TARGET}-gcc
LD=${PFX}/${TARGET}-ld
NM=${PFX}/${TARGET}-nm
OBJCOPY=${PFX}/${TARGET}-objcopy
OBJDUMP=${PFX}/${TARGET}-objdump
RANLIB=${PFX}/${TARGET}-ranlib
STRIP=${PFX}/${TARGET}-strip

$(INSTPFX_SRC)/Makefile.defs:
	echo "Creating Makefile.defs"
	mkdir -p $(@D)
	echo CC=${CC} >> $@.tmp
	echo AR=${AR} >> $@.tmp
	echo CFLAGS=${CFLAGS} >> $@.tmp
	echo LDFLAGS=${LDFLAGS} >> $@.tmp
	mv -f $@.tmp $@


install:
	mkdir -p ${INSTPFX}/bin
	mkdir -p ${INSTPFX}/opt 
	mkdir -p ${INSTPFX}/mnt

	if [ ! -d ${INSTPFX}/mnt/out.iso ] ; then \
		$(LTP_TOP)/bin/fsmk ${INSTPFX}/mnt/out.iso ; \
	fi;
	(cd ${INSTPFX_SRC}; PFX=${PFX} CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" \
		AR=${AR} AS=${AS} CC=${CC} LD=${LD} NM=${NM} OBJCOPY=${OBJCOPY} \
		RANLIB=${RANLIB} STRIP=${STRIP} UCLINUX=${UCLINUX} LTP_SRCDIR=${LTP_SRCDIR} \
		FMT=${FMT} GCC=${GCC} INSTPFX=${INSTPFX} DASHJ=${DASHJ} BE=${BE} \
		make DESTDIR=${INSTPFX} SKIP_IDCHECK=1 install ; )
	(cd ${INSTPFX_SRC}; cp sandbox/sandbox ${INSTPFX}/bin; )
	cp ${LTP_SRCDIR}/setup-ltp* ${INSTPFX}/bin
	cp ${LTP_SRCDIR}/fs* ${INSTPFX}/bin

all: $(INSTPFX_SRC)/Makefile.defs
	# Always start with a clean folder
	if [ -d "${INSTPFX_SRC}" ] ; then \
		echo "Removing old files" \
		rm -rf "${INSTPFX_SRC}" ; \
	fi;

	(cd ${INSTPFX}; tar -xvjf ${LTP_SRCDIR}/ltp-current.tar.bz2; )
	(cd ${INSTPFX_SRC}; patch -p0 < ${LTP_SRCDIR}/ltp.patch; make autotools; )
	(cd ${INSTPFX_SRC}; PFX=${PFX} CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" \
		AR=${AR} AS=${AS} CC=${CC} LD=${LD} NM=${NM} OBJCOPY=${OBJCOPY} \
		RANLIB=${RANLIB} STRIP=${STRIP} UCLINUX=${UCLINUX} LTP_SRCDIR=${LTP_SRCDIR} \
		FMT=${FMT} GCC=${GCC} INSTPFX=${INSTPFX} DASHJ=${DASHJ} BE=${BE} \
		 ./configure --host=i686-redhat-linux ; )
	(cd ${INSTPFX_SRC}; PFX=${PFX} CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" \
		AR=${AR} AS=${AS} CC=${CC} LD=${LD} NM=${NM} OBJCOPY=${OBJCOPY} \
		RANLIB=${RANLIB} STRIP=${STRIP} UCLINUX=${UCLINUX} LTP_SRCDIR=${LTP_SRCDIR} \
		FMT=${FMT} GCC=${GCC} INSTPFX=${INSTPFX} DASHJ=${DASHJ} BE=${BE} make ; )
	#build sandbox
	if [ ! -d ${INSTPFX_SRC}/sandbox ] ; then \
		(cd ${INSTPFX_SRC}; tar -xvjf ${LTP_SRCDIR}/sandbox-src.tar.bz2 ) \
	fi;
	(cd ${INSTPFX_SRC}/sandbox; CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" AR=${AR} CC=${CC} make ;)
	# build testdriver
	if [ ! -d ${INSTPFX_SRC}/testdriver ] ; then \
		(cd ${INSTPFX_SRC}; tar -xvjf ${LTP_SRCDIR}/testdriver-src.tar.bz2; ) \
	fi;
	(cd ${INSTPFX_SRC}/testdriver; make ; cp testdriver ../../)
	make install;
		
clean:
	if [ -d "${INSTPFX}" ]; then \
		echo "Removing old directory" \
		rm -rf "${INSTPFX}" \
	fi \

