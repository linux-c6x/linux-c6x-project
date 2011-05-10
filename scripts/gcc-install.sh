#!/bin/sh
# Author - Murali Karicheri
# used for installing gcc tool chain to the c6x-project top level
# install tool chain under $(pwd)/gcc-c6x
# install uclibc source to $(pwd)/gcc-c6x-uclibc 
# if you are behind a proxy, export http_proxy=<proxy> and https_proxy=<proxy>

gcc_tools_install_help() {
    echo "Usage gcc-install <release> <ti/[cs]>"
    echo "Example gcc-install 4.5-109 - for installing specific version from cs public folder"
    echo "Only 4.5-97 or 4.5-109 available in cs public folder"
    echo "--------------OR-------------"
    echo "Example gcc-install 4.5-109 ti - for installing from ti server"
}

validate() {
	if [ "$1X" = "4.5-97X" ]
	then
		GCC_REL=$1
	else
		if [ "$1X" != "4.5-109X" ]
		then
			echo "Only 4.5-97 or 4.5-109 available"
			exit 0;
		fi
	fi
}

SERVER="cs"
GCC_REL="4.5-109"

if [ "$1X" = "X" ]
then
 	gcc_tools_install_help	
    	exit 0;
else
	if [ "$2X" = "csX" ]
	then
		validate $1
		echo "Installing gcc release $1 from cs public site"
	else
		if [ "$2X" = "tiX" ]
		then
    			echo "Installing gcc release $1 from ti internal server"
			SERVER="ti"
			GCC_REL=$1
		else
			if [ "$2X" != "X" ]
			then
				gcc_tools_install_help
				exit 0;
			fi
			validate $1
    			echo "Installing gcc release $1 from cs public site"
		fi
	fi
fi


INSTALL_DIR=$(pwd)

if [ "$SERVER" = "ti" ]
then
GCC_TOOL_LOCATION=http://gtwmills.gt.design.ti.com/linux-c6x/received/codesourcery
else
if [ "$GCC_REL" = "4.5-97" ]
then
# location of old release 4.5-97 commented here
GCC_TOOL_LOCATION=http://www.codesourcery.com/sgpp/lite/c6000/portal/package8272/c6x-uclinux
GCC_TOOL_LOCATION1=http://www.codesourcery.com/sgpp/lite/c6000/portal/package8271/c6x-uclinux
else
GCC_TOOL_LOCATION=https://support.codesourcery.com/GNUToolchain/package8639/c6x-uclinux
GCC_TOOL_LOCATION1=https://support.codesourcery.com/GNUToolchain/package8638/c6x-uclinux
fi
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

echo "Installing gcc tool chain to ${INSTALL_DIR}/gcc-c6x"
echo "Installing uclibc source under ${INSTALL_DIR}/gcc-c6x-uclibc"

if [ -d ${INSTALL_DIR}/gcc-c6x ]; then
	if [ -d ${INSTALL_DIR}/gcc-c6x-old ]; then
		echo removing ${INSTALL_DIR}/gcc-c6x-old
		rm -rf ${INSTALL_DIR}/gcc-c6x-old
	fi
	echo moving old tool chain to ${INSTALL_DIR}/gcc-c6x-old
	mv -f ${INSTALL_DIR}/gcc-c6x ${INSTALL_DIR}/gcc-c6x-old
fi

if [ -d ${INSTALL_DIR}/gcc-c6x-uclibc ]; then
	if [ -d ${INSTALL_DIR}/gcc-c6x-uclibc-old ]; then
		echo removing ${INSTALL_DIR}/gcc-c6x-uclibc-old
		rm -rf ${INSTALL_DIR}/gcc-c6x-uclibc-old
	fi
	echo moving old uclibc source to ${INSTALL_DIR}/gcc-c6x-uclibc-old
	mv -f ${INSTALL_DIR}/gcc-c6x-uclibc ${INSTALL_DIR}/gcc-c6x-uclibc-old
fi

mkdir -p ${TEMPDIR}

if [ "$SERVER" = "cs" ]
then
if [ "$GCC_REL" = "4.5-97" ]
then
# old release 4.5-97
echo Downloading gcc tool chain binary  ${GCC_TOOL_LOCATION}/${TOOL_DIR}/${TOOLCHAIN_BIN_TARFILE}
wget --directory-prefix=${TEMPDIR}  ${GCC_TOOL_LOCATION}/${TOOL_DIR}/${TOOLCHAIN_BIN_TARFILE}
echo Downloading uclibc source ${GCC_TOOL_LOCATION1}/${TOOL_DIR}/${UCLINUX_SRC_PKG_TARFILE}
wget --directory-prefix=${TEMPDIR}  ${GCC_TOOL_LOCATION1}/${TOOL_DIR}/${UCLINUX_SRC_PKG_TARFILE}
else
# 4.5-107
echo Downloading gcc tool chain binary  ${GCC_TOOL_LOCATION}/${TOOLCHAIN_BIN_TARFILE}
wget --directory-prefix=${TEMPDIR} --no-check-certificate ${GCC_TOOL_LOCATION}/${TOOLCHAIN_BIN_TARFILE}
echo Downloading uclibc source ${GCC_TOOL_LOCATION1}/${UCLINUX_SRC_PKG_TARFILE}
wget --directory-prefix=${TEMPDIR} --no-check-certificate ${GCC_TOOL_LOCATION1}/${UCLINUX_SRC_PKG_TARFILE}
fi
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
if [ ! -d ${INSTALL_DIR}/c6x-4.5 ]
then
	echo "Installation of gcc tool chain failed"
else
	echo "Renaming tool chain folder to gcc-c6x"
	mv ${INSTALL_DIR}/c6x-4.5 ${INSTALL_DIR}/gcc-c6x
fi
echo Installing uclibc source under ${INSTALL_DIR}
(cd ${INSTALL_DIR}; tar -xvjf ${TEMPDIR}/${UCLINUX_PREFIX}/${UCLIBC_SRC_TARFILE})
if [ ! -d ${INSTALL_DIR}/uclibc-ti-c6x ]
then
	echo "Installation of gcc uclibc source failed"
else
	echo "Renaming uclibc folder to gcc-c6x-uclibc"
	mv ${INSTALL_DIR}/uclibc-ti-c6x ${INSTALL_DIR}/gcc-c6x-uclibc
fi
echo removing the temp files at ${TEMPDIR}
rm -rf ${TEMPDIR}

