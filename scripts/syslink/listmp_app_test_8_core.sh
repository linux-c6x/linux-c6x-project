#!/bin/sh
echo "Beginning of ListMP sample application run"
echo "insmod syslink.ko"
insmod syslink.ko
echo "Loading slave core 1"
./dl6x.gcc 1 listmp_c6678_core1.xe66
echo "Loading slave core 2"
./dl6x.gcc 2 listmp_c6678_core2.xe66
echo "Loading slave core 3"
./dl6x.gcc 3 listmp_c6678_core3.xe66
echo "Loading slave core 4"
./dl6x.gcc 4 listmp_c6678_core4.xe66
echo "Loading slave core 5"
./dl6x.gcc 5 listmp_c6678_core5.xe66
echo "Loading slave core 6"
./dl6x.gcc 6 listmp_c6678_core6.xe66
echo "Loading slave core 7"
./dl6x.gcc 7 listmp_c6678_core7.xe66
./listmpapp_debug 7 1 0x815b00 2 0x815b00 3 0x815b00 4 0x815b00 5 0x815b00 6 0x815b00 7 0x815b00 3
echo "rmmod syslink.ko"
rmmod syslink.ko
echo "ListMP sample application run is complete"
