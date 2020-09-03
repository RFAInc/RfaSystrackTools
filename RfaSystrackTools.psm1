#v0.1.0.5

function Test-SysTrackInstalled {
    <#
    .SYNOPSIS
    Check to see if SysTrack and its prerequisites are installed and up-to-date. 
    .DESCRIPTION
    Check the local system to see if SysTrack and its prerequisites are installed and the versions meet known minimums for RFA. 
    .PARAMETER OutFile
    Writes verbose output to file for later retrieval
    .PARAMETER SystrackVersionUri
    URL for the TXT files that contains the deployed version number. Default value populated by CW Automate replacements.
    .INPUTS
    This function doesn't require input, but a log path can be specified if desired.
    .OUTPUTS
    Returns a simple [boolean] value where true means requirements have been met and false means some requirement failed.
    .NOTES
    A digital experience monitoring solution that reduces IT costs and improves end-user experience. https://www.lakesidesoftware.com
    #>
    [CmdletBinding()]
    param(
        # (Over)writes verbose output to file for later retrieval
        [Parameter(Position=0)]
        [ValidateScript({Test-Path (Split-Path $_ -Parent)})]
        [string]
        $OutFile,
        
        # URL for the TXT files that contains the deployed version number. Default value populated by CW Automate replacements.
        [Parameter()]
        [string]
        $SystrackVersionUri = "https://automate.rfa.com/LabTech/Transfer/@SystrackVersionUri@"
    )

    Begin {
        # Define the default boolean value as true
        # If any of 3 items presents a problem, change to false
        $SysTrackInstalled = $true

        # Initialize an Output Message for the verbose stream
        [string[]]$Message = $null

        # Make sure the URL doesn't have raw replacement string from Automate
        if ($SystrackVersionUri -like '@') {
            throw "Invalid URL: [$($SystrackVersionUri)]"
        } else {
		    Write-Verbose "SystrackVersionUri: [$($SystrackVersionUri)]" -Verbose
		}
        
        # Define the requirements for versions on the 2 prerequsite packages
        # Define the URL to the version files
        $web = New-Object Net.WebClient
        $uriSysTrackParent = 'https://automate.rfa.com/LabTech/Transfer/Software/SysTrack Cloud Agent'
        [version]$vcRedist64VersionShouldBe = $web.DownloadString(("$($uriSysTrackParent)/prereq64version.txt")).Trim()
        [version]$vcRedist86VersionShouldBe = $web.DownloadString(("$($uriSysTrackParent)/prereq86version.txt")).Trim()
        [version]$SysTrackVersionShouldBe = $web.DownloadString($SystrackVersionUri).Trim()


        # Pull in info related to the 3 packages we need to check
        $allSoftware = Get-InstalledSoftware
        $vcRedist64Info = $allSoftware |
            Where-Object {
                ($_.Name -like '*visual c++*redist*x64*' -or
                $_.Name -like '*visual c++*x64*redist*') -and
                $_.Name -notlike '*visual c++*x86*'
            } |
            Sort-Object @{expr={[version]($_.Version)};Descending=$true} |
            Select-Object -First 1

        $vcRedist86Info = $allSoftware |
            Where-Object {
                ($_.Name -like '*visual c++*redist*x86*' -or
                $_.Name -like '*visual c++*x86*redist*') -and
                $_.Name -notlike '*visual c++*x64*'
            } |
            Sort-Object @{expr={[version]($_.Version)};Descending=$true} |
            Select-Object -First 1
    
        $SysTrackInfo = $allSoftware |
            Where-Object {$_.Name -eq 'Systems Management Agent'}



        # Ensure all 3 apps are installed and meet version requirements
        if ( -not $vcRedist64Info) {
            $Message += "FAIL: Microsoft Visual C++ Redistributable (x64) not detected on $($env:COMPUTERNAME)"
            $SysTrackInstalled = $false
        } elseif (($vcRedist64Info.Version -as [version]) -lt $vcRedist64VersionShouldBe) {
            $Message += "FAIL: Microsoft Visual C++ Redistributable (x64) version $($vcRedist64VersionShouldBe) or higher not detected on $($env:COMPUTERNAME)"
            $SysTrackInstalled = $false
        } else {
            $Message += "OK: Microsoft Visual C++ Redistributable (x64) version $($vcRedist64Info.Version) is installed on $($env:COMPUTERNAME)"
        }

        if ( -not $vcRedist86Info) {
            $Message += "FAIL: Microsoft Visual C++ Redistributable (x86) not detected on $($env:COMPUTERNAME)"
            $SysTrackInstalled = $false
        } elseif (($vcRedist86Info.Version -as [version]) -lt $vcRedist86VersionShouldBe) {
            $Message += "FAIL: Microsoft Visual C++ Redistributable (x86) version $($vcRedist86VersionShouldBe) or higher not detected on $($env:COMPUTERNAME)"
            $SysTrackInstalled = $false
        } else {
            $Message += "OK: Microsoft Visual C++ Redistributable (x86) version $($vcRedist86Info.Version) is installed on $($env:COMPUTERNAME)"
        }

        if ( -not $SysTrackInfo) {
            $Message += "FAIL: Systems Management Agent (SysTrack) not detected on $($env:COMPUTERNAME)"
            $SysTrackInstalled = $false
        } elseif (($SysTrackInfo.Version -as [version]) -lt $SysTrackVersionShouldBe) {
            $Message += "FAIL: Systems Management Agent (SysTrack) version $($SysTrackVersionShouldBe) or higher not detected on $($env:COMPUTERNAME)"
            $SysTrackInstalled = $false
        } else {
            $Message += "OK: Systems Management Agent (SysTrack) version $($SysTrackInfo.Version) is installed on $($env:COMPUTERNAME)"
        }



    }

    Process {}

    End {

        Write-Output $SysTrackInstalled
        $Message | ForEach-Object {
            Write-Verbose -Message $_
        }

        if ($OutFile) {
            $Message | Out-File -FilePath $OutFile -Force | Out-Null
        }
        
        $web.Dispose()
    }

}#END function Test-SysTrackInstalled

function Uninstall-Systrack {
    <#
    .NOTES
    Quick uninstall, use at own risk.

    #>
    [CmdletBinding()]
    param (
        [switch]$KeepPrerequisiteRedist
    )
    
    begin {
        # Load external functions
        $URLs = @(
            'https://raw.githubusercontent.com/tonypags/PsWinAdmin/master/Get-InstalledSoftware.ps1'
            'https://raw.githubusercontent.com/tonypags/PsWinAdmin/master/Get-PendingReboot.ps1'
        )
        $web = New-Object Net.WebClient
        Foreach ($URL in $URLs) {
            Invoke-Expression ($web.DownloadString( $URL ))
            sleep 1
        }

        $preRebootStatus = Get-PendingReboot
    }
    
    process {
        
    }
    
    end {
        & msiexec.exe /qn /x "{5A10C299-1D99-4478-94F9-64C9DE93751D}" REBOOT=R 
        sleep 3

        if (!($KeepPrerequisiteRedist)) {
            & "C:\ProgramData\Package Cache\{282975d8-55fe-4991-bbbb-06a72581ce58}\VC_redist.x64.exe"  /uninstall /quiet /norestart
            sleep 2
            & "C:\ProgramData\Package Cache\{e31cb1a4-76b5-46a5-a084-3fa419e82201}\VC_redist.x86.exe"  /uninstall /quiet /norestart
            sleep 3
        }

        gps LsiSupervisor -ea 0 | stop-process -force -ea 0
        sleep 1

        del -force -recurse "C:\Windows\LtSvc\packages\SysTrack Cloud Agent\" -ea 0
        sleep 1

        del -force -recurse "C:\Program Files (x86)\SysTrack\" -ea 0
        sleep 2
        
        del -force -recurse "HKLM:\SOFTWARE\WOW6432Node\Lakeside Software\" -ea 0
        sleep 1

        $postRebootStatus = Get-PendingReboot

        'reboot status:'
        $postRebootStatus

        'changes in reboot status:'
        Compare $preRebootStatus $postRebootStatus |
            ?{$_.sideindicator -eq '=>'} |
            Select inputobject

        sleep 1
        Try{ & quser } Catch { ($_.Exception.Message) }

        $web.Dispose()
    }
}#END Uninstall-Systrack



# Load external functions
$URLs = @(
    'https://raw.githubusercontent.com/tonypags/PsWinAdmin/master/Get-InstalledSoftware.ps1'
)
$web = New-Object Net.WebClient
Foreach ($URL in $URLs) {
    Invoke-Expression ($web.DownloadString( $URL ))
}
$web.Dispose()
