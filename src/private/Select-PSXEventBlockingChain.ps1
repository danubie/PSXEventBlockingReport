function Select-PSXEventBlockingChain {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [Object]
        $BlockingEventReport,
        [Object]
        $SqlInstance
    )
    begin {
        Write-PSFMessage -Level Verbose -Message "Finding all blocking processes"
        [hashtable] $Script:allBlockers = @{}
    }

    process {
        foreach ($brEvent in $BlockingEventReport) {
            # is this a known blocker?
            $event = ConvertTo-PSXEventBlockingReportObject -BlockedReportEvent $brEvent -SqlInstance $SqlInstance
            $key = "$($event.DatabaseName)/$($event.TransactionId)"
            if ( $Script:allBlockers.ContainsKey($key) ) {
                $updatedBlocker = $Script:allBlockers[$key]
                $updatedBlocker.BlockingData.LastSeen = $event.Timestamp
                $updatedBlocker.BlockingData.DurationSec = $event.DurationSec
                Write-PSFMessage -Level Debug -Message "Update blocker data $updateBlocker"
                $Script:allBlockers[$key] = $updatedBlocker
            } else {
                Write-PSFMessage -Level Debug -Message "New blocker $event"
                $BlockingData = [PSCustomObject]@{
                    FirstSeen   = $event.Timestamp
                    LastSeen   = $event.Timestamp
                    DurationSec = $event.DurationSec
                }
                Add-Member -InputObject $event -MemberType NoteProperty -Name 'BlockingData' -Value $BlockingData
                $Script:allBlockers.Add($key, $event )
            }
        }
    }
    end {
        $Script:allBlockers.foreach({ Write-PSFMessage -Level Debug -Message "Block: $_" })
        $Script:allBlockers.GetEnumerator() | ForEach-Object { $_.Value }
    }
}