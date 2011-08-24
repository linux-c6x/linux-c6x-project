# shell fragment for building bootblob templates
# this file is sourced by the bootblob command and should not be executed directly

if $VERBOSE; then
	set -x
fi

if [ -z "$ENDIAN" ]; then
	ENDIAN=both
	BEST_EFFORT=true
fi

if [ -z "$FLOAT" ]; then
	FLOAT=native
	BEST_EFFORT=true
fi

if [ -z "$BUILD_SUFFIX" ] ; then
	if [ -n "$BUILD_NAME" ]; then
		BUILD_SUFFIX="-$BUILD_NAME"
	else
		BEST_EFFORT=true
	fi
fi

do_late_defs() {
	if [ "$ENDIAN"x == "little"x ]; then
		ENDIAN_TAG=el
	elif [ "$ENDIAN"x == "big"x ]; then
		ENDIAN_TAG=eb
	fi

	if [ "$FLOAT"x == "hard"x ]; then
		FLOAT_SUFFIX="-hf"
	else
		FLOAT_SUFFIX=""
	fi

	if [ "$CPU"x == "C64P"x ]; then
		NATIVE_FLOAT="soft"
		POSSIBLE_FLOATS="soft"
	elif [ "$CPU"x == "C66"x ]; then
		NATIVE_FLOAT="hard"
		POSSIBLE_FLOATS="soft hard"
	else
		echo "unknown CPU ($CPU) in template $TEMPLATE"
		exit 2
	fi

	ENDIAN_SUFFIX=.$ENDIAN_TAG
	FULL_TAG=$ENDIAN_TAG$FLOAT_SUFFIX
	FULL_SUFFIX=".$FULL_TAG"
	ARCHef="c6x$FULL_TAG"

	KERNEL_PATTERN_START="vmlinux-2.6.34-${EVM}${ENDIAN_SUFFIX}"
	KERNEL_PATTERN_END=".bin"
	KERNEL_FILE="${KERNEL_PATTERN_START}${BUILD_SUFFIX}${KERNEL_PATTERN_END}"
	BASEFS_FILE="${BASEFS}-${ARCHef}.cpio.gz"
	MODULES_FILE="modules-2.6.34-${EVM}${ENDIAN_SUFFIX}${BUILD_SUFFIX}.tar.gz"
	TEST_MODULES_FILE="test-modules-2.6.34-${EVM}${ENDIAN_SUFFIX}${BUILD_SUFFIX}.tar.gz"
	SYSLINK_FILE="syslink-${SYSLINK_TYPE}-${EVM}${FULL_SUFFIX}${BUILD_SUFFIX}.tar.gz"
	DEVTOOLS_FILE="gplv3-devtools-${ARCHef}.cpio.gz"

	BLOB_OUTFILE=${TEMPLATE}${FULL_SUFFIX}${BUILD_SUFFIX}.bin
	FS_OUTFILE=${TEMPLATE}${FULL_SUFFIX}${BUILD_SUFFIX}

	: ${IPADDR:=$(eval echo \$${EVM}_IPADDR)}
	: ${IPADDR:=dhcp}
	: ${IP:="ip=${IPADDR}"}
	: ${NFS_PREFIX:="/srv/nfs/"}
}

do_for_each() {
	do_late_defs
	if [ "$ENDIAN" == "both" ]; then
		ENDIAN=little do_for_each_float "$@"
		ENDIAN=big    do_for_each_float "$@"
	else
		do_for_each_float "$@"
	fi
}

do_for_each_float() {
	if [ "$FLOAT" == "both" ]; then
		for float in $POSSIBLE_FLOAT; do
			FLOAT=$float  do_for_each_build "$@"
		done
	elif [ "$FLOAT" == "native" ]; then
		FLOAT=$NATIVE_FLOAT  do_for_each_build "$@"
	else
		do_for_each_build "$@"
	fi
}

do_for_each_build() {
	do_late_defs
	if [ -z "$BUILD_SUFFIX" ]; then
		for kernel in ${KERNEL_PATTERN_START}*${KERNEL_PATTERN_END}; do
			tmp=${kernel##$KERNEL_PATTERN_START}
			tmp=${tmp%%$KERNEL_PATTERN_END}
			BUILD_SUFFIX="$tmp" one_rc_check "$@"
		done
	else
		one_rc_check "$@"
	fi
}


do_one() {
	do_late_defs
	if [ ! -r $KERNEL_FILE ]; then
		echo "***** skipping $(basename $TEMPLATE) for ENDIAN=$ENDIAN FLOAT=$FLOAT BUILD=$BUILD_SUFFIX, no kernel"
		one_rc_check false
		return
	fi

	if [ ! -r $BASEFS_FILE ]; then
		echo "***** skipping $(basename $TEMPLATE) for ENDIAN=$ENDIAN FLOAT=$FLOAT BUILD=$BUILD_SUFFIX, no base filesystem"
		one_rc_check false
		return
	fi

	echo "***** Bootblob $(basename $TEMPLATE) for ENDIAN=$ENDIAN FLOAT=$FLOAT BUILD=$BUILD_SUFFIX"
	do_it
}

calculate_depends() {
	BOOTBLOB_DEPENDS=""
}

do_it() {
	FS_PREFIX=""
	FS_OPTS=""
	case $FSTYPE in 
	NFS)
		ROOT="root=/dev/nfs nfsroot=${NFS_SERVER}${NFS_PREFIX%/}/${FS_OUTFILE}/,v3,tcp rw"
		if [ -n "$NFS_PREFIX_DIR" ] ; then
			FS_EXT=""
			FS_PREFIX=${NFS_PREFIX_DIR%/}/
		else
			FS_EXT=".cpio.gz"
		fi
		;;
	INITRAMFS)
		ROOT="rw"
		FS_EXT=.cpio.gz
		;;
	JFFS2)
		ROOT="root=${JFFS2_DEV} rootfstype=jffs2 rw"
		FS_EXT=".jffs2"
		FS_OPTS=$JFFS2_OPT
		;;
	*)
		echo "Unknown FSTYPE=$FSTYPE"
		return 1
	esac

	if [ $ENDIAN == "big" ] ; then
		FS_OPTS="$FS_OPTS --big-endian"
	else
		FS_OPTS="$FS_OPTS --little-endian"
	fi

	if [ ! -r "$MODULES_FILE" ]; then
		echo "skipping non-existant file $MODULES_FILE"
		MODULES_FILE=""
	fi

	if [ -z "$SYSLINK_TYPE" ]; then SYSLINK_FILE=""; fi
	if [ -n "$SYSLINK_FILE" ] && [ ! -r "$SYSLINK_FILE" ]; then
		echo "skipping non-existant file $SYSLINK_FILE"
		SYSLINK_FILE=""
	fi

	if [ "$TEST_MODULES"x != "yes"x ]; then TEST_MODULES_FILE=""; fi
	if [ -n "$TEST_MODULES_FILE" ] && [ ! -r "$TEST_MODULES_FILE" ]; then
		echo "skipping non-existant file $TEST_MODULES_FILE"
		TEST_MODULES_FILE=""
	fi

	if [ "$GPLV3OK"x != "yes"x ]; then DEVTOOLS_FILE=""; fi
	if [ -n "$DEVTOOLS_FILE" ] && [ ! -r "$DEVTOOLS_FILE" ]; then
		echo "skipping non-existant file $DEVTOOLS_FILE"
		DEVTOOLS_FILE=""
	fi

	MAKE_FILESYSTEM_CMD="./make-filesystem ${FS_OPTS} ${FS_PREFIX}${FS_OUTFILE}${FS_EXT} ${BASEFS}-${ARCHef}.cpio.gz ${TEST_MODULES_FILE} ${MODULES_FILE} ${SYSLINK_FILE} ${DEVTOOLS_FILE} ${EXTRA_FS_PARTS}"
	echo $MAKE_FILESYSTEM_CMD
	if ! $MAKE_FILESYSTEM_CMD ; then
		return 2
	fi

	CMDLINE="${CONSOLE} ${ROOT} ${MEM} ${IP} ${EXTRA_CMDLINE_ARGS}"

	if [ $FSTYPE == INITRAMFS ]; then
		BOOTBLOB_CMD_PART1="./bootblob make-image --abs-base=${MEMORY_START} --round=0x100000 ${BLOB_OUTFILE} ${KERNEL_FILE} ${FS_OUTFILE}${FS_EXT}"
		CMDLINE="${CMDLINE} initrd=0x%fsimage-start-abs-x%,0x%fsimage-size-x%"

		echo $BOOTBLOB_CMD_PART1 \"$CMDLINE\" >&2
		$BOOTBLOB_CMD_PART1 "${CMDLINE}"
	else
		echo cp ${KERNEL_FILE} ${BLOB_OUTFILE}
		cp ${KERNEL_FILE} ${BLOB_OUTFILE}
		echo ./bootblob set-cmdline ${BLOB_OUTFILE} \"${CMDLINE}\"
		./bootblob set-cmdline ${BLOB_OUTFILE} "${CMDLINE}"
	fi
}
