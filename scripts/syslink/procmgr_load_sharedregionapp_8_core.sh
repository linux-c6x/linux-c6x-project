#!/bin/sh
echo "Beginning of SharedRegion kernel test module run"
echo "insmod syslink.ko"
insmod syslink.ko
echo "Loading and running slave core 1"
./dl6x.gcc 1 sharedregion_c6678_core1.xe66
echo "Loading and running slave core 2"
./dl6x.gcc 2 sharedregion_c6678_core2.xe66
echo "Loading and running slave core 3"
./dl6x.gcc 3 sharedregion_c6678_core3.xe66
echo "Loading and running slave core 4"
./dl6x.gcc 4 sharedregion_c6678_core4.xe66
echo "Loading and running slave core 5"
./dl6x.gcc 5 sharedregion_c6678_core5.xe66
echo "Loading and running slave core 6"
./dl6x.gcc 6 sharedregion_c6678_core6.xe66
echo "Loading and running slave core 7"
./dl6x.gcc 7 sharedregion_c6678_core7.xe66
echo "Running Notify User land sample application"
./procmgrapp_debug 7 1 0x815080 2 0x815080 3 0x815080 4 0x815080 5 0x815080 6 0x815080 7 0x815080 3
echo "rmmod syslink.ko"
rmmod syslink.ko
echo "SharedRegion kernel test module run is complete"
