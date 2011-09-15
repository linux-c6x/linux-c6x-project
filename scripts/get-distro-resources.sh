#! /bin/bash

#set -x
set -e

distro-check() {
    DISTRO_ID=$(lsb_release --id | awk '{ print $NF; exit }')
    echo "distro == $DISTRO_ID"
    for test_distro in "$@" ; do
	if [ "$DISTRO_ID" == "$test_distro" ] ; then 
		return 0
	fi
    done
    return 1
}

if ! which lsb_release >/dev/null || ! which awk >/dev/null || ! distro-check Ubuntu Debian ; then
    echo "This distribution is not setup for auto setup, doing basic checks ..."
    PROGRAMS="make gcc git awk perl wget autoheader automake expect bison flex mkfs.jffs2 mkisofs"
    RC=0
    for pgm in $PROGRAMS; do
        if ! which $pgm >/dev/null; then
            echo "$pgm not found"
            RC=1
        fi
    done

    # if DISTRO_CHECK_WARN is defined, this becomes non-fatal
    if [ -z "$DISTRO_CHECK_WARN" ]; then 
	exit $RC
    fi
fi

# set up debian based machine
# (we only need expect for the TI installers)
PACKAGES="build-essential git-core expect automake zlib1g-dev bison flex mtd-utils fakeroot genisoimage"
if ! dpkg -L $PACKAGES 2>&1 >/dev/null; then
    if [ x"$AUTO_INSTALL" == x"yes" ] ; then
	echo "installing (at least one of) the following packages: $PACKAGES"
        sudo apt-get install -y $PACKAGES
    else
        echo "needed packages missing and AUTO_INSTALL != yes"
	if [ -z "$DISTRO_CHECK_WARN" ]; then 
	    exit 1
	else
	    echo "DISTRO_CHECK_WARN enabled, continuing anyway ..."
	fi
    fi
else
    echo "all following packages already installed: $PACKAGES"
fi

# need /bin/sh to be dash
if ! /bin/sh --version 2>&1 | grep bash >/dev/null; then
    if [ x"$AUTO_INSTALL" == x"yes" ] ; then
	echo "reconfiguring /bin/sh to be bash"
        echo "no" | sudo dpkg-reconfigure -f teletype dash
    else
        echo "/bin/sh is not bash and AUTO_INSTALL != yes"
        exit 1
    fi
else
    echo "/bin/sh looks like bash"
fi
