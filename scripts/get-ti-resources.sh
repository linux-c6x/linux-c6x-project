#! /bin/bash

#set -x
set -e 

TOP=$LINUX_C6X_TOP_DIR
PRJ=$TOP/linux-c6x-project

if [ -z "$CCS_VERSION" ]   || [ -z "$CGT_LINUX_VERSION" ] || [ -z "$CGT_BIOS_VERSION" ] || 
   [ -z "$IPC_VERSION" ]   || [ -z "$BIOS_VERSION" ]      || [ -z "$XDC_VERSION" ]      || 
   [ -z "$XDAIS_VERSION" ] || [ -z "$DOWNLOAD_PATH" ]     ; then
    echo "setenv has not been sourced or does not defined the needed vars for $0"
    exit 2
fi

TEMPDIR=/tmp/linux-c6x-install-$(date --iso)
rm -rf ${TEMPDIR} || true
mkdir -p ${TEMPDIR}

install_ccs() {
    if [ "$CCS_VERSION" == "any" ]; then
	ver_spec="*"
    else
	ver_spec=$CCS_VERSION
    fi

    tarball=$(echo $DOWNLOAD_PATH/setup_CCS_$ver_spec.tar.gz | awk '{print $NF; exit}')
    if [ ! -r $tarball ]; then
	echo "need CCS version $CCS_VERSION and did not find it nor install file $tarball"
	exit 2
    fi
    ccs_setup=$(basename $tarball)
    ccs_setup=${ccs_setup%.tar.gz}
    scrap_dir=$TEMPDIR/${ccs_setup}

    rm -rf $scrap_dir
    mkdir -p $scrap_dir
    ccs_install_prefix=$TOP/opt/
    pushd $scrap_dir
	echo "extracting CCS setup"
	tar xzf $tarball
	echo "running CCS setup"
	./$ccs_setup.bin --mode console <<EOF
${ccs_install_prefix}
EOF
	if [ "$AUTO_INSTALL" == "yes" ] ; then 
		cd ~/opt/ti/ccsv5/install_scripts/
		sudo ./install_drivers.sh 
	fi
    popd
    CCS_DIR=$ccs_install_prefix/ccsv5
}

find_existing_ccs() {
    for base in $TOP/opt ~/opt/ti /opt/ti ; do
	if [ -d $base/ccsv5 ]; then
	    this_ccs_base=$(basename $(echo $base/ccsv5/ccs_base*))
	    this_ccs_ver=${this_ccs_base#ccs_base_}
	    if [ "$CCS_VERSION" == "any" ] || [ "$CCS_VERSION" == "$this_ccs_ver" ]; then
		CCS_DIR=$base/ccsv5
		echo "found CCS version $this_ccs_ver in $CCS_DIR"
		return 0
	    fi
	fi
    done
    return 1
}

reverse_words() {
    output=""
    for i in "$@"; do
	output="$i $output"
    done
    echo $output
}

install_cgt() {
    if [ "$CGT_VERSION" == "any" ]; then
	ver_spec="*"
    else
	ver_spec=$CGT_VERSION
    fi

    cgt_setup=$(echo $DOWNLOAD_PATH/ti_cgt_c6000_${ver_spec}_setup_linux_x86.bin | awk '{print $NF; exit}')
    if [ ! -r $cgt_setup ]; then
	echo "need CGT version $CGT_VERSION and did not find it nor install file $cgt_setup"
	exit 2
    fi
    this_cgt_ver=$(basename $cgt_setup)
    this_cgt_ver=${this_cgt_ver#ti_cgt_c6000_}
    this_cgt_ver=${this_cgt_ver%_setup_linux_x86.bin}
    
    chmod +x $cgt_setup
    cgt_install_prefix=$TOP/opt/TI_CGT_C6000_${this_cgt_ver}
    expect - <<EOF
spawn ${cgt_setup} --mode console
while true {
expect {
    "Continue?" {send "y\n"} 
    "Press space to continue" {send " "} 
    "Do you accept " {send "y\n"}
    "Where do you want to install" {send "${cgt_install_prefix}\n"}
    eof {break}
}
}
EOF

    CGT_DIR=$cgt_install_prefix
    echo "installed and will use CGT version $this_cgt_ver in $CGT_DIR"
}

find_existing_cgt() {
    for base in $(reverse_words $TOP/opt/TI_CGT_C6000_*) $CCS_DIR/tools/compiler/c6000 $(reverse_words ~/opt/{TI,ti}/TI_CGT_C6000_*) $(reverse_words /opt/{TI,ti}/TI_CGT_C6000_*) ; do
	if [ -x $base/bin/cl6x ]; then
	    this_cgt_ver=$($base/bin/cl6x --tool_version | awk '{ print $NF; exit }')
	    this_cgt_ver=${this_cgt_ver#v}
	    if [ "$CGT_VERSION" == "any" ] || [ "$CGT_VERSION" == "$this_cgt_ver" ]; then
		CGT_DIR=$base
		echo "found CGT version $this_cgt_ver in $CGT_DIR"
		return 0
	    fi
	fi
    done
    return 1
}

install_comp() {
    if [ "$COMP_VERSION" == "any" ]; then
	ver_spec="*"
    else
	ver_spec=${COMP_VERSION//./_}
    fi

    comp_setup=$(echo $DOWNLOAD_PATH/${COMP_SETUP_PREFIX}${ver_spec}${COMP_SETUP_SUFFIX} | awk '{print $NF; exit}')
    if [ ! -r $comp_setup ]; then
	echo "need $COMP version $COMP_VERSION and did not find it nor install file $comp_setup"
	exit 2
    fi
    this_comp_ver=$(basename $comp_setup)
    this_comp_ver=${this_comp_ver#${COMP_SETUP_PREFIX}}
    this_comp_ver=${this_comp_ver%${COMP_SETUP_SUFFIX}}
    
    chmod +x $comp_setup
    COMP_DIR=$TOP/opt/${COMP_DIR_PREFIX}${this_comp_ver}
    comp_install_prefix=$(dirname $COMP_DIR)
    expect - <<EOF
spawn ${comp_setup} --mode console
while true {
expect {
    "Continue?" {send "y\n"} 
    "Press space to continue" {send " "} 
    "Do you accept " {send "y\n"}
    "Is this correct?" {send "y\n"}
    "Is this is correct?" {send "y\n"}
    "Please type \"Y\" to agree and continue:" {send "y\n"}
    "Where do you want to install" {send "${comp_install_prefix}\n"}
    eof {break}
}
}
EOF

    echo "installed and will use $COMP version $this_comp_ver in $COMP_DIR"
}

find_existing_comp() {
    for base in $(reverse_words $TOP/opt/${COMP_SEARCH}*) $(reverse_words $CCS_DIR/${COMP_SEARCH}*) $(reverse_words {,~}/opt/{TI,ti}{/ccsv5,}/${COMP_SEARCH}*) ; do
	if [ -d $base ]; then
	    this_comp_ver=$(basename $base)
	    this_comp_ver=${this_comp_ver#$COMP_SEARCH}
	    if [ "$COMP_VERSION" == "any" ] || [ "${COMP_VERSION//./_}" == "$this_comp_ver" ]; then
		COMP_DIR=$base
		echo "found $COMP version $this_comp_ver in $COMP_DIR"
		return 0
	    fi
	fi
    done
    return 1
}

# get CCS directory
if [ -n "$CCS_DIR" ]; then
    echo "using predefined CCS directory: $CCS_DIR"
elif [ "$CCS_VERSION" != "none" ]; then
    # try to find preinstalled version of CCS
    if ! find_existing_ccs; then
	install_ccs
    fi
fi

# get TI CGT directory for LINUX
if [ -n "$CGT_LINUX_DIR" ]; then
    echo "using predefined TI CGT directory $CGT_LINUX_DIR for Linux programs"
elif [ -n "$CGT_LINUX_VERSION" ] && [ "$CGT_LINUX_VERSION" != "none" ]; then
    CGT_VERSION=$CGT_LINUX_VERSION
    echo -n "CGT for Linux: "
    if ! find_existing_cgt; then
	install_cgt
    fi
    CGT_LINUX_DIR=$CGT_DIR
fi

# get TI CGT directory for BIOS
if [ -n "$CGT_BIOS_DIR" ]; then
    echo "using predefined TI CGT directory $CGT_BIOS_DIR for BIOS programs"
elif [ -n "$CGT_BIOS_VERSION" ] && [ "$CGT_BIOS_VERSION" != "none" ]; then
    CGT_VERSION=$CGT_BIOS_VERSION
    echo -n "CGT for BIOS:  "
    if ! find_existing_cgt; then
	install_cgt
    fi
    CGT_BIOS_DIR=$CGT_DIR
fi

generic_comp() {
    COMP=$1
    COMP_DIR=$2
    COMP_VERSION=$3
    COMP_SEARCH=$4
    COMP_SETUP_PREFIX=$5
    COMP_SETUP_SUFFIX=$6
    COMP_DIR_PREFIX=$4
    if [ -n "$COMP_DIR" ]; then
        echo "using predefined $COMP directory: $COMP_DIR"
    elif [ -n "$COMP_VERSION" ] && [ "$COMP_VERSION" != "none" ]; then
        if ! find_existing_comp $COMP ; then
	    install_comp $COMP
        fi
    fi
}

# get TI SYSBIOS components
generic_comp IPC 	"$IPC_DIR"    "$IPC_VERSION"    ipc_		ipc_setuplinux_		.bin
IPC_DIR=$COMP_DIR
generic_comp BIOS 	"$BIOS_DIR"   "$BIOS_VERSION"   bios_		bios_setuplinux_	.bin
BIOS_DIR=$COMP_DIR
generic_comp XDC	"$XDC_DIR"    "$XDC_VERSION"    xdctools_	xdctools_setuplinux_	.bin
XDC_DIR=$COMP_DIR
generic_comp XDAIS	"$XDAIS_DIR"  "$XDAIS_VERSION"  xdais_		xdias_setuplinux_	.bin
XDAIS_DIR=$COMP_DIR

cat - >>$PRJ/.setenv.local <<EOF
export CCS_DIR="$CCS_DIR"
export CGT_LINUX_DIR="$CGT_LINUX_DIR"
export CGT_BIOS_DIR="$CGT_BIOS_DIR"
export IPC_DIR="$IPC_DIR"
export BIOS_DIR="$BIOS_DIR"
export XDC_DIR="$XDC_DIR"
export XDAIS_DIR="$XDAIS_DIR"
EOF
