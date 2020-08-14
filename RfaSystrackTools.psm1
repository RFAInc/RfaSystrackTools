#v0.0.1.1

function Test-SysTrackInstalled {
    <#
    .SYNOPSIS
    Check to see if SysTrack and its prerequisites are installed and up-to-date. 
    .DESCRIPTION
    Check the local system to see if SysTrack and its prerequisites are installed and the versions meet known minimums for RFA. 
    .PARAMETER OutFile
    Writes verbose output to file for later retrieval
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
        $OutFile
    )

    Begin {
        # Define the default boolean value as true
        # If any of 3 items presents a problem, change to false
        $SysTrackInstalled = $true

        # Initialize an Output Message for the verbose stream
        [string[]]$Message = $null

        # Define the requirements for versions on the 2 prerequsite packages
        # Define the URL to the version files
        $web = New-Object Net.WebClient
        $uriSysTrackParent = 'https://automate.rfa.com/LabTech/Transfer/Software/SysTrack Cloud Agent'
        [version]$vcRedist64VersionShouldBe = $web.DownloadString(("$($uriSysTrackParent)/prereq64version.txt")).Trim()
        [version]$vcRedist86VersionShouldBe = $web.DownloadString(("$($uriSysTrackParent)/prereq64version.txt")).Trim()
        [version]$SysTrackVersionShouldBe = $web.DownloadString(("$($uriSysTrackParent)/prereq64version.txt")).Trim()


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
            $Message += "Microsoft Visual C++ Redistributable (x64) not detected on $($env:COMPUTERNAME)"
            $SysTrackInstalled = $false
        } elseif (($vcRedist64Info.Version -as [version]) -lt $vcRedist64VersionShouldBe) {
            $Message += "Microsoft Visual C++ Redistributable (x64) version $($vcRedist64VersionShouldBe) or higher not detected on $($env:COMPUTERNAME)"
            $SysTrackInstalled = $false
        }

        if ( -not $vcRedist86Info) {
            $Message += "Microsoft Visual C++ Redistributable (x86) not detected on $($env:COMPUTERNAME)"
            $SysTrackInstalled = $false
        } elseif (($vcRedist86Info.Version -as [version]) -lt $vcRedist86VersionShouldBe) {
            $Message += "Microsoft Visual C++ Redistributable (x86) version $($vcRedist86VersionShouldBe) or higher not detected on $($env:COMPUTERNAME)"
            $SysTrackInstalled = $false
        }

        if ( -not $SysTrackInfo) {
            $Message += "Systems Management Agent (SysTrack) not detected on $($env:COMPUTERNAME)"
            $SysTrackInstalled = $false
        } elseif (($SysTrackInfo.Version -as [version]) -lt $SysTrackVersionShouldBe) {
            $Message += "Systems Management Agent (SysTrack) version $($SysTrackVersionShouldBe) or higher not detected on $($env:COMPUTERNAME)"
            $SysTrackInstalled = $false
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



# Load external functions
$URLs = @(
    'https://raw.githubusercontent.com/tonypags/PsWinAdmin/master/Get-InstalledSoftware.ps1'
)
$web = New-Object Net.WebClient
Foreach ($URL in $URLs) {
    Invoke-Expression [string]($web.DownloadString( $URL ))
}
$web.Dispose()
