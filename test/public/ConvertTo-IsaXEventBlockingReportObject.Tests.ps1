BeforeAll {
    Import-Module $PSScriptRoot\..\..\src\PSXEventBlockingReport.psd1 -Force
}

Describe "ConvertTo-PSXEventBlockingReportObject" {
    Context "Default" {
        It "Read frist test event" {
            $PathJson2Events = "$PSScriptRoot\..\Data\Testdata-BlockingReport2Events.json"
            $BprEvent = Get-Content -Path $PathJson2Events -Raw | ConvertFrom-Json | Select-Object -First 1
            $result = $BprEvent | ConvertTo-PSXEventBlockingReportObject
            $result | Should -HaveCount 2
            $result.DatabaseName[0] | Should -Be 'Database1'
            $result.DatabaseName[0] | Should -Be 'Database1'
            $result.BlockedProcess.spid[0] | Should -Be 65
            $result.BlockingProcess.spid[0] | Should -Be 68
        }
    }
}