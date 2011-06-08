#!/bin/sh
if [ "$1X" = "X" ]
then
        LOADER=/usr/bin/dl6x.gcc
else
        LOADER=$1
fi
CORES="1 2 3 4 5 6 7"
echo "Beginning of MessageQ sample application run"
echo "insmod syslink.ko"
insmod syslink.ko

for i in $CORES
do
echo "Loading and running slave core $i"
${LOADER} $i messageq_c6678_core${i}.xe66
done

echo "Running messageq User land sample application"
./messageqapp_debug 7 1 0x817300 2 0x817300 3 0x817300 4 0x817300 5 0x817300 6 0x817300 7 0x817300 3
echo "rmmod syslink.ko"
rmmod syslink.ko
echo "MessageQ sample application run is complete"
