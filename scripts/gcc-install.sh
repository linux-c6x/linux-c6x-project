#!/bin/sh
# Author - Murali Karicheri
# used for installing gcc tool chain to the c6x-project top level
# install tool chain to c6x-4.5-97 under pwd
# install uclibc source to uclibc-ti-c6x under pwd
# edit GCC_TOOL_LOCATION and GCC_TOOL_LOCATION1 for correct path to cs public directory
# currently set to the folder corresponding to release1703
# for installation from ti internal server, no change is needed
# if you are behind a proxy, export http_proxy=<proxy>

gcc_tools_install_help() {
    echo "Usage gcc-install <release> <ti/cs>"
    echo "Example gcc-install 4.5-97 ti - for installing from ti server"
    echo "--------------OR-------------"
    echo "Example gcc-install 4.5-97 cs - for installing from cs public folder"
}

if [ "$1X" = "X" ] ; then
 	gcc_tools_install_help	
    	exit 0;
else
	if [ "$2X" = "csX" ]; then
		echo "Installing gcc release $1 from cs public site"
	else
		if [ "$2X" = "tiX" ]; then
    			echo "Installing gcc release $1 from ti internal server"
		else
			gcc_tools_install_help
			exit 0;
		fi
	fi
fi

GCC_REL=$1;

INSTALL_DIR=$(pwd)

if [ "$2X" = "tiX" ] ; then
GCC_TOOL_LOCATION=http://gtwmills.gt.design.ti.com/linux-c6x/received/codesourcery
else
GCC_TOOL_LOCATION=http://www.codesourcery.com/sgpp/lite/c6000/portal/package8272/c6x-uclinux
GCC_TOOL_LOCATION1=http://www.codesourcery.com/sgpp/lite/c6000/portal/package8271/c6x-uclinux
fi

echo "Downloading from $GCC_TOOL_LOCATION"

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
	echo moving old tool chain to ${INSTALL_DIR}/c6x-4.5-old
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

if [ "$2X" = "csX" ] ; then
echo Downloading gcc tool chain binary  ${GCC_TOOL_LOCATION}/${TOOL_DIR}/${TOOLCHAIN_BIN_TARFILE}
wget --directory-prefix=${TEMPDIR}  ${GCC_TOOL_LOCATION}/${TOOL_DIR}/${TOOLCHAIN_BIN_TARFILE}
echo Downloading uclibc source ${GCC_TOOL_LOCATION1}/${TOOL_DIR}/${UCLINUX_SRC_PKG_TARFILE}
wget --directory-prefix=${TEMPDIR}  ${GCC_TOOL_LOCATION1}/${TOOL_DIR}/${UCLINUX_SRC_PKG_TARFILE}
else
echo Downloading gcc tool chain binary  ${GCC_TOOL_LOCATION}/${TOOL_DIR}/${TOOLCHAIN_BIN_TARFILE}
wget --directory-prefix=${TEMPDIR}  ${GCC_TOOL_LOCATION}/${TOOL_DIR}/${TOOLCHAIN_BIN_TARFILE}
echo Downloading uclibc source ${GCC_TOOL_LOCATION}/${TOOL_DIR}/${UCLINUX_SRC_PKG_TARFILE}
wget --directory-prefix=${TEMPDIR}  ${GCC_TOOL_LOCATION}/${TOOL_DIR}/${UCLINUX_SRC_PKG_TARFILE}
fi

echo Extracting ${UCLINUX_SRC_PKG_TARFILE}

(cd ${TEMPDIR}; tar -xvjf ${UCLINUX_SRC_PKG_TARFILE})
echo Installing gcc tool chain under ${INSTALL_DIR}
(cd ${INSTALL_DIR}; tar -xvjf ${TEMPDIR}/${TOOLCHAIN_BIN_TARFILE})
echo Installing uclibc source under ${INSTALL_DIR}
(cd ${INSTALL_DIR}; tar -xvjf ${TEMPDIR}/${UCLINUX_PREFIX}/${UCLIBC_SRC_TARFILE})
echo removing the temp files at ${TEMPDIR}
rm -rf ${TEMPDIR}

