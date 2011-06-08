#!/bin/sh
if [ "$1X" = "X" ]
then
        LOADER=/usr/bin/dl6x.gcc
else
        LOADER=$1
fi
CORES="1 2 3 4 5 6 7"
echo "Beginning of HeapMemMP kernel test module run"
echo "insmod syslink.ko"
insmod syslink.ko

for i in $CORES
do
echo "Loading and running slave core $i"
${LOADER} $i heapmemmp_c6678_core${i}.xe66
done

echo "Running procmgr User land sample application"
./procmgrapp_debug 7 1 0x815f00 2 0x815f00 3 0x815f00 4 0x815f00 5 0x815f00 6 0x815f00 7 0x815f00 3
echo "rmmod syslink.ko"
rmmod syslink.ko
echo "HeapMemMP kernel test module run is complete"
