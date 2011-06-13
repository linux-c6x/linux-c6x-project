#!/bin/sh
if [ "$1X" = "X" ]
then
        LOADER=/usr/bin/mcoreloader
else
        LOADER=$1
fi
CORES="1 2 3 4 5 6 7"
echo "Beginning of HeapBufMP kernel test module run"
echo "insmod syslink.ko"
insmod syslink.ko

for i in $CORES
do
echo "Loading and running slave core $i"
${LOADER} $i heapbufmp_c6678_core${i}.xe66
done
echo "Running procmgr User land sample application"
./procmgrapp_release 7 1 0x817180 2 0x817180 3 0x817180 4 0x817180 5 0x817180 6 0x817180 7 0x817180 3
echo "rmmod syslink.ko"
rmmod syslink.ko
echo "HeapBufMP kernel test module run is complete"
