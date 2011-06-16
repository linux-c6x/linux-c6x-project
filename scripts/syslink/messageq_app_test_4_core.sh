#!/bin/sh
if [ "$1X" = "X" ]
then
        LOADER=/usr/bin/mcoreloader
else
        LOADER=$1
fi
CORES="1 2 3"
echo "Beginning of MessageQ sample application run"
echo "insmod syslink.ko"
insmod /opt/syslink_evmc6670.el/syslink.ko

for i in $CORES
do
echo "Loading and running slave core $i"
${LOADER} $i /opt/syslink_evmc6670.el/messageq_c6670_core${i}.xe66
done

echo "Running messageq User land sample application"
/opt/syslink_evmc6670.el/messageqapp_release 3 1 0x817300 2 0x817300 3 0x817300 3
echo "rmmod syslink.ko"
rmmod /opt/syslink_evmc6670.el/syslink.ko
echo "MessageQ sample application run is complete"
