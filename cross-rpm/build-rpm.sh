#!/bin/sh

set -x
set -e

apply_patch () {
    for i in `echo $1/*.gz `; do
	if [ -f $i ]; then
	    gunzip < $i | patch -p1
	fi 
    done

    for i in `echo $1/*.patch `; do
	if [ -f $i ]; then
	    patch -p1 < $i
	fi
    done
}

# Where RPM patches and tarball are stored
PATCHES=$LINUX_C6X_TOP_DIR/projects/packages/rpm-4.0.4/patches/
RPM_SRC_DIR=$LINUX_C6X_TOP_DIR/projects/package-downloads/
RPM_FILE=$RPM_SRC_DIR/rpm-4.0.4.tar.gz

if [ ! -r $RPM_FILE ] ; then
    echo "$RPM_FILE not found"
    exit 2
fi
if [ ! -d $PATCHES ] ; then
    echo "Patch directory $PATCHES not found"
    exit 2
fi

mkdir -p $LINUX_C6X_BUILD_DIR
pushd $LINUX_C6X_BUILD_DIR

rm -rf rpm-4.0.4
cat $RPM_FILE | tar zxf -
cd rpm-4.0.4

apply_patch $PATCHES

./configure --prefix=$SDK_DIR/rpm/ --enable-shared=no --enable-static=yes --disable-aio --without-python --without-javaglue

make

rm -rf $SDK_DIR/rpm || true
mkdir -p $SDK_DIR/rpm

make install

popd
cp -r cross-rpm $SDK_DIR/rpm/

echo "Build RPM complete" >$LINUX_C6X_BUILD_DIR/rpm-done.txt
