#!/bin/sh
if [ "$1X" = "X" ]
then
        LOADER=/usr/bin/mcoreloader
else
        LOADER=$1
fi
CORES="1 2 3"
# IPC Reset Vector. configured in rtos application cfg file
IRV=0x800000

echo "Beginning of HeapMemMP sample application run"
echo "insmod syslink.ko"
insmod syslink.ko

for i in $CORES
do
echo "Loading and running slave core $i"
${LOADER} $i heapmemmp_c6670_core${i}.xe66
done

echo "Running heapmemmp User land sample application"
./heapmemmpapp_release 3 1 $IRV 2 $IRV 3 $IRV 3
echo "rmmod syslink.ko"
rmmod syslink.ko
echo "HeapMemMP sample application run is complete"
