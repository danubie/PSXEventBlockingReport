$private = Get-ChildItem (Join-Path $PSScriptRoot "Private") -Recurse -Filter '*.ps1'
$public = Get-ChildItem (Join-Path $PSScriptRoot "Public") -Recurse -Filter '*.ps1'
foreach ($function in $private) {
    . $function.FullName
    Write-Verbose "private: $($function.FullName)"
}
foreach ($function in $public) {
    . $function.FullName
    Write-Verbose "public: $($function.FullName)"
}

Write-Verbose "Exporting $($public.BaseName)"
Export-ModuleMember -Function $public.BaseName