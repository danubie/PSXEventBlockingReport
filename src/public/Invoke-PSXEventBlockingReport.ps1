function Invoke-PSXEventBlockingReport {
    [CmdletBinding()]
    param (
        [string] $SqlInstance,
        [string] $SessionName = 'Blocked_Process_Report',
        [string] $PathToTemplateXlsx
    )

    begin {

    }

    process {
        Try {

            $SqlSession = Connect-DbaInstance -SqlInstance $SqlInstance

            $DomainInstanceName = $SqlSession.DomainInstanceName -replace '\\', '_'
            $PathExportFolder = "$($env:USERPROFILE)\Documents\BlockedProcessReports"
            Assert-IsaPathExists -Path $PathExportFolder -ItemType Directory -Create
            $ReportXlsName = "$PathExportFolder\$($DomainInstanceName)_$(Get-Date -Format 'yyyy-MM-dd').xlsx"

            $XESession = Get-DbaXESession -SqlInstance $SqlInstance -Session $SessionName -EnableException
            # sanity check : session known? session file exists?
            if (!$XESession) {
                Throw "No XEvent session $SessionName found"
            }
            $FilesXel = Get-ChildItem -Path (Split-Path ($XESession.TargetFile) -Parent) -Filter "$(Split-Path ($XESession.TargetFile) -Leaf)*.xel" -ErrorAction SilentlyContinue
            if (!$FilesXel) {
                Throw "No XEvent XEL files for $SessionName found (are you on a different machine?"
            }
            $NewestFile = $FilesXel | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1

            $exportParams = @{
                Path        = $ReportXlsName
                SqlInstance = $SqlInstance
            }
            if ($PathToTemplateXlsx) {
                Assert-IsaPathExists -Path $PathToTemplateXlsx -ItemType File
                $exportParams.Add("TemplateXlsx","$PathExportFolder\Blocking_Template.xlsx")
            }
            Read-DbaXEFile -Path $NewestFile |
                Export-PSXEventBlockingReport @exportParams
        }
        Catch {
            Throw $_
        }
    }

    end {

    }
}

