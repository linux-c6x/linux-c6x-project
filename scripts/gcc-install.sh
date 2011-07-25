#!/bin/bash
# Author - Murali Karicheri
# used for installing gcc tool chain to the c6x-project top level
# install tool chain under $(pwd)/gcc-c6x
# install uclibc source to $(pwd)/gcc-c6x-uclibc 
# if you are behind a proxy, export http_proxy=<proxy> and https_proxy=<proxy>

PUBLIC_VERSIONS="4.5-123 4.5-109 4.5-97"
DEFAULT_VERSION="4.5-123"

gcc_tools_install_help() {
    echo "Usage gcc-install [options] <release> <ti/[cs]>"
    echo "options are zero or more of --help, --only-gcc, & --only-uclibc"
    echo "Example gcc-install $DEFAULT_VERSION - for installing specific version from cs public folder"
    echo "Only $PUBLIC_VERSIONS are available in cs public folder"
    echo "--------------OR-------------"
    echo "Example gcc-install $DEFAULT_VERSION ti - for installing from ti internal server"
}

SERVER="cs"
GCC_REL="4.5-123"
DO_BIN=true
DO_SRC=true

# process options
while true; do
case $1 in
--help)
 	gcc_tools_install_help	
    	exit 0
;;
--only-gcc)
	DO_SRC=false
	shift
;;
--only-uclibc)
	DO_BIN=false
	shift
;;
--*)
	echo "unknown option $1"
	echo "use --help for command usage"
	exit 2
;;
*)
	break
;;
esac
done

if [ -z "$LINUX_C6X_TOP_DIR" ]; then
	INSTALL_DIR=$(pwd)
	echo "warning: setenv not in effect, installing to $INSTALL_DIR"
else
	INSTALL_DIR=$LINUX_C6X_TOP_DIR
fi

if [ "$1"x != ""x ]
then
	GCC_REL=$1
fi

if [ "$2"x != ""x ]
then
	SERVER=$2
fi

# common definitions to be used or overridden below
TOOL_DIR=c6x-${GCC_REL}-c6x-uclinux
UCLINUX_PREFIX=c6x-${GCC_REL}-c6x-uclinux
TOOLCHAIN_SRC_TARFILE=${UCLINUX_PREFIX}.src.tar.bz2
TOOLCHAIN_BIN_TARFILE=${UCLINUX_PREFIX}-i686-pc-linux-gnu.tar.bz2
UCLIBC_SRC=uclibc-${GCC_REL}
UCLIBC_SRC_TARFILE=${UCLIBC_SRC}.tar.bz2

OLD_CS_BASE=http://www.codesourcery.com/sgpp/lite/c6000/portal
NEW_CS_BASE=https://support.codesourcery.com/GNUToolchain/
TI_INTERNAL_BASE=http://gtgit01.gt.design.ti.com/files/linux-c6x/received/codesourcery

BIN_DIR_NAME=c6x-4.5
UCLIBC_DIR_NAME=uclibc-ti-c6x

case $GCC_REL in 
4.5-97)
	BIN_URL=$OLD_CS_BASE/package8272/c6x-uclinux/${TOOL_DIR}/${TOOLCHAIN_BIN_TARFILE}
	SRC_URL=$OLD_CS_BASE/package8271/c6x-uclinux/${TOOL_DIR}/${TOOLCHAIN_SRC_TARFILE}
;;
4.5-109)
	BIN_URL=$NEW_CS_BASE/package8639/c6x-uclinux/${TOOLCHAIN_BIN_TARFILE}
	SRC_URL=$NEW_CS_BASE/package8638/c6x-uclinux/${TOOLCHAIN_SRC_TARFILE}
;;
4.5-123)
	BIN_URL=$NEW_CS_BASE/package9077/c6x-uclinux/${TOOLCHAIN_BIN_TARFILE}
	SRC_URL=$NEW_CS_BASE/package9076/c6x-uclinux/${TOOLCHAIN_SRC_TARFILE}
;;
4.5-*)
;;
*)
	# other version will probibly need adjustments to BIN_DIR_NAME at least
	echo "GCC version $GCC_REL not handled"
	echo "use --help for command usage"
	exit 2
;;
esac

case $SERVER in
cs)
	SERVER_DESC="cs public site"
;;
ti)
	SERVER_DESC="ti internal site"
	BIN_URL=$TI_INTERNAL_BASE/${TOOL_DIR}/${TOOLCHAIN_BIN_TARFILE}
	SRC_URL=$TI_INTERNAL_BASE/${TOOL_DIR}/${TOOLCHAIN_SRC_TARFILE}
;;
*)
	echo "unknown site specifier $SERVER"
	echo "use --help for command usage"
	exit 2
;;
esac

if [ -z "$BIN_URL" ] || [ -z "$SRC_URL" ] ; then
	echo "$GCC_REL is not a publicly available version"
	echo "Only $PUBLIC_VERSION are available"
	exit 2;
fi

# download & temp dir
: ${DOWNLOAD_PATH=$INSTALL_PATH/downloads}"
: ${DOWNLOAD_DIR=$DOWNLOAD_PATH}"
TEMPDIR=/tmp/gcc-c6x-${GCC_REL}

echo "Installing gcc release $GCC_REL from $SERVER_DESC site";
if $DO_BIN; then echo "Installing gcc tool chain to ${INSTALL_DIR}/gcc-c6x"; fi
if $DO_SRC; then echo "Installing uclibc source under ${INSTALL_DIR}/gcc-c6x-uclibc"; fi

# create and/or start clean
rm -rf ${TEMPDIR}
mkdir -p ${TEMPDIR}

if $DO_BIN; then

if [ ! -r ${DOWNLOAD_DIR}/${TOOLCHAIN_BIN_TARFILE} ] ; then
	if [ -z "$BIN_URL" ] ; then
		echo "$GCC_REL is not a publicly available version"
		echo "Only $PUBLIC_VERSION are available"
		exit 2;
	fi

	echo Downloading gcc tool chain binary  ${BIN_URL}
	wget --directory-prefix=${TEMPDIR} --no-check-certificate ${BIN_URL} || exit 2
	mv ${TEMPDIR}/${TOOLCHAIN_BIN_TARFILE} ${DOWNLOAD_DIR}/${TOOLCHAIN_BIN_TARFILE}
fi

if [ -d ${INSTALL_DIR}/gcc-c6x ]; then
	if [ -d ${INSTALL_DIR}/gcc-c6x-old ]; then
		echo removing ${INSTALL_DIR}/gcc-c6x-old
		rm -rf ${INSTALL_DIR}/gcc-c6x-old
	fi
	echo moving old tool chain to ${INSTALL_DIR}/gcc-c6x-old
	mv -f ${INSTALL_DIR}/gcc-c6x ${INSTALL_DIR}/gcc-c6x-old
fi

echo Installing gcc tool chain under ${INSTALL_DIR}
(cd ${INSTALL_DIR}; tar -xjf ${DOWNLOAD_DIR}/${TOOLCHAIN_BIN_TARFILE})
if [ ! -d ${INSTALL_DIR}/${BIN_DIR_NAME} ]
then
	echo "Installation of gcc tool chain failed"
	exit 2
else
	echo "Renaming tool chain folder to gcc-c6x"
	mv ${INSTALL_DIR}/${BIN_DIR_NAME} ${INSTALL_DIR}/gcc-c6x
fi

fi # end DO_BIN

if $DO_SRC; then

if [ ! -r ${DOWNLOAD_DIR}/${TOOLCHAIN_SRC_TARFILE} ] ; then
	if [ -z "$SRC_URL" ] ; then
		echo "$GCC_REL is not a publicly available version"
		echo "Only $PUBLIC_VERSION are available"
		exit 2;
	fi

	echo Downloading toolchain source ${SRC_URL}
	wget --directory-prefix=${TEMPDIR} --no-check-certificate ${SRC_URL} || exit 2
	mv ${TEMPDIR}/${TOOLCHAIN_SRC_TARFILE} ${DOWNLOAD_DIR}/${TOOLCHAIN_SRC_TARFILE}
fi

echo Extracting ${TOOLCHAIN_SRC_TARFILE}
(cd ${TEMPDIR}; tar -xjf ${DOWNLOAD_DIR}/${TOOLCHAIN_SRC_TARFILE})

if [ -d ${INSTALL_DIR}/gcc-c6x-uclibc ]; then
	if [ -d ${INSTALL_DIR}/gcc-c6x-uclibc-old ]; then
		echo removing ${INSTALL_DIR}/gcc-c6x-uclibc-old
		rm -rf ${INSTALL_DIR}/gcc-c6x-uclibc-old
	fi
	echo moving old uclibc source to ${INSTALL_DIR}/gcc-c6x-uclibc-old
	mv -f ${INSTALL_DIR}/gcc-c6x-uclibc ${INSTALL_DIR}/gcc-c6x-uclibc-old
fi

echo Installing uclibc source under ${INSTALL_DIR}
(cd ${INSTALL_DIR}; tar -xjf ${TEMPDIR}/${UCLINUX_PREFIX}/${UCLIBC_SRC_TARFILE})
if [ ! -d ${INSTALL_DIR}/${UCLIBC_DIR_NAME} ]
then
	echo "Installation of gcc uclibc source failed"
	exit 2
else
	echo "Renaming uclibc folder to gcc-c6x-uclibc"
	mv ${INSTALL_DIR}/${UCLIBC_DIR_NAME} ${INSTALL_DIR}/gcc-c6x-uclibc
fi

fi # end DO_SRC

echo removing the temp files at ${TEMPDIR}
rm -rf ${TEMPDIR}
