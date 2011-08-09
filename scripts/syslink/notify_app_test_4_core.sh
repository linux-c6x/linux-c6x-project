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

echo "Beginning of Notify sample application run"
echo "insmod syslink.ko"
insmod /opt/syslink_evmc6670.el/syslink.ko
for i in $CORES
do
echo "Loading and running slave core $i"
${LOADER} $i /opt/syslink_evmc6670.el/notify_c6670_core${i}.xe66
done

echo "Running Notify User land sample application"
/opt/syslink_evmc6670.el/notifyapp_release 3 1 $IRV 2 $IRV 3 $IRV 3 
echo "rmmod syslink.ko"
rmmod /opt/syslink_evmc6670.el/syslink.ko
echo "Notify sample application run is complete"

