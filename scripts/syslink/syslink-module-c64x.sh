#!/bin/sh

# ******   SYSLINK Kernel module Test script ****************************************************
# **
# ** Script to test SysLink kernel sample modules
# **
# ** Run the syslinktest-dss-c64x.js to load and run Linux and BIOS apps on DSP cores
# ** Once Linux is loaded and started, immediately telnet to evm and run the
# ** syslink-app-c644x.sh with app-name "procmgrapp" to start IPC with remote DSP
# ** cores. This is needed before running this script which tests the kernel
# ** module samples. Type syslink-module.sh <enter> to see the options
# ** Set MEM=112M in the kernel command line parameter to reserve upper 16M
# ** for SysLink
# ***********************************************************************************************

if [ "$#" != "2" ]
then
	echo "syslink-module-c64x.sh <app-name> <num-slave-cores>"
	echo "num-slave-cores = 5 for c6472 and 2 for c6474"
	echo "app-names:-"
	echo "	- notifyapp, gatempapp, heapbufmpapp, heapmemmpapp, listmpapp, messageqapp, sharedregionapp"
	exit
fi

app_name=$1
num_cores=$2

# shared region address used for testing
# C6472 - 0xE7E00000
# C6474 - 0x87E00000
appsharedregion=


case $app_name in
	notifyapp)
		;;
	gatempapp)
		;;
	heapbufmpapp)
		;;
	heapmemmpapp)
		;;
	listmpapp)    
		;;
	messageqapp)
		;;
	sharedregionapp)
		if [ "$num_cores" == "5" ]
		then
			#assume platform based on core time being
			appsharedregion=0xE7E00000
		else
			appsharedregion=0x87E00000
		fi
		;;
	*)
		echo "unknown application"
		exit
		;;
esac

if [ "$num_cores" != "5" ]
then
	if [ "$num_cores" != "2" ]
	then
		echo "arg3 should be 5 for c6472, 2 for c6474"
		exit
	fi
fi

echo Testing release version of notify application, num-cores=$num_cores reset_vector=$reset_vector
if [ "${appsharedregion}X" != "X" ]
then
	echo "Using App SharedRegion address $appsharedregion"
fi

if [ "$num_cores" == "5" ]
then
	echo "Testing on C6472"
else
        echo "Testing on C6474"
fi

if [ "$app_name" == "sharedregionapp" ]
then
	insmod "$app_name".ko SHAREDMEM=$appsharedregion NUMPROCS=$num_cores PROCID=01234
else
	insmod "$app_name".ko NUMPROCS=$num_cores PROCID=01234
fi
sleep 1
rmmod "$app_name".ko

