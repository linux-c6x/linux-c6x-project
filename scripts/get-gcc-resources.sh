#! /bin/bash

#set -x
set -e

TOP=$LINUX_C6X_TOP_DIR
PRJ=$TOP/linux-c6x-project

if [ -z "$GCC_VERSION" ] || [ -z "$LINUX_C6X_TOP_DIR" ] ; then
    echo "setenv has not been sourced"
    exit 2
fi

install_gcc() {
	INSTALL_OPT=""
	if $DONT_TOUCH_UCLIBC ; then INSTALL_OPT="--only-gcc" ; fi
	$PRJ/scripts/gcc-install.sh $INSTALL_OPT $GCC_VERSION
}

reverse_words() {
    output=""
    for i in "$@"; do
	output="$i $output"
    done
    echo $output
}

verify_gcc_dir() {
    this_gcc_dir=$1
    if [ -x $this_gcc_dir/bin/c6x-uclinux-gcc ]; then
        THIS_GCC_VERSION=$($this_gcc_dir/bin/c6x-uclinux-gcc --version | grep -o -m 1 -E -e '4\.[0-9]+-[0-9]+')
        if [ -n "$THIS_GCC_VERSION" ] && [ "$GCC_VERSION" == "any" ] || [ "$GCC_VERSION" == "$THIS_GCC_VERSION" ]; then
            return 0
        fi
    fi
    return 1
}

find_existing_gcc() {
    for base in $TOP/opt/gcc-c6x $(reverse_words ~/opt/c6x-*) $(reverse_words /opt/c6x-*) ; do
	if verify_gcc_dir $base ; then
	    GCC_DIR=$base
	    echo "found GCC version $THIS_GCC_VERSION in $GCC_DIR"
	    return 0
	fi
    done
    return 1
}

find_existing_uclibc() {
    # for now we always expect a local copy
    # if it came from a source tar file it will be in $TOP/gcc-c6x-uclibc
    # if it was installed by the setup scripts it will be in $TOP/opt/gcc-c6x-uclibc
    # this is intentional
    for base in $TOP/gcc-c6x-uclibc $TOP/opt/gcc-c6x-uclibc; do
	if [ -d $base/libc ]; then
	    UCLIBC_DIR=$base
	    echo "found uClibc source in $UCLIBC_DIR"
	    return 0
	fi
    done
    return 1
}

# is uclibc from a source tarball?
DONT_TOUCH_UCLIBC=false
if [ -e $TOP/src-release.src-record ] ; then
    DONT_TOUCH_UCLIBC=true
fi

# get GCC directory
if [ -n "$GCC_DIR" ]; then
    if ! GCC_VERSION=any verify_gcc_dir $GCC_DIR ; then
        echo "predefined GCC directory $GCC_DIR does not look valid"
	exit 2
    else
        echo "predefined GCC directory $GCC_DIR containing version $THIS_GCC_VERSION"
    fi
    if ! find_existing_uclibc ; then
	echo "Can't find/verify uClibc source directory"
	exit 2
    fi
elif [ "$GCC_VERSION" != "none" ]; then
    # try to find preinstalled version of CCS
    if ! find_existing_gcc || ! find_existing_uclibc ; then
	install_gcc
	if ! find_existing_gcc ; then
	    echo "Can't find usable GCC even after installing"
	    exit 2
	fi
	if ! find_existing_uclibc ; then
	    echo "Can't find usable uClibc even after installing"
	    exit 2
	fi
    fi
fi

cat - >>$PRJ/.setenv.local <<EOF
export GCC_DIR="$GCC_DIR"
export UCLIBC_DIR="$UCLIBC_DIR"
EOF
