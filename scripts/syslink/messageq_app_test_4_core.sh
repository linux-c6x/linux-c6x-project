#!/bin/sh
if [ "$1X" = "X" ]
then
        LOADER=/usr/bin/dl6x.gcc
else
        LOADER=$1
fi
CORES="1 2 3"
echo "Beginning of MessageQ sample application run"
echo "insmod syslink.ko"
insmod syslink.ko

for i in $CORES
do
echo "Loading and running slave core $i"
${LOADER} $i messageq_c6670_core${i}.xe66
done

echo "Running messageq User land sample application"
./messageqapp_debug 3 1 0x817300 2 0x817300 3 0x817300 3
echo "rmmod syslink.ko"
rmmod syslink.ko
echo "MessageQ sample application run is complete"
