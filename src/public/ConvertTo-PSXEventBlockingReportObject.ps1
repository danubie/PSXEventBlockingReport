function ConvertTo-PSXEventBlockingReportObject {
<#
.SYNOPSIS
Converts a XEvent blocking report into a PSCustomObject

.DESCRIPTION
An object of stlye DbaTools 'Blocking Process Report' XEvent Template is converted into a PSCustumObject.
The XML structure describing the blocking an the blocked event are converted into objects as well

.PARAMETER BlockedReportEvent
Object containing an blocked process report

.EXAMPLE
Get-DbaXESession -SqlInstance $instance -Session 'Blocked Process Report' | ConvertTo-PSXEventBlockingReportObject

.NOTES
General notes
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [object] $BlockedReportEvent,
        [Parameter()]
        [string] $SqlInstance
    )

    begin {
        $Script:procCache = @{}
    }

    process {
        function GetSpName {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory)]
                [string]
                $SqlInstance,
                [string]
                $InputBuf
            )
            Write-PSFMessage -Level Debug -Message "Inputbuf = [$InputBuf]"
            if ( $null -eq $InputBuf -or '' -eq $InputBuf) {
                Write-PSFMessage -Level Debug "Inputbuf is null -o empty"
            } else {
                if ( $null -ne $SqlInstance -and $InputBuf -match '.*Proc \[Database Id = ([0-9]+) Object Id = ([0-9]+).*') {
                    $key = "$($Matches[1])/$($Matches[2])"
                    if ($Script:procCache.ContainsKey($key)) {
                        $Script:procCache[$key]     #     return name of the SP
                    } else {
                        $Query = "select object_name('$($Matches[2])', $($Matches[1]) ) as SPName"
                        Write-PSFMessage -Level Verbose -Message "Query = [$Query]"
                        $result = Invoke-DbaQuery -SqlInstance $SqlInstance -Query $Query
                        if ( ($null -ne $result[0]) -and ('' -ne $result[0]) ) {
                            Write-PSFMessage "returned SP = $($result[0]); key=$key"
                            $Script:procCache[$key] = $result[0]
                            $Script:procCache[$key]     #     return name of the SP
                        } else {
                            $InputBuf
                        }
                    }
                } else {
                    $InputBuf                   # return original statement
                }
            }
        }

        Write-PSFMessage -Level Debug "RawString[$($BlockedReportEvent.blocked_process.RawString)]"
        [System.Xml.XmlDocument] $Detail = $BlockedReportEvent.blocked_process.RawString
        if ( $Detail.ChildNodes.Count -gt 1 ) {
            Write-PSFMessage -Level Warning "Not prepared for more than 1 childnode"
        }
        $EventDetailed = [PSCustomObject]@{
            'DatabaseName'    = $BlockedReportEvent.database_name
            'Timestamp'       = $BlockedReportEvent.timestamp
            'DurationSec'     = $BlockedReportEvent.duration / 1000000
            'TransactionId'   = $BlockedReportEvent.transaction_id
            'MonitorLoop'     = $Detail.ChildNodes[0].monitorLoop
            'BlockingProcess' = [pscustomobject] @{
                'SpId'        = $Detail.ChildNodes[0].'blocking-process'.process.spid
                'Loginname'   = $Detail.ChildNodes[0].'blocking-process'.process.loginname
                'XActId'      = $Detail.ChildNodes[0].'blocking-process'.process.xactid
                'InputBuf'    = $Detail.ChildNodes[0].'blocking-process'.process.inputbuf
                'Hostname'    = $Detail.ChildNodes[0].'blocking-process'.process.Hostname
                'HostPid'     = $Detail.ChildNodes[0].'blocking-process'.process.hostpid
                'CurrentDb'   = $Detail.ChildNodes[0].'blocking-process'.process.CurrentDb
                'LockTimeout' = $Detail.ChildNodes[0].'blocking-process'.process.LockTimeout
                'Clientapp'   = $Detail.ChildNodes[0].'blocking-process'.process.clientapp
            }
            'BlockedProcess'  = [pscustomobject] @{
                'SpId'        = $Detail.ChildNodes[0].'blocked-process'.process.spid
                'Loginname'   = $Detail.ChildNodes[0].'blocked-process'.process.loginname
                'XActId'      = $Detail.ChildNodes[0].'blocked-process'.process.xactid
                'InputBuf'    = $Detail.ChildNodes[0].'blocked-process'.process.inputbuf
                'Hostname'    = $Detail.ChildNodes[0].'blocked-process'.process.Hostname
                'HostPid'     = $Detail.ChildNodes[0].'blocked-process'.process.hostpid
                'CurrentDb'   = $Detail.ChildNodes[0].'blocked-process'.process.CurrentDb
                'LockTimeout' = $Detail.ChildNodes[0].'blocked-process'.process.LockTimeout
                'Clientapp'   = $Detail.ChildNodes[0].'blocked-process'.process.clientapp

            }
        }
        # try to extract name of stored procedure
        if ( $null -ne $SqlInstance -and '' -ne $SqlInstance ) {
            $EventDetailed.BlockingProcess.InputBuf = GetSpName -SqlInstance $SqlInstance -InputBuf $EventDetailed.BlockingProcess.InputBuf
            $EventDetailed.BlockedProcess.InputBuf = GetSpName -SqlInstance $SqlInstance -InputBuf $EventDetailed.BlockedProcess.InputBuf
        }
        $EventDetailed
    }
}
