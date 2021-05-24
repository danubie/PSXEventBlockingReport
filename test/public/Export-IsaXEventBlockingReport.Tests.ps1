BeforeAll {
    Import-Module $PSScriptRoot\..\..\src\PSXEventBlockingReport.psd1 -Force -ErrorAction Stop
}

Describe "First one" {
    BeforeAll {
        $PathJson2Events = "$PSScriptRoot\..\Data\Testdata-BlockingReport2Events.json"
        $PathJsonAllEvents = "$PSScriptRoot\..\Data\Testdata-BlockingReport.json"
        $PathExcelFile = "$PSScriptRoot\..\Data\Result.xlsx"
        $PathTemplateFile = "$PSScriptRoot\..\Data\Blocking_Template.xlsx"
        $SheetBasedata = "Base data"
        $SheetGroupedData = "Blocking list"
    }
    It "Export new file from 2 Events" {
        # Testfile contains 2 blocking report events blocker: spid65, victim spid68
        Remove-Item -Path $PathExcelFile -ErrorAction SilentlyContinue

        $content = Get-Content -Path $PathJson2Events | ConvertFrom-Json
        $content | Export-PSXEventBlockingReport -Path $PathExcelFile

        $resultBaseData = Import-Excel -Path $PathExcelFile -WorksheetName $SheetBasedata
        $resultBaseData | Should -HaveCount 2

        $resultGroupedData = Import-Excel -Path $PathExcelFile -WorksheetName $SheetGroupedData
        $resultGroupedData | Should -HaveCount 1
        $resultGroupedData.FirstSeen | Should -Be $resultBaseData[0].FirstSeen
        $resultGroupedData.LastSeen | Should -Be $resultBaseData[1].FirstSeen
    }
    It "Export from Templatefile" -Skip {
        Export-PSXEventBlockingReport -Path $PathExcelFile -JsonFilePath $PathJsonAllEvents -TemplateXlsx $PathTemplateFile
    }
}
