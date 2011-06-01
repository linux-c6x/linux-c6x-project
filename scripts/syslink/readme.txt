======== SysLink sample application readme.txt ==========

In order to simplify the syslink sample application execution by the user
wrapper scripts are provided per evm. The files are defined per core.

For C6472 - Number of cores = 6
For C6474 - Number of cores = 3
For C6678 - Number of cores = 8
For C6670 - Number of cores = 6

For example to run notify user land application on C6678, the script invoked is
./notify_app_test_8_core.sh <Ipc Reset Vector>
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
2) Run kernel module sample by running notify_module_test_8_core.sh
 
