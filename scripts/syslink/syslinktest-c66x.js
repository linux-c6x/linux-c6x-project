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
	print("\n    argument1: <C6678_USB/C6670_USB>\n")
      print("      C6678_USB - C6678 Emulator with USB\n")
	print("      C6670_USB - C6670 Emulator with USB\n")
	print("\n    argument2: <all/moduleName>\n")
	print("\n      all - All of the modules\n")
	print("      modulenName - notify/sharedregion/heapmemmp/gatemp/heapbufmp,listmp,messageq\n")
	print("\n    argument3: <BE/LE>\n")
	print("\n      BE - Big Endian\n")
	print("      LE - Little Endian\n")

	script.traceWrite("\n  Syntax:  syslinktest.js <argument1> <argument2>\n")
	script.traceWrite("\n    argument1: <C6678_USB/C6670_USB>\n")
	script.traceWrite("      C6678_USB - C6678 Emulator with USB\n")
	script.traceWrite("      C6670_USB - C6670 Emulator with USB\n")
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
if (targetFlag == "C6678_USB")
{
	var targetConfig = "evm6678.ccxml";
	if (endianFlag == "LE")
	{
		syslink_image_dir = syslink_image_dir + "evm6678.el\\";
	} else {
		syslink_image_dir = syslink_image_dir + "evm6678.eb\\";
	}
	targetConfig = syslink_target_config + targetConfig; 
} else if (targetFlag == "C6670_USB")
{
	var targetConfig = "evm6670.ccxml";
	if (endianFlag == "LE")
	{
		syslink_image_dir = syslink_image_dir + "evm6670.el\\";
	} else {
		syslink_image_dir = syslink_image_dir + "evm6670.eb\\";
	}
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
if (targetFlag == "C6678_USB"){
	debugSession0 = debugServer.openSession("*","C66xx_0");
	debugSession1 = debugServer.openSession("*","C66xx_1");
	debugSession2 = debugServer.openSession("*","C66xx_2");
	debugSession3 = debugServer.openSession("*","C66xx_3");
	debugSession4 = debugServer.openSession("*","C66xx_4");
	debugSession5 = debugServer.openSession("*","C66xx_5");
	debugSession6 = debugServer.openSession("*","C66xx_6");
	debugSession7 = debugServer.openSession("*","C66xx_7");

	if ((debugSession0.getMajorISA() == 0x66) &&
            (debugSession1.getMajorISA() == 0x66) &&
            (debugSession2.getMajorISA() == 0x66) &&
            (debugSession3.getMajorISA() == 0x66) &&
            (debugSession4.getMajorISA() == 0x66) &&
            (debugSession5.getMajorISA() == 0x66) &&
		(debugSession6.getMajorISA() == 0x66) &&
		(debugSession7.getMajorISA() == 0x66)) 
	{
		validCoreFound = true;
	}
} else if (targetFlag == "C6670_USB"){
	debugSession0 = debugServer.openSession("*","C66xx_0");
	debugSession1 = debugServer.openSession("*","C66xx_1");
	debugSession2 = debugServer.openSession("*","C66xx_2");
	debugSession3 = debugServer.openSession("*","C66xx_3");
	if ((debugSession0.getMajorISA() == 0x66) &&
            (debugSession1.getMajorISA() == 0x66) &&
            (debugSession2.getMajorISA() == 0x66) &&
            (debugSession3.getMajorISA() == 0x66)) 
	{
		validCoreFound = true;
	}
}

// Error check on CPU type
if (!validCoreFound)
{
	script.traceSetConsoleLevel(TraceLevel.INFO)
	script.traceWrite("Test requires a C66x!")
	script.traceWrite("TEST FAILED!")
	script.traceEnd()
	java.lang.System.exit(1);
}


debugSession0.target.connect();
debugSession1.target.connect();
debugSession2.target.connect();
debugSession3.target.connect();
debugSession0.expression.evaluate('GEL_AdvancedReset("System Reset")');
// debugSession0.target.reset();
debugSession1.target.reset();
debugSession2.target.reset();
debugSession3.target.reset();


var linuxSession = debugSession0;
var linuxProgram = syslink_image_dir + "vmlinux";
var lastBiosCore = 3;

if (targetFlag == "C6678_USB")
{
	lastBiosCore = 7;
	debugSession4.target.connect();
	debugSession5.target.connect();
	debugSession6.target.connect();
	debugSession7.target.connect();
	debugSession4.target.reset();
	debugSession5.target.reset();
	debugSession6.target.reset();
	debugSession7.target.reset();
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

print("********Linux Kernel is running. do insmod syslink.ko and type <enter>*********"); 
java.lang.System['in'].read();
java.lang.System['in'].read();


// Start the test
var biosProgram = biosProgram = syslink_image_dir + module[module_index];

script.traceWrite("Loading and running BIOS application for "+module[module_index]+"\n");

if (targetFlag == "C6678_USB")
{
	biosProgram = biosProgram + "_c6678_core";
}
else
{
	biosProgram = biosProgram + "_c6670_core";
}

var coreId = 1;

if ( loadPass )
{
	var Program;
	do
	{
		try
		{
       		loadPass = false;
			if (endianFlag == "LE") {
			    Program = biosProgram + coreId + ".xe66";
                  } else {
			    Program = biosProgram + coreId + ".xe66e";
       	      }
    		      script.traceWrite("Loading " + Program + "\n");
			print("Loading " + Program + "\n");
			switch (coreId)
			{
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
       				      debugSession5.memory.loadProgram(Program);
						loadPass = true;
					break;
				case 6:
       					debugSession6.memory.loadProgram(Program);
						loadPass = true;
					break;
				case 7:
       					debugSession7.memory.loadProgram(Program);
						loadPass = true;
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

	var IpcResetVector = debugSession1.symbol.getAddress("Ipc_ResetVector"); 
	print("********IpcResetVector is 0x" + Integer.toHexString(IpcResetVector) + " *********"); 

if ( loadPass )
{
       	debugScriptEnv.setScriptTimeout(timeout_bios_core);
	try {
       		// Remove any and all breakpoints and run to completion
       		debugSession1.breakpoint.removeAll();
       		debugSession1.target.run();
	}
	catch (ex)
	{
       		print("\nDEBUG: Running of core1 successful...\n\n");
	}

      debugScriptEnv.setScriptTimeout(timeout_bios_core);

	try {
       		debugSession2.breakpoint.removeAll();
       		debugSession2.target.run();
	}
	catch (ex)
	{
       		print("\nDEBUG: Running of core2 successful...\n\n");
	}

      debugScriptEnv.setScriptTimeout(timeout_bios_core);

	try {
       		debugSession3.breakpoint.removeAll();
       		debugSession3.target.run();
	}
	catch (ex)
	{
       		print("\nDEBUG: Running of core3 successful...\n\n");
	}

}

if ( loadPass && (targetFlag == "C6678_USB"))
{
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

      debugScriptEnv.setScriptTimeout(timeout_bios_core);
	try {
       		// Remove any and all breakpoints and run to completion
       		debugSession5.breakpoint.removeAll();
       		debugSession5.target.run();
	}
	catch (ex)
	{
       		print("\nDEBUG: Running of core5 successful...\n\n");
	}

      debugScriptEnv.setScriptTimeout(timeout_bios_core);
	try {
       		// Remove any and all breakpoints and run to completion
       		debugSession6.breakpoint.removeAll();
       		debugSession6.target.run();
	}
	catch (ex)
	{
       		print("\nDEBUG: Running of core6 successful...\n\n");
	}

      debugScriptEnv.setScriptTimeout(timeout_bios_core);
	try {
       		// Remove any and all breakpoints and run to completion
       		debugSession7.breakpoint.removeAll();
       		debugSession7.target.run();
	}
	catch (ex)
	{
       		print("\nDEBUG: Running of core7 successful...\n\n");
	}

}

print("********IpcResetVector for " + module[module_index] + " is 0x" + Integer.toHexString(IpcResetVector) + " *********"); 
print("Run SysLink IPC application and Type <enter> when test is complete");
java.lang.System['in'].read();

print("Cleaning up....\n");

when = localTime();
fileWrite(logFile, "\nEnd " + module[module_index] + " Test @ " + when + "\n\n");

if (debugFlag)
{
       print("\nDEBUG: Logging successful...\n\n");
}

debugSession0.terminate();
debugSession1.terminate();
debugSession2.terminate();
debugSession3.terminate();

if ( targetFlag == "C6678_USB")
{
	debugSession4.terminate();
	debugSession5.terminate();
	debugSession6.terminate();
	debugSession7.terminate();
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
