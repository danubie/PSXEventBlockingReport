function Write-ResultExcel {
# internal function to create excel content (not exported)
    [CmdletBinding()]
    param (
        $Path,
        $sheetName,
        $eventlist
    )
    $xl = $eventlist |
        Select-Object MonitorLoop,
                    TimeStamp,
                    @{name = 'DurationSec'; expression = { $_.BlockingData.DurationSec } },
                    DatabaseName,
                    TransactionId,
                    @{name = 'B-LoginName'; expression = { $_.BlockingProcess.Loginname } } ,
                    @{name = 'B-App'; expression = { $_.BlockingProcess.Clientapp } } ,
                    @{name = 'B-InputBuf'; expression = { $_.BlockingProcess.InputBuf } } ,
                    @{name = 'B-SpId'; expression = { $_.BlockingProcess.SpId } } ,
                    @{name = 'B-HostName'; expression = { $_.BlockingProcess.HostName } } ,
                    @{name = 'B-HostPid'; expression = { $_.BlockingProcess.HostPid } } ,
                    @{name = 'V-LoginName'; expression = { $_.BlockedProcess.Loginname } } ,
                    @{name = 'V-App'; expression = { $_.BlockedProcess.Clientapp } },
                    @{name = 'V-InputBuf'; expression = { $_.BlockedProcess.InputBuf } },
                    @{name = 'V-SpId'; expression = { $_.BlockedProcess.SpId } },
                    @{name = 'V-HostName'; expression = { $_.BlockedProcess.HostName } } ,
                    @{name = 'V-HostPid'; expression = { $_.BlockedProcess.HostPid } } ,
                    @{name = 'First seen'; expression = { $_.BlockingData.FirstSeen } } ,
                    @{name = 'Last seen'; expression = { $_.BlockingData.LastSeen } } |
            Sort-Object MonitorLoop |
            export-excel -Path $Path -WorksheetName $sheetName -ClearSheet -AutoSize -AutoFilter -FreezeTopRow -BoldTopRow -PassThru
    Set-Column -Worksheet $xl.Workbook.Worksheets[$SheetName] -Column 2 -NumberFormat "hh:mm:ss" -AutoSize
    Set-Column -Worksheet $xl.Workbook.Worksheets[$sheetName] -Column 3 -NumberFormat "0" -Width 8
    Set-Column -Worksheet $xl.Workbook.Worksheets[$sheetName] -Column  6 -Width 25                      # B-LoginName (Blocker)
    Set-Column -Worksheet $xl.Workbook.Worksheets[$sheetName] -Column  7 -Width 25                      # B-App
    Set-Column -Worksheet $xl.Workbook.Worksheets[$sheetName] -Column  8 -Width 40                      # B-Inputbuf
    Set-Column -Worksheet $xl.Workbook.Worksheets[$sheetName] -Column 12 -Width 25                      # V-LoginName (Victim)
    Set-Column -Worksheet $xl.Workbook.Worksheets[$sheetName] -Column 13 -Width 25                      # V-App
    Set-Column -Worksheet $xl.Workbook.Worksheets[$sheetName] -Column 14 -Width 40                      # V-Inputbuf
    Close-ExcelPackage -ExcelPackage $xl
}

function Export-PSXEventBlockingReport {
<#
.SYNOPSIS
Exports XEvent records to an Excel file

.DESCRIPTION
This function reads XEvent records of the style "DbTools XEvent Template Blocking Process Report".
Depending on the setting of SQL instances "Blocking Report Threshold" there can be more than one reported event showing the same blocking process.
The output collects subsequent events reporting the same process (of one transaction_id) into one result row ("consolidate events").
Finally it contains the starttime of such a case and its duration till the time it was last seen in a report as well as some data of the detailed process report XML.
The resulting xlsx-File can be based on a template ("example") File where the results are populated in.

.PARAMETER BlockingEvent
The event originally coming from the "Blocked Process Report"

.PARAMETER Path
Filepath for the resulting xlsx.
If the file exists, the worksheet(s) will be filled with the current report

.PARAMETER SheetName
Name of the Worksheet to be used

.PARAMETER TemplateXlsx
If a new result file is to be created, this file should be used as a template.

.PARAMETER ExcludeOriginal
If this switch is set, the plain reported events are not populated

.PARAMETER ExcludeParsedEvents
If this switch is set, no "combinded events" are analyzed or populated.

.EXAMPLE
Get-DbaXeSession -Session 'Blocked Process Report' | Read-DbaXEventFile | Export-PSXEventBlockingReport -Path $PathExcelFile
Reading the events collected by the, analyze it, consolidates processes reported in several consecutive events and outputs to Excel.
If the Excel-file already exists, it will be updated. If it does not exist, it will be created.

.EXAMPLE
Get-DbaXeSession -Session 'Blocked Process Report' | Read-DbaXEventFile | Export-PSXEventBlockingReport -Path $PathExcelFile -Template $PathToTemplateXlsx
Creating a consolidated processes report and uses an example Xlsx as "template" for the final report (only if the $PathExcelFile does not exist)

.NOTES
General notes
#>
    [CmdletBinding()]
    param (
        # Blocking Event Object
        [Parameter(ValueFromPipeline)]
        [Object]
        $BlockingEvent,
        # Path to the resulting Export-Excel
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,
        [string]
        $SheetName = 'Blocking list',
        # Path to the xlsx to be used if original file does not exist
        [string]
        $TemplateXlsx,
        # Should we exclude the original event list?
        [switch]
        $ExcludeOriginal,
        # Shouldn't we analyze the process loops?
        [switch]
        $ExcludeParsedEvents,
        [string]
        $SqlInstance
    )

    begin {
        if (!(Test-Path -Path $Path)) {
            if ($TemplateXlsx) {
                Assert-IsaPathExists -Path $TemplateXlsx
                Copy-Item -Path $TemplateXlsx -Destination $Path -ErrorAction Stop
            }
        }
        $store = @()
    }

    process {
        foreach ($o in $BlockingEvent) {
            $store += $o
        }
    }

    end {

        if (!($ExcludeParsedEvents)) {
            $result = $store | Select-PSXEventBlockingChain -SqlInstance $SqlInstance
            Write-ResultExcel -Path $Path -sheetName $SheetName -eventlist $result
        }
        if (!($ExcludeOriginal)) {
            $result = $store | ConvertTo-PSXEventBlockingReportObject -SqlInstance $SqlInstance
            Write-ResultExcel -Path $Path -sheetName 'base data' -eventlist $result
        }
    }
}
