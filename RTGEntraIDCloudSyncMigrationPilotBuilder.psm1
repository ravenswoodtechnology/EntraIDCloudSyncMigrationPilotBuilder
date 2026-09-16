# Find all script files
$Files = Get-ChildItem -Path $PSScriptRoot -File -Recurse -Filter "*.ps1"
$Files | ForEach-Object {
    Try {. $_.FullName }
    Catch { Write-Error -Message "Failed to import function $($_.FullName)" }
    }
Export-ModuleMember -Function $Files.BaseName