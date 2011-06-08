#!/bin/sh
if [ "$1X" = "X" ]
then
	LOADER=/usr/bin/dl6x.gcc
else
	LOADER=$1
fi
CORES="1 2 3 4 5 6 7"
echo "Beginning of GateMP sample application run"
echo "insmod syslink.ko"
insmod syslink.ko

for i in $CORES
do
echo "Loading and running slave core $i"
${LOADER} $i gatemp_c6678_core${i}.xe66
done

echo "Running GateMP User land sample application"
./gatempapp_debug 7 1 0x815c00 2 0x815c00 3 0x815c00 4 0x815c00 5 0x815c00 6 0x815c00 7 0x815c00 3
rmmod syslink.ko
echo "GateMP sample application run is complete"

