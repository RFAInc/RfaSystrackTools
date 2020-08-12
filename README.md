# RfaSystrackTools
A digital experience monitoring solution that reduces IT costs and improves end-user experience. https://www.lakesidesoftware.com

## How to Run scripts in this module
Paste the following like into a PowerShell window to retrieve the status of the installation
```
( new-object Net.WebClient ).DownloadString( 'https://raw.githubusercontent.com/RFAInc/RfaSystrackTools/master/RfaSystrackTools.psm1' ) | iex; Test-SystrackInstall
```
Will return True or False boolean. Add the -Verbose parameter for reason for False result, or add a path to any filename in an existing folder to put this verbose message to a file for later retrieval. 

## How do I Install SysTrack?
RFA uses CW Automate to install the packages.
