#!/bin/sh
if [ "$1X" = "X" ]
then
        LOADER=/usr/bin/dl6x.gcc
else
        LOADER=$1
fi
CORES="1 2 3 4 5 6 7"
echo "Beginning of Notify sample application run"
echo "insmod syslink.ko"
insmod syslink.ko

for i in $CORES
do
echo "Loading and running slave core $i"
${LOADER} $i notify_c6678_core${i}.xe66
done
echo "Running procmgr User land sample application"

./procmgrapp_debug 7 1 0x815a80 2 0x815b00 3 0x815b00 4 0x815b00 5 0x815b00 6 0x815a80 7 0x815a80 3 
echo "rmmod syslink.ko"
rmmod syslink.ko
echo "Notify sample application run is complete"
