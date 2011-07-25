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

TEMPDIR=/tmp/linux-c6x-$(date --iso)
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
    ccs_install_prefix=~/opt/ti
    pushd $scrap_dir
	echo "extracting CCS setup"
	tar xzf $tarball
	echo "running CCS setup"
	./$ccs_setup.bin --mode console <<EOF
${ccs_install_prefix}
EOF
	cd ~/opt/ti/ccsv5/install_scripts/
	sudo ./install_drivers.sh 
    popd
    CCS_DIR=~/opt/ti/ccsv5
}

find_existing_ccs() {
    for base in ~/opt/ti /opt/ti ; do
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
    cgt_install_prefix=~/opt/TI/TI_CGT_C6000_${this_cgt_ver}
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
    for base in $(reverse_words $TOP/TI_CGT_C6000_*) $CCS_DIR/tools/compiler/c6000 $(reverse_words ~/opt/{TI,ti}/TI_CGT_C6000_*) $(reverse_words /opt/{TI,ti}/TI_CGT_C6000_*) ; do
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

install_ipc() {
    if [ "$IPC_VERSION" == "any" ]; then
	ver_spec="*"
    else
	ver_spec=${IPC_VERSION//./_}
    fi

    ipc_setup=$(echo $DOWNLOAD_PATH/ipc_setuplinux_${ver_spec}.bin | awk '{print $NF; exit}')
    if [ ! -r $ipc_setup ]; then
	echo "need IPC version $IPC_VERSION and did not find it nor install file $ipc_setup"
	exit 2
    fi
    this_ipc_ver=$(basename $ipc_setup)
    this_ipc_ver=${this_ipc_ver#ipc_setuplinux_}
    this_ipc_ver=${this_ipc_ver%.bin}
    
    chmod +x $ipc_setup
    IPC_DIR=$TOP/ipc_${this_ipc_ver}
    ipc_install_prefix=$(basename $IPC_DIR)
    expect - <<EOF
spawn ${ipc_setup} --mode console
while true {
expect {
    "Continue?" {send "y\n"} 
    "Press space to continue" {send " "} 
    "Do you accept " {send "y\n"}
    "Is this correct?" {send "y\n"}
    "Is this is correct?" {send "y\n"}
    "Where do you want to install" {send "${ipc_install_prefix}\n"}
    eof {break}
}
}
EOF

    echo "installed and will use IPC version $this_ipv_ver in $IPC_DIR"
}

find_existing_ipc() {
    for base in $(reverse_words $TOP/ipc_*) $(reverse_words {,~}/opt/{TI,ti}{/ccsv5,}/ipc_*) ; do
	if [ -d $base ]; then
	    this_ipc_ver=$(basename $base)
	    this_ipc_ver=${this_ipc_ver#ipc_}
	    if [ "$IPC_VERSION" == "any" ] || [ "${IPC_VERSION//./_}" == "$this_ipc_ver" ]; then
		IPC_DIR=$base
		echo "found IPC version $this_ipc_ver in $IPC_DIR"
		return 0
	    fi
	fi
    done
    return 1
}

find_existing_comp() {
    for base in $(reverse_words $TOP/${COMP_SEARCH}*) $(reverse_words $CCS_DIR/${COMP_SEARCH}*) $(reverse_words {,~}/opt/{TI,ti}{/ccsv5,}/${COMP_SEARCH}*) ; do
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

install_comp() {
    echo "install of $COMP not supported"
    exit 2
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

# get BIOS IPC directory
if [ -n "$IPC_DIR" ]; then
    echo "using predefined TI IPC directory: $IPC_DIR"
elif [ -n "$IPC_VERSION" ] && [ "$IPC_VERSION" != "none" ]; then
    if ! find_existing_ipc; then
	install_ipc
    fi
fi

generic_comp() {
    COMP=$1
    COMP_DIR=$2
    COMP_VERSION=$3
    COMP_SEARCH=$4
    if [ -n "$COMP_DIR" ]; then
        echo "using predefined $COMP directory: $COMP_DIR"
    elif [ -n "$COMP_VERSION" ] && [ "$COMP_VERSION" != "none" ]; then
        if ! find_existing_comp $COMP ; then
	    install_comp $COMP
        fi
    fi
}

generic_comp BIOS 	"$BIOS_DIR"   "$BIOS_VERSION"   bios_
BIOS_DIR=$COMP_DIR
generic_comp XDC	"$XDC_DIR"    "$XDC_VERSION"    xdctools_
XDC_DIR=$COMP_DIR
generic_comp XDAIS	"$XDAIS_DIR"  "$XDAIS_VERSION"  xdais_
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
