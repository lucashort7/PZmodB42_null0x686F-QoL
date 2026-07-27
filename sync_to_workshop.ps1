# Sync script: local repo -> Zomboid Workshop test folder
# Run this after any code change to test in-game.

$SourcePath = "C:\obsidian\pz-mods-byme\qol"
$DestPath = "C:\Users\lucas\Zomboid\Workshop\qol"

Write-Host "Syncing null0x686F QoL..." -ForegroundColor Cyan
Write-Host "Source: $SourcePath"
Write-Host "Dest:   $DestPath"
Write-Host "--------------------------------------------------"

robocopy "$SourcePath" "$DestPath" /MIR /XD .git /NFL /NDL

if ($LASTEXITCODE -lt 8) {
    Write-Host "Sync complete." -ForegroundColor Green
} else {
    Write-Host "Warning: errors during copy. (Robocopy Exit Code: $LASTEXITCODE)" -ForegroundColor Red
}

if (-not [Console]::IsInputRedirected) {
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}
