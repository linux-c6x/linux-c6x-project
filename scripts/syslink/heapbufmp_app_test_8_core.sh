#!/bin/sh
echo "Beginning of HeapBufMP sample application run"
echo "insmod syslink.ko"
insmod syslink.ko
echo "Loading slave core 1"
./dl6x.gcc 1 heapbufmp_c6678_core1.xe66
echo "Loading slave core 2"
./dl6x.gcc 2 heapbufmp_c6678_core2.xe66
echo "Loading slave core 3"
./dl6x.gcc 3 heapbufmp_c6678_core3.xe66
echo "Loading slave core 4"
./dl6x.gcc 4 heapbufmp_c6678_core4.xe66
echo "Loading slave core 5"
./dl6x.gcc 5 heapbufmp_c6678_core5.xe66
echo "Loading slave core 6"
./dl6x.gcc 6 heapbufmp_c6678_core6.xe66
echo "Loading slave core 7"
./dl6x.gcc 7 heapbufmp_c6678_core7.xe66
./heapbufmpapp_debug 7 1 0x817180 2 0x817180 3 0x817180 4 0x817180 5 0x817180 6 0x817180 7 0x817180 3
echo "rmmod syslink.ko"
rmmod syslink.ko
echo "HeapBufMP sample application run is complete"
