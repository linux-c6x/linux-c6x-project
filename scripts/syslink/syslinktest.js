// To get this working, following is assumed
// configs - ccs configuration file for the evm
// images - images for bios and linux
// logs - save logs
// assumes script is at a level above the above directories
// on the windows command shell, set SYSLINK_TEST_DIR env variable to
// point to root of above directories. All other directories are
// relative to this path
// cd dss script directory where dss is installed or under ccs
// example
// cd c:\Program Files\Texas Instruments\ccsv4\scripting\bin
// dss.bat <path of this script> TCI6488_USB <syslink module name> LE
//            - for faraday
// dss.bat <path of this script> TCI6486_USB <syslink module name> LE
//            - for faraday
// Import the DSS packages into our namespace to save on typing
importPackage(Packages.com.ti.debug.engine.scripting)
importPackage(Packages.com.ti.ccstudio.scripting.environment)
importPackage(Packages.java.lang)
importPackage(Packages.java.io);
//importPackage(Packages.java.io.BufferedReader);
//importPackage(Packages.java.io.InputStream);
//importPackage(Packages.java.io.InputStreamReader);

// Create our scripting environment object - which is the main entry point into
// any script and the factory for creating other Scriptable ervers and Sessions
var script = ScriptingEnvironment.instance()

var debugScriptEnv = ScriptingEnvironment.instance();

// Get the Debug Server and start a Debug Session
var debugServer = script.getServer("DebugServer.1");

// Create a log file in the current directory to log script execution
script.traceBegin("BFTRunLog.xml", "DefaultStylesheet.xsl")

//***************Functions define***************************
//****************Open file to write***********************
// if attr is true, bytes will be written to the end of the file rather than the beginning
function fileWriterOpen(path, attr)
{
	if (attr)
	{
        	file = new java.io.FileWriter(path, true);
        	return file;
    	}
    	else
	{
        	file = new java.io.FileWriter(path, false);
        	return file;
    	}
}

//****************Write to file***********************
function fileWrite(file, string)
{            
	file.write(string);
}

//**************** Close file*************************
function fileClose(file)
{            
	file.close();
}

//****************Get New Time Stamp***********************
function localTime()
{
	// get time stamp
	var currentTime = new Date();
	var year = currentTime.getFullYear();
	var month = currentTime.getMonth() + 1;
	month = month + "";
	if (month.length == 1)
	{
		month = "0" + month;
	}
	var day = currentTime.getDate();
	var hour = currentTime.getHours();
	var minute = currentTime.getMinutes();
	minute = minute + "";
	if (minute.length == 1)
	{
		minute = "0" + minute;
	}
	var second = currentTime.getSeconds();
	second = second + "";
	if (second.length == 1)
	{
		second = "0" + second;
	}
    
	return (year+"_"+month+"_"+day+"_"+hour+minute+second);
}

/**
 * Get error code from the given exception.
 * @param {exception} The exception from which to get the error code.
 */
function getErrorCode(exception)
{
	var ex2 = exception.javaException;
	if (ex2 instanceof Packages.com.ti.ccstudio.scripting.environment.ScriptingException) {
		return ex2.getErrorID();
	}
	return 0;
}

//*******************************************
// Declarations and Inititalizations
var ccxmlFileName;
var config_index        = 0;
var module_index        = 0;
var testStatus          = new Array();
var timeoutThreshold    = 480000;
var config_index_start  = 0;
var config_index_inc    = 2;
var syslink_test_dir    = java.lang.System.getenv("SYSLINK_TEST_DIR");
var syslink_log_dir     = syslink_test_dir+"\\logs\\";
var syslink_image_dir   = syslink_test_dir+"\\images\\";
var syslink_target_config = syslink_test_dir+"\\configs\\";
var when                = localTime();
var debugFlag           = true; // false; //set this to true, to see more prints
var timeout_bios_core	= 5000; // 30 seconds
var timeout_linux_core  = 15000; // 2 minutes
var num_bios_cores	= 2; // by default for faraday


// Parse the arguments
if (arguments.length > 1)
{
	var targetFlag = arguments[0];
	var moduleFlag = arguments[1];
	var endianFlag = arguments[2];
}
else
{
	print("\n  Syntax:  syslinktest.js <argument1> <argument2> <argument3>\n")
	print("\n    argument1: <TCI6486_USB/TCI6488_USB>\n")
	print("      TCI6486_USB - TCI6486 Emulator with USB\n")
	print("      TCI6488_USB - TCI6488 Emulator with USB\n")
	print("\n    argument2: <all/moduleName>\n")
	print("\n      all - All of the modules\n")
	print("      modulenName - notify/sharedregion/heapmemmp/gatemp/heapbufmp,listmp,messageq\n")
	print("\n    argument3: <BE/LE>\n")
	print("\n      BE - Big Endian\n")
	print("      LE - Little Endian\n")

	script.traceWrite("\n  Syntax:  syslinktest.js <argument1> <argument2>\n")
	script.traceWrite("\n    argument1: <TCI6486_USB/TCI6488_USB>\n")
	script.traceWrite("      TCI6486_USB - TCI6486 Emulator with USB\n")
	script.traceWrite("      TCI6488_USB - TCI6488 Emulator with USB\n")
	script.traceWrite("\n    argument2: <all/moduleName>\n")
	script.traceWrite("\n      all - All of the modules\n")
	script.traceWrite("      modulenName - notify/sharedregion/heapmemmp/gatemp/heapbufmp,listmp,messageq\n")
	script.traceWrite("\n    argument3: <BE/LE>\n")
	script.traceWrite("\n      BE - Big Endian\n")
	script.traceWrite("      LE - Little Endian\n")
	script.traceEnd()

	java.lang.System.exit(1);
}

var argCheck = true;
// check arguments
if (targetFlag == "TCI6486_USB")
{
	var targetConfig = "evmTCI6486.ccxml";
	syslink_image_dir = syslink_image_dir + "evm6486\\";
	targetConfig = syslink_target_config + targetConfig; 
	num_bios_cores = 5;
}
else if (targetFlag == "TCI6488_USB")
{
	var targetConfig = "evmTCI6488.ccxml";
	syslink_image_dir = syslink_image_dir + "evm6488\\";
	targetConfig = syslink_target_config + targetConfig; 
}
else
{
	print("Invalid Target flag passed!!!")
	script.traceWrite("Invalid Target flag passed!!!")
	argCheck = false;
}


print("Test selected is " + moduleFlag);
if (moduleFlag == "notify")
{
	module_index = 0
} else if (moduleFlag == "sharedregion")
{
	module_index = 1;
}
else if (moduleFlag == "heapmemmp")
{
	module_index = 2;
} else if (moduleFlag == "gatemp")
{
	module_index = 3;
}
else if (moduleFlag == "heapbufmp")
{
	module_index = 4;
} else if (moduleFlag == "listmp")
{
	module_index = 5;
} else if (moduleFlag == "messageq")
{
	module_index = 6;
} else if (moduleFlag == "all")
{
	module_index = 0;
} else
{
	print("Invalid module flag passed!!!")
	script.traceWrite("Invalid module flag passed!!!")
	argCheck = false;
}

if (!argCheck)
{
	script.traceEnd()
	java.lang.System.exit(1);
}

if (debugFlag)
{
	print(targetFlag)
	print(endianFlag)
}

//define configurations set
var build_config = new Array(
"LE",
"BE"
);

//define configurations names
var config_name = new Array(
"Little Endian",
"Big Endian"
);

//define platform path
var plat_path = new Array(
"little_endian",
"big_endian"
);

//define modules
// NOTE: When updating this array, make sure the last entry doesn't
// end with comma(,) otherwise Java throw error
var module = new Array(
"notify", 
"sharedregion",
"heapmemmp",
"gatemp",
"heapbufmp",
"listmp",
"messageq"
);

// create and open a log file to write
when = localTime();
var logFile = fileWriterOpen(syslink_log_dir+module[module_index]+"_"+when+".txt", 1);

fileWrite(logFile, "Start Test @ "+when+"\r\n");
script.traceWrite("\n Start SysLink test "+config_name[config_index]+" @ "+when+"\r\n");

// Configure target
debugServer.setConfig(targetConfig);

// Open the debug session
  
var validCoreFound = false;
if (targetFlag == "TCI6488_USB")
{
	debugSession = debugServer.openSession("*","C64XP_1A");
	debugSession1 = debugServer.openSession("*","C64XP_1B");
	debugSession2 = debugServer.openSession("*","C64XP_1C");
	if ((debugSession.getMajorISA() == 0x64) &&
       	    (debugSession1.getMajorISA() == 0x64)&&
	    (debugSession2.getMajorISA() == 0x64)) 
	{
        	validCoreFound = true;
    	}
} else {
	timeout_linux_core = 45000;
	debugSession = debugServer.openSession("*","C64XP");
	debugSession1 = debugServer.openSession("*","C64XP_1");
	debugSession2 = debugServer.openSession("*","C64XP_2");
	debugSession3 = debugServer.openSession("*","C64XP_3");
	debugSession4 = debugServer.openSession("*","C64XP_4");
	debugSession5 = debugServer.openSession("*","C64XP_5");
	if ((debugSession.getMajorISA() == 0x64) &&
            (debugSession1.getMajorISA() == 0x64) &&
            (debugSession2.getMajorISA() == 0x64) &&
            (debugSession3.getMajorISA() == 0x64) &&
            (debugSession4.getMajorISA() == 0x64) &&
	    (debugSession5.getMajorISA() == 0x64)) 
	{
		validCoreFound = true;
	}
}

// Error check on CPU type
if (!validCoreFound)
{
// Requires a C64x (for now)
	script.traceSetConsoleLevel(TraceLevel.INFO)
	script.traceWrite("Test requires a C64x!")
	script.traceWrite("TEST FAILED!")
	script.traceEnd()
	java.lang.System.exit(1);
}


debugSession.target.connect();
debugSession1.target.connect();
debugSession2.target.connect();
debugSession.target.reset();
debugSession1.target.reset();
debugSession2.target.reset();

var linuxSession = debugSession2;
var linuxProgram = syslink_image_dir + "vmlinux";
var lastBiosCore = 1;

if (targetFlag == "TCI6486_USB")
{
	linuxSession = debugSession5;
	lastBiosCore = 4;
	debugSession3.target.connect();
	debugSession4.target.connect();
	debugSession5.target.connect();
	debugSession3.target.reset();
	debugSession4.target.reset();
	debugSession5.target.reset();
}

// Reset
  
// Load a program
// (ScriptingEnvironment has a concept of a working folder and for all of the APIs which take
// path names as arguments you can either pass a relative path or an absolute path)
// Run to end of program (or timeout) and return total cycles unless asynch run.
var loadPass = false;
try
{
       print("Loading linux program " + linuxProgram + "\n"); 
       // Check to see if .out file exists, if not print test failed and go on
       script.traceWrite("Loading Linux program " + linuxProgram + "\n");
       linuxSession.memory.loadProgram(linuxProgram);
       if (debugFlag)
       {
           print("\nDEBUG: Loading successful for linux core...\n\n");
       }

       loadPass = true;
}
catch (ex)
{
       errCode = getErrorCode(ex);
       script.traceWrite("Error code #" + errCode + ", " + linuxProgram + " load failed!\nAborting!");
       // quit(errCode != 0 ? errCode : 1);
       loadPass = false;
       print(errCode);
}
       // load and run linux kernel image
       debugScriptEnv.setScriptTimeout(timeout_linux_core);

try {
       // Remove any and all breakpoints and run to completion
       linuxSession.breakpoint.removeAll();
       linuxSession.target.run();
}
catch (ex)
{
       print("\nDEBUG: Running of Linux core is successful...\n\n");
}


// Start the test
var biosProgram = biosProgram = syslink_image_dir + module[module_index];

script.traceWrite("Loading and running BIOS application for "+module[module_index]+"\n");

if ((module_index == 2) || (module_index == 3))
{
	if (targetFlag == "TCI6486_USB")
	{
		biosProgram = biosProgram + "_c6472core";
	}
	else
	{
		biosProgram = biosProgram + "_c6474core";
	}
}
else
{
	if (targetFlag == "TCI6486_USB")
	{
		//var sProgram = syslink_image_dir + module[module_index] + "_c6474_core0.x64P";
		biosProgram = biosProgram + "_c6472_core";
	}
	else
	{
		biosProgram = biosProgram + "_c6474_core";
	}
}

var coreId = 0;

if ( loadPass )
{
	var Program;
	do
	{
		try
		{
       			loadPass = false;
			Program = biosProgram + coreId + ".x64P";
 
       			script.traceWrite("Loading " + Program + "\n");
			print("Loading " + Program + "\n");
			switch (coreId)
			{
				case 0:
       					debugSession.memory.loadProgram(Program);
       					loadPass = true;
					break;
				case 1:
       					debugSession1.memory.loadProgram(Program);
       					loadPass = true;
					break;
				case 2:
       					debugSession2.memory.loadProgram(Program);
       					loadPass = true;
					break;
				case 3:
       					debugSession3.memory.loadProgram(Program);
       					loadPass = true;
					break;
				case 4:
       					debugSession4.memory.loadProgram(Program);
       					loadPass = true;
					break;
				case 5:
       					loadPass = true;
       					debugSession5.memory.loadProgram(Program);
					break;
			}
		}
		catch (ex)
		{
       			errCode = getErrorCode(ex);
       			script.traceWrite("Error code #" + errCode + ", " + Program + " load failed!\nAborting!");
       			// quit(errCode != 0 ? errCode : 1);
       			loadPass = false;
       			print(errCode);
		}
		coreId++;
	}
	while (loadPass && (coreId <= lastBiosCore));
}

	var IpcResetVector = debugSession.symbol.getAddress("Ipc_ResetVector"); 
	print("********IpcResetVector is 0x" + Integer.toHexString(IpcResetVector) + " *********"); 

if ( loadPass )
{
       	debugScriptEnv.setScriptTimeout(timeout_bios_core);
	try {
       		// Remove any and all breakpoints and run to completion
       		debugSession.breakpoint.removeAll();
       		debugSession.target.run();
	}
	catch (ex)
	{
       		print("\nDEBUG: Running of core0 successful...\n\n");
	}

        debugScriptEnv.setScriptTimeout(timeout_bios_core);

	try {
       		debugSession1.breakpoint.removeAll();
       		debugSession1.target.run();
	}
	catch (ex)
	{
       		print("\nDEBUG: Running of core1 successful...\n\n");
	}
}

if ( loadPass && (targetFlag == "TCI6486_USB"))
{
       	debugScriptEnv.setScriptTimeout(timeout_bios_core);
	try {
       		// Remove any and all breakpoints and run to completion
       		debugSession2.breakpoint.removeAll();
       		debugSession2.target.run();
	}
	catch (ex)
	{
       		print("\nDEBUG: Running of core2 successful...\n\n");
	}

       	debugScriptEnv.setScriptTimeout(timeout_bios_core);
	try {
       		// Remove any and all breakpoints and run to completion
       		debugSession3.breakpoint.removeAll();
       		debugSession3.target.run();
	}
	catch (ex)
	{
       		print("\nDEBUG: Running of core3 successful...\n\n");
	}

       	debugScriptEnv.setScriptTimeout(timeout_bios_core);
	try {
       		// Remove any and all breakpoints and run to completion
       		debugSession4.breakpoint.removeAll();
       		debugSession4.target.run();
	}
	catch (ex)
	{
       		print("\nDEBUG: Running of core4 successful...\n\n");
	}
}

print("********IpcResetVector for " + module[module_index] + " is 0x" + Integer.toHexString(IpcResetVector) + " *********"); 
print("Type any key once syslink test is complete");
java.lang.System['in'].read();

print("Cleaning up....\n");

when = localTime();
fileWrite(logFile, "\nEnd " + module[module_index] + " Test @ " + when + "\n\n");

if (debugFlag)
{
       print("\nDEBUG: Logging successful...\n\n");
}

debugSession.terminate();
debugSession1.terminate();
debugSession2.terminate();
if ( targetFlag == "TCI6486_USB")
{
	debugSession3.terminate();
	debugSession4.terminate();
	debugSession5.terminate();
}
 
// Close log file
fileWrite(logFile, "\n\n\n");
fileClose(logFile);


// All done
// Stop debug server
debugServer.stop()
script.traceSetConsoleLevel(TraceLevel.INFO);

// Stop logging and exit.
script.traceEnd();
java.lang.System.exit(0);
