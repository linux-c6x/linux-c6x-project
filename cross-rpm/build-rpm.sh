#!/bin/sh

set -x

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

rm -rf $SDK_DIR/rpm
mkdir -p $SDK_DIR/rpm

cp -r cross-rpm $SDK_DIR/rpm/

cd $LINUX_C6X_BUILD_DIR

rm -rf rpm-4.0.4
cat $RPM_SRC_DIR/rpm-4.0.4.tar.gz | tar zxf -
cd rpm-4.0.4

apply_patch $PATCHES

./configure --prefix=$SDK_DIR/rpm/ --enable-shared=no --enable-static=yes --disable-aio --without-python --without-javaglue

make
make install


