#!/bin/sh
if [ "$1X" = "X" ]
then
        LOADER=/usr/bin/mcoreloader
else
        LOADER=$1
fi
CORES="1 2 3 4 5 6 7"
# IPC Reset Vector. configured in rtos application cfg file
IRV=0x800000

echo "Beginning of SharedRegion sample application run"
echo "insmod syslink.ko"
insmod syslink.ko
for i in $CORES
do
echo "Loading and running slave core $i"
${LOADER} $i sharedregion_c6678_core${i}.xe66
done

echo "Running sharedregion User land sample application"
./sharedregionapp_release 0x9FE00000 7 1 $IRV 2 $IRV 3 $IRV 4 $IRV 5 $IRV 6 $IRV 7 $IRV 3
echo "rmmod syslink.ko"
rmmod syslink.ko
echo "SharedRegion sample application run is complete"
