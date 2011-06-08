#!/bin/sh
echo "Beginning of SharedRegion sample application run"
echo "insmod syslink.ko"
insmod syslink.ko
echo "Loading slave core 1"
./dl6x.gcc 1 sharedregion_c6678_core1.xe66
echo "Loading slave core 2"
./dl6x.gcc 2 sharedregion_c6678_core2.xe66
echo "Loading slave core 3"
./dl6x.gcc 3 sharedregion_c6678_core3.xe66
echo "Loading slave core 4"
./dl6x.gcc 4 sharedregion_c6678_core4.xe66
echo "Loading slave core 5"
./dl6x.gcc 5 sharedregion_c6678_core5.xe66
echo "Loading slave core 6"
./dl6x.gcc 6 sharedregion_c6678_core6.xe66
echo "Loading slave core 7"
./dl6x.gcc 7 sharedregion_c6678_core7.xe66
./sharedregionapp_debug 0x9FE00000 7 1 0x815080 2 0x815080 3 0x815080 4 0x815080 5 0x815080 6 0x815080 7 0x815080 3
echo "rmmod syslink.ko"
rmmod syslink.ko
echo "SharedRegion sample application run is complete"
