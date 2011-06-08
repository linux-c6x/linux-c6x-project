#!/bin/sh
echo "Beginning of MessageQ kernel test module run"
echo "insmod syslink.ko"
insmod syslink.ko
echo "Loading and running slave core 1"
./dl6x.gcc 1 messageq_c6678_core1.xe66
echo "Loading and running slave core 2"
./dl6x.gcc 2 messageq_c6678_core2.xe66
echo "Loading and running slave core 3"
./dl6x.gcc 3 messageq_c6678_core3.xe66
echo "Loading and running slave core 4"
./dl6x.gcc 4 messageq_c6678_core4.xe66
echo "Loading and running slave core 5"
./dl6x.gcc 5 messageq_c6678_core5.xe66
echo "Loading and running slave core 6"
./dl6x.gcc 6 messageq_c6678_core6.xe66
echo "Loading and running slave core 7"
./dl6x.gcc 7 messageq_c6678_core7.xe66
echo "Running Notify User land sample application"
./procmgrapp_debug 7 1 0x817300 2 0x817300 3 0x817300 4 0x817300 5 0x817300 6 0x817300 7 0x817300 3
echo "rmmod syslink.ko"
rmmod syslink.ko
echo "MessageQ kernel test module run is complete"
