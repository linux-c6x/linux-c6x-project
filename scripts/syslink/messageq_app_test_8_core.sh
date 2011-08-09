#!/bin/sh
if [ "$1X" = "X" ]
then
        LOADER=/usr/bin/mcoreloader
else
        LOADER=$1
fi
# IPC Reset Vector. configured in rtos application cfg file
IRV=0x800000

CORES="1 2 3 4 5 6 7"
echo "Beginning of MessageQ sample application run"
echo "insmod syslink.ko"
insmod /opt/syslink_evmc6678.el/syslink.ko

for i in $CORES
do
echo "Loading and running slave core $i"
${LOADER} $i /opt/syslink_evmc6678.el/messageq_c6678_core${i}.xe66
done

echo "Running messageq User land sample application"
/opt/syslink_evmc6678.el/messageqapp_release 7 1 $IRV 2 $IRV 3 $IRV 4 $IRV 5 $IRV 6 $IRV 7 $IRV 3
echo "rmmod syslink.ko"
rmmod /opt/syslink_evmc6678.el/syslink.ko
echo "MessageQ sample application run is complete"
