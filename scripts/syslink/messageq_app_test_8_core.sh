#!/bin/sh
if [ "$1X" = "X" ]
then
        LOADER=/usr/bin/mcoreloader
else
        LOADER=$1
fi
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
/opt/syslink_evmc6678.el/messageqapp_release 7 1 0x817300 2 0x817300 3 0x817300 4 0x817300 5 0x817300 6 0x817300 7 0x817300 3
echo "rmmod syslink.ko"
rmmod /opt/syslink_evmc6678.el/syslink.ko
echo "MessageQ sample application run is complete"
