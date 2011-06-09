#!/bin/sh
if [ "$1X" = "X" ]
then
        LOADER=/usr/bin/dl6x.gcc
else
        LOADER=$1
fi
CORES="1 2 3"
echo "Beginning of HeapMemMP sample application run"
echo "insmod syslink.ko"
insmod syslink.ko

for i in $CORES
do
echo "Loading and running slave core $i"
${LOADER} $i heapmemmp_c6670_core${i}.xe66
done

echo "Running heapmemmp User land sample application"
./heapmemmpapp_debug 3 1 0x815f00 2 0x815f00 3 0x815f00 3
echo "rmmod syslink.ko"
rmmod syslink.ko
echo "HeapMemMP sample application run is complete"
