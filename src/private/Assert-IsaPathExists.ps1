<#
.SYNOPSIS
Assert-IsaPathExists

.DESCRIPTION
Assures that a file / directory exists

.PARAMETER Path
Path to File or Directory

.PARAMETER LiteralPath
LiteralPath to File or Directory

.PARAMETER ItemType
Type of the object (file, Directory)

.PARAMETER Create
Create the object if it does not exist. Default: throw an error

.EXAMPLE
Assert-IsaPathExists 'C:\Temp\blabla.dir' -ItemType Directory

Check if directory C:\Temp\blabla.dir exists, therewise throw

.EXAMPLE
Assert-IsaPathExists 'C:\Temp\blabla.txt' -ItemType File -Create

If file C:\Temp\blabla.txt does not exist it will be created

.NOTES
General notes
#>
function Assert-IsaPathExists {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName,Position=0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]
        $LiteralPath,
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [ValidateSet('Directory','File')]
        [string]
        $ItemType = 'Directory',
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [switch]
        $Create
    )
    if ( !(Test-Path($Path) ) ){
        if ( $Create ) {
            $splat = $PSBoundParameters
            $splat.Remove('Create')          # Throw is "our own" parameter
            $null = New-Item @splat
        } else {
            Write-PSFMessage -Level Error -Message "Could not create ($Path)"
            Throw [System.Management.Automation.ItemNotFoundException]
        }
    }
}