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

	BLOB_OUTFILE=${TEMPLATE}${FULL_SUFFIX}${BUILD_SUFFIX}.bin
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
			if [ "$tmp" != '*' ]; then
				BUILD_SUFFIX="$tmp" one_rc_check "$@"
			else
				echo "***** skipping $(basename $TEMPLATE) for ENDIAN=$ENDIAN FLOAT=$FLOAT, no kernel"
				one_rc_check false
			fi
		done
	else
		one_rc_check "$@"
	fi
}


do_one() {
	do_late_defs
	echo "***** Bootblob $(basename $TEMPLATE) for ENDIAN=$ENDIAN FLOAT=$FLOAT BUILD=$BUILD_SUFFIX"
	do_it
}

