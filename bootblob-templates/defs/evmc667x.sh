# makefile fragment to create a specific bootblob
# is sourced into bootblob and should not be used otherwise

: ${MEM:="mem=256M"}
: ${IP:="ip=dhcp"}
: ${CONSOLE:="console=ttyS0,115200"}
: ${ROOT:="rw"}

MEMORY_START=0x80000000
CPU=C66

if [ -n "$INITRAMFS" ] ; then

BOOTBLOB_DEPENDS=

do_it() {
    ./bootblob make-image \
	--abs-base=${MEMORY_START} --round=0x100000 \
	${BLOB_OUTFILE} \
	${KERNEL_FILE} \
	${INITRAMFS}-${ARCHef}.cpio.gz \
	"${CONSOLE} initrd=0x%fsimage-start-abs-x%,0x%fsimage-size-x% ${ROOT} ${MEM} ${IP} ${EXTRA_CMDLINE_ARGS}"
}

else

BOOTBLOB_DEPENDS=

do_it() {
    cp ${KERNEL_FILE} 	${BLOB_OUTFILE}
    ./bootblob set-cmdline ${BLOB_OUTFILE} \
	"${CONSOLE} ${ROOT} ${MEM} ${IP} ${EXTRA_CMDLINE_ARGS}"
}

fi

