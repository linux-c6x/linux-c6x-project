#!/bin/sh
echo "Beginning of GateMP sample application run"
echo "insmod syslink.ko"
insmod syslink.ko
echo "Loading slave core 1"
./dl6x.gcc 1 gatemp_c6678_core1.xe66
echo "Loading slave core 2"
./dl6x.gcc 2 gatemp_c6678_core2.xe66
echo "Loading slave core 3"
./dl6x.gcc 3 gatemp_c6678_core3.xe66
echo "Loading slave core 4"
./dl6x.gcc 4 gatemp_c6678_core4.xe66
echo "Loading slave core 5"
./dl6x.gcc 5 gatemp_c6678_core5.xe66
echo "Loading slave core 6"
./dl6x.gcc 6 gatemp_c6678_core6.xe66
echo "Loading slave core 7"
./dl6x.gcc 7 gatemp_c6678_core7.xe66
./gatempapp_debug 7 1 0x815c00 2 0x815c00 3 0x815c00 4 0x815c00 5 0x815c00 6 0x815c00 7 0x815c00 3
rmmod syslink.ko
echo "GateMP sample application run is complete"


