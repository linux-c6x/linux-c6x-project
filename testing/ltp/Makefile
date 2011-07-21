# *************     LTP Build top level Makefile ****************************

BUILD_DIR=$(TOP_DIR)/Build
PFX=$(TOP_DIR)/sdk/bin
# directory where LTP source tarball is located, if not CWD.
LTP_TOP=$(TOP_DIR)/projects/ltp
LTP_SRCDIR=$(LTP_TOP)/src

ifeq ($(FLOAT),hard)
ARCHfloat      = -hf
FLOAT_SUFFIX   = _hardfp
FLOAT_CFLAG    = -march=c674x
else
ARCHfloat      =
FLOAT_SUFFIX   =
FLOAT_CFLAG    =
endif

ifeq ($(ENDIAN),big)
ARCHendian     = eb
ENDIAN_SUFFIX  = .eb
ENDIAN_CFLAG   = -mbig-endian
BE             = big
else
ARCHendian     = 
ENDIAN_SUFFIX  = .el
ENDIAN_CFLAG   =
BE             =
endif

INSTPFX=$(BUILD_DIR)/ltp$(ENDIAN_SUFFIX)$(FLOAT_SUFFIX)
INSTPFX_SRC=$(INSTPFX)/ltp-full-20101031

# Use gcc if GCC defined, otherwise assume TI compiler
ifneq ($(GCC),true)
$(error only GCC supported)
endif

# Set to elf or coff.  Only needed with TI compiler
ifneq ($(ABI),elf)
$(error only ELF supported)
endif

# Number of parallel makes to run, use /proc/cpuinfo if undefined
#DASHJ=1

UCLINUX=1
DASHJ=""

CFLAGS = -DCONFIG_COLDFIRE -DHAVE_STRUCT_PTRACE_REGS $(ENDIAN_CFLAG) $(FLOAT_CFLAG)
TARGET=c6x-uclinux
LDFLAGS=$(CFLAGS)

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

