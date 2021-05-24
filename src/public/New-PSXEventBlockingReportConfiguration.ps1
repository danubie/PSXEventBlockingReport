<#
.SYNOPSIS
Sets up configuration for blocked process xevents

.DESCRIPTION
If not already done, registers XEvent and sets blocked process threshold.

.PARAMETER SqlInstance
Needs a DbaTools connected instance object.

.PARAMETER EventName
Name of the XEvent (Default: Blocked_Process_Report)

.PARAMETER Threshold
Number of seconds for the blocked process threshold. This is only set, when the current configured value is 0.
So if there is already a configured value, it will not be changed

.EXAMPLE
New-PSXEventBlockingReportConfiguration -SqlInstance $SqlInstance -Threshold 10

.RETURNS
Status of the XEvent after setup

.NOTES
General notes
#>
function New-PSXEventBlockingReportConfiguration {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory=$true)]
        [Object] $SqlInstance,
        [Parameter()]
        [string] $EventName = 'Blocked_Process_Report',
        [Parameter()]
        [int] $Threshold = 10
    )

    begin {

    }

    process {
        Try {
            $Status = Get-PSXEventBlockingReportConfiguration -SqlInstance $SqlInstance -EventName $EventName
            # check if XEvent Blocking Report is installed and enabled
            if (!$Status.Installed) {
                # Import-DbaXESessionTemplate does not support -Whatif as of writing
                if ($PSCmdlet.ShouldProcess($SqlInstance, "Importing XeSessionTemplate 'Blocked Process Report'")) {
                    Write-Information "Importing Blocked Process Report template to $EventName"
                    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("UseDeclaredVarsMoreThanAssignments","",Target="*")]
                    $XEvent = Import-DbaXESessionTemplate -SqlInstance $SqlInstance -Name $EventName -Template 'Blocked Process Report'
                }
            }
            if ($Status.BlockedProcessThreshold -eq 0) {
                Write-Information "Setting SpConfigure BlockedProcessThreshold to $Threshold"
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute("UseDeclaredVarsMoreThanAssignments","",Target="*")]
                $SpConfigBPT = Set-DbaSpConfigure -SqlInstance $SqlInstance -Name BlockedProcessThreshold -Value $Threshold -WhatIf:$WhatIfPreference
            }
            # return current config
            Get-PSXEventBlockingReportConfiguration -SqlInstance $SqlInstance -EventName $EventName
        }
        Catch {
            Throw $_
        }
    }

    end {

    }
}