<#
.SYNOPSIS
Checks the minimum configuration for blocked process xevents

.DESCRIPTION
Checks the minimum configuration for blocked process xevents

.PARAMETER SqlInstance
Needs a DbaTools connected instance object

.PARAMETER Session
Name which is used to identify the blocked process report (Default: Blocked_Process_Report)

.EXAMPLE
$sql = Connect-DbaInstance -SqlInstance 'localhost'; Get-PSXEventConfiguration -SqlInstance $sql

.NOTES
General notes
#>
function Get-PSXEventBlockingReportConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [Object] $SqlInstance,
        [Parameter()]
        [string] $SessionName = 'Blocked_Process_Report'
    )

    begin {

    }

    process {
        Try {
            $Result = @{
                SqlInstance = $SqlInstance
                Installed = $false
                Running = $false
                BlockedProcessThreshold = 0
            }
            # check if XEvent Blocking Report is installed and enabled
            $xevent = Get-DbaXESession -SqlInstance $SqlInstance | Where-Object { $_.name -eq $SessionName }
            if ( $xevent ) {
                $Result.Installed = $true
                $Result.Running = ($xevent.Status -eq 'Running')
            }
            # check blocked process threshold set
            $ConfigBlockedProcessThreshold = Get-DbaSpConfigure -SqlInstance $SqlInstance -Name BlockedProcessThreshold
            $Result.BlockedProcessThreshold = $ConfigBlockedProcessThreshold.ConfiguredValue
            [PSCustomObject] $Result
        }
        Catch {
            Throw $_
        }
    }

    end {

    }
}