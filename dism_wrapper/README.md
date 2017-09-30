This is a dism wrapper script to resolve the issue with SCCM OSD documented here:
https://blogs.technet.microsoft.com/system_center_configuration_manager_operating_system_deployment_support_blog/2016/12/28/apply-driver-package-task-fails-when-the-adk-is-upgrade-to-adk-10-1607/

- Compile dism_wrapper.au3 script to create AMD64 and x86 versions.
- Copy both compiled scripts and the dism_wrapper.cmd file into an SCCM package.
- Create and distribute SCCM package to DPs.
- Create run command line action in your task sequence.
  - Place this action just before your Apply Driver Package section of the task sequence.
  - Command line: dism_wrapper.cmd
  - Package: the new SCCM package created above
  
That's it!  The best part is it's just a single run command line action prior to your normal Apply Driver Package actions.  No need for retry if fail groupings and multiple task sequence actions for retry logic.

The cmd file performs the following:
- Rename X:\Windows\System32\dism.exe to dism2.exe
- Copy in the appropriate compiled script (based on %processor_architecture%) as the new X:\Windows\System32\dism.exe.

The script itself flows something like this:
- Parses out the dism command line parameters that are passed.
- Gets the path to the drivers.xml file.
- Gets the (actual) driver path from the drivers.xml using XMLDOM COM object
  - Note: There's also logic in the script for regex matching (commented out) to get the driver path out of the drivers.xml file but I chose XMLDOM just in case the drivers.xml file isn't always formatted properly.
- Modifies the dism command line to use /Add-Driver /Driver:
- And most importantly adds a /Recurse to the command to resolve the issue documented in the blog post.
