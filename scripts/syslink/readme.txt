======== SysLink sample application readme.txt ==========

In all of the sample applications, SysLink/IPC sample runs on Core0 and 
BIOS/IPC sample applications run on remaining cores.

c66x platforms
==============

In order to simplify the syslink sample application execution by the user
wrapper scripts are provided per evm. The files are defined per core.

For C6678 - Number of cores = 8
For C6670 - Number of cores = 6

The scripts uses /usr/bin/mcoreloader for loading and running images on the
slave cores.

For example to run notify user land application on C6678, the script invoked is
./notify_app_test_8_core.sh

First update the _Ipc_ResetVector value in the script for each of the slave image. For example 
in ./notify_app_test_8_core.sh, following line to be updated before running the script.

/opt/syslink_evmc6678.el/notifyapp_release 7 1 0x815a80 2 0x815b00 3 0x815b00 4 0x815b00 5 0x815b00 6 0x815a80 7 0x815a80 3

where first argument is the number of cores, argument 2-3, 4-5, 6-7 etc are the
core id - _Ipc_ResetVector pair. 

Where Ipc Reset Vector is _Ipc_ResetVector symbol value in notify_c6678_core<x>.xe66.map,
x being the core id. _Ipc_ResetVector symbol is from the BIOS IPC application
coff or elf image. This points to slave configuration info in slave memory that SysLink
Host read. This has information such as SharedRegion 0 used for IPC, cache enabled/disabled
etc.

To get _Ipc_ResetVector, do following command from the syslink root directory after
building SysLink

>find . -name notify*map | xargs grep _Ipc_ResetVector

Here is a sample output from the above command for C6670 build of SysLink.

syslink>find . -name notify*map | xargs grep _Ipc_ResetVector

==================================================================================
./ti/syslink/samples/rtos/notify/package/cfg/ti_syslink_samples_rtos_platforms_
evm6670_core3/whole_program_debug/notify_c6670_core3.xe66.map:00815a80   _Ipc_ResetVector
=================================================================================

Where 815a80 is the _Ipc_ResetVector

To run notify kernel module sample, user has to run 2 samples

1) Start IPC by running procmgr_app_8_core.sh on C6678. Obtain _Ipc_ResetVector info as before

Make sure the _Ipc_ResetVector info is updated in procmgr_app_8_core.sh as
stated above before running the script. The vectors should be picked based on
the sample run in step 2 since they will be different for different applications.

2) Run kernel module sample by running notify_module_test_8_core.sh
 
c64x platforms
==============

For c64x platforms, there are no loader to load and run BIOS/IPC sample
applications on the slave cores . So different scripts are used for running
sample applications.

syslinktest-dss.js is a dss script that is used for loading and running BIOS
sample applications on the slave cores. syslinktest-dss.js is run on the
windows host machine. syslink-app-c64x.sh is the script for running user land
sample applications. syslink-module-c64x.sh is the script for testing kernel
module samples. These scripts are run on the target along with the syslinktest-dss.js.
Please read the documentation at the header of the above scripts for details
on how to run them.

