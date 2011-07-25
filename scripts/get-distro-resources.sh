#! /bin/bash

#set -x

distro-check() {
    DISTRO_ID=$(lsb_release --id | awk '{ print $NR; exit }')
    if [ "$DISTRO_ID" == "$1" ] ; then 
        return 0
    else 
        return 1
    fi
}

if ! which lsb_release >/dev/null || ! which awk >/dev/null || distro-check Ubuntu || distro-check Debian ; then
    echo "This distribution is not setup for auto setup, doing basic checks ..."
    PROGRAMS="make gcc git awk perl wget"
    RC=0
    for pgm in $PROGRAMS; do
        if ! which $pgm >/dev/null; then
            echo "$pgm not found"
            RC=1
        fi
    done
    exit $RC
fi

# set up machine debian based machine
# (we only need expect for the CGT installer)
PACKAGES="build-essential git-core expect"
if ! dpkg -L $PACKAGES 2>&1 >/dev/null; then
    if [ x"$AUTO_INSTALL" == x"yes" ] ; then
	echo "installing (at least one of) the following packages: $PACKAGES"
        sudo apt-get install -y $PACKAGES
    else
        echo "needed packages missing and AUTO_INSTALL != yes"
        exit 1
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
