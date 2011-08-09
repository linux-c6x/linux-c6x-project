#!/bin/sh
# ******   SYSLINK Test script *****************************************************************
# **
# ** Script to test SysLink user land sample applications
# **
# ** Run the syslinktest-dss-c64x.js to load and run Linux and BIOS apps on DSP cores
# ** Once Linux is loaded and started, immediately telnet to evm and run this script
# ** This is required since BIOS cores to be loaded and run only after insmod syslink.
# ** Read the reset vector displayed by the syslinktest-dss.js script as input to this
# ** script. Type syslink-app-c64x.sh <enter> to see the options
# ** Set MEM=112M in the kernel command line parameter to reserve upper 16M for SysLink
# ***********************************************************************************************

if [ "$#" != "3" ]
then
	echo "syslink-app-c64x.sh <app-name> <num-slave-cores> <debug/release>"
	echo "app-names:-"
	echo "	- procmgrapp, notifyapp, gatempapp, heapbufmpapp, heapmemmpapp, listmpapp, messageqapp, sharedregionapp"
	echo "num-slave-cores = 5 for c6472 and 2 for c6474"
	exit
fi

app_name=$1
app_type=$3
num_cores=$2

echo "application name $app_name"
echo "application type $app_type"
echo "num_cores $num_cores"
# shared region address used for testing
# C6472 - 0xE7E00000
# C6474 - 0x87E00000
appsharedregion=

case $app_name in
	procmgrapp)
		;;
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

if [ "$app_type" != "debug" ]
then
	if [ "$app_type" != "release" ]
	then
		echo "arg 2 should be debug/release"
		exit
	fi
fi

if [ "$num_cores" != "5" ]
then
	if [ "$num_cores" != "2" ]
	then
		echo "arg3 should be 5 for c6472, 2 for c6474"
		exit
	fi
fi

reset_vector=0x800000
insmod syslink.ko
echo "Load BIOS application on slave cores and Type  <enter>"
read none


echo "Testing release version of notify application, num-cores=$num_cores reset_vector=$reset_vector"
if [ "${appsharedregion}X" != "X" ]
then
	echo "Using App SharedRegion address $appsharedregion"
fi

if [ "$app_type" == "debug" ] 
then
	if [ "$num_cores" == "5" ]
	then
                echo "Testing on C6472"
		if [ "$app_name" == "sharedregionapp" ]
		then
			./"$app_name"_debug "$appsharedregion" 5 0 $reset_vector 1 $reset_vector 2 $reset_vector 3 $reset_vector 4 $reset_vector 3 
		else
			./"$app_name"_debug 5 0 $reset_vector 1 $reset_vector 2 $reset_vector 3 $reset_vector 4 $reset_vector 3 
		fi
	else
                echo "Testing on C6474"
		if [ "$app_name" == "sharedregionapp" ]
		then
			./"$app_name"_debug "$appsharedregion" 2 0 $reset_vector 1 $reset_vector 3 
		else
			./"$app_name"_debug 2 0 $reset_vector 1 $reset_vector 3 
		fi
	fi
else
	if [ "$num_cores" == "5" ]
	then
                echo "Testing on C6472"
		if [ "$app_name" == "sharedregionapp" ]
		then
			./"$app_name"_release "$appsharedregion" 5 0 $reset_vector 1 $reset_vector 2 $reset_vector 3 $reset_vector 4 $reset_vector 3 
		else
			./"$app_name"_release 5 0 $reset_vector 1 $reset_vector 2 $reset_vector 3 $reset_vector 4 $reset_vector 3 
		fi
	else
                echo "Testing on C6474"
		if [ "$app_name" == "sharedregionapp" ]
		then
			./"$app_name"_release "$appsharedregion" 2 0 $reset_vector 1 $reset_vector 3 
		else
			./"$app_name"_release 2 0 $reset_vector 1 $reset_vector 3 
		fi
	fi
fi
rmmod syslink.ko

