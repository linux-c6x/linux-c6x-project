#!/bin/sh
# Author - Murali Karicheri
# WARNING!
# It is assumed that code sourcery delivery follows the current convention
# of file naming. Otherwise this will not work

# tool chain version numbers. Edit this before running this

# Tool chain version
if [ "$1X" = "X" ] ; then
    echo "Usage gcc-install <release>"
    echo "Example  gcc-install 4.5-88"
    exit;
else
    echo "Installing gcc release $1"
fi

GCC_REL=$1;

INSTALL_DIR=$(pwd)

# installation directory for gcc tool chain


# GCC tool chain location
GCC_TOOL_LOCATION=http://gtwmills.gt.design.ti.com/linux-c6x/received/codesourcery

# download temp dir
TEMPDIR=/tmp/gcc-c6x-${GCC_REL}

# point this to the code sourcery tool chain location on local server
TOOL_DIR=c6x-${GCC_REL}-c6x-uclinux
UCLINUX_PREFIX=c6x-${GCC_REL}-c6x-uclinux
UCLINUX_SRC_PKG_TARFILE=${UCLINUX_PREFIX}.src.tar.bz2
TOOLCHAIN_BIN_TARFILE=${UCLINUX_PREFIX}-i686-pc-linux-gnu.tar.bz2
UCLIBC_SRC=uclibc-${GCC_REL}
UCLIBC_SRC_TARFILE=${UCLIBC_SRC}.tar.bz2

echo "Installing gcc tool chain to ${INSTALL_DIR}/c6x-4.5"
echo "Installing uclibc source under ${INSTALL_DIR}/uclibc-ti-c6x"

if [ -d ${INSTALL_DIR}/c6x-4.5 ]; then
	if [ -d ${INSTALL_DIR}/c6x-4.5-old ]; then
		echo removing ${INSTALL_DIR}/c6x-4.5-old
		rm -rf ${INSTALL_DIR}/c6x-4.5-old
	fi
	echo moving old too chain to ${INSTALL_DIR}/c6x-4.5-old
	mv -f ${INSTALL_DIR}/c6x-4.5 ${INSTALL_DIR}/c6x-4.5-old
fi

if [ -d ${INSTALL_DIR}/uclibc-ti-c6x ]; then
	if [ -d ${INSTALL_DIR}/uclibc-ti-c6x-old ]; then
		echo removing ${INSTALL_DIR}/uclibc-ti-c6x-old
		rm -rf ${INSTALL_DIR}/uclibc-ti-c6x-old
	fi
	echo moving old uclibc source to ${INSTALL_DIR}/uclibc-ti-c6x-old
	mv -f ${INSTALL_DIR}/uclibc-ti-c6x ${INSTALL_DIR}/uclibc-ti-c6x-old
fi

mkdir -p ${TEMPDIR}
echo Downloading gcc tool chain binary  ${GCC_TOOL_LOCATION}/${TOOL_DIR}/${TOOLCHAIN_BIN_TARFILE}
wget --directory-prefix=${TEMPDIR}  ${GCC_TOOL_LOCATION}/${TOOL_DIR}/${TOOLCHAIN_BIN_TARFILE}
echo Downloading uclibc source ${GCC_TOOL_LOCATION}/${TOOL_DIR}/${UCLINUX_SRC_PKG_TARFILE}
wget --directory-prefix=${TEMPDIR}  ${GCC_TOOL_LOCATION}/${TOOL_DIR}/${UCLINUX_SRC_PKG_TARFILE}
echo Extracting ${UCLINUX_SRC_PKG_TARFILE}

(cd ${TEMPDIR}; tar -xvjf ${UCLINUX_SRC_PKG_TARFILE})
echo Installing gcc tool chain under ${INSTALL_DIR}
(cd ${INSTALL_DIR}; tar -xvjf ${TEMPDIR}/${TOOLCHAIN_BIN_TARFILE})
echo Installing uclibc source under ${INSTALL_DIR}
(cd ${INSTALL_DIR}; tar -xvjf ${TEMPDIR}/${UCLINUX_PREFIX}/${UCLIBC_SRC_TARFILE})

sleep 2
echo removing the temp files at ${TEMPDIR}
rm -rf ${TEMPDIR}


