#!/bin/sh
if [ "$1X" = "X" ]
then
	LOADER=/usr/bin/mcoreloader
else
	LOADER=$1
fi
CORES="1 2 3"
echo "Beginning of GateMP sample application run"
echo "insmod syslink.ko"
insmod syslink.ko

for i in $CORES
do
echo "Loading and running slave core $i"
${LOADER} $i gatemp_c6670_core${i}.xe66
done

echo "Running GateMP User land sample application"
./gatempapp_release 3 1 0x815c80 2 0x815c80 3 0x815c80 3
rmmod syslink.ko
echo "GateMP sample application run is complete"

