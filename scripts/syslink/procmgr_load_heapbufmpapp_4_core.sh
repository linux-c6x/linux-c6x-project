#!/bin/sh
if [ "$1X" = "X" ]
then
        LOADER=/usr/bin/mcoreloader
else
        LOADER=$1
fi
CORES="1 2 3"
echo "Beginning of HeapBufMP kernel test module run"
echo "insmod syslink.ko"
insmod syslink.ko

for i in $CORES
do
echo "Loading and running slave core $i"
${LOADER} $i heapbufmp_c6670_core${i}.xe66
done
echo "Running procmgr User land sample application"
./procmgrapp_debug 3 1 0x817180 2 0x817180 3 0x817180 3
echo "rmmod syslink.ko"
rmmod syslink.ko
echo "HeapBufMP kernel test module run is complete"
