#!/bin/sh
if [ "$1X" = "X" ]
then
        LOADER=/usr/bin/mcoreloader
else
        LOADER=$1
fi
CORES="1 2 3 4 5 6 7"
echo "Beginning of SharedRegion sample application run"
echo "insmod syslink.ko"
insmod syslink.ko
for i in $CORES
do
echo "Loading and running slave core $i"
${LOADER} $i sharedregion_c6678_core${i}.xe66
done

echo "Running sharedregion User land sample application"
./sharedregionapp_debug 0x9FE00000 7 1 0x815080 2 0x815080 3 0x815080 4 0x815080 5 0x815080 6 0x815080 7 0x815080 3
echo "rmmod syslink.ko"
rmmod syslink.ko
echo "SharedRegion sample application run is complete"
