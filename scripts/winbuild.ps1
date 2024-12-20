# Love2D Game Build Script
# Save this as winbuild.ps1

# Configuration
$GameName = "mygame"  # Change this to your game name
$LovePath = "C:\Program Files\LOVE"  # Change this to your Love2D installation path

# Create output directories
$BuildDir = Join-Path $PSScriptRoot "build"
$ReleaseDir = Join-Path $BuildDir $GameName
New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null
New-Item -ItemType Directory -Force -Path $ReleaseDir | Out-Null

# Create .love file
Write-Host "Creating .love file..." -ForegroundColor Green
$TempZip = Join-Path $BuildDir "temp.zip"
$LoveFile = Join-Path $BuildDir "$GameName.love"

# Move up one directory to get the game files
$GameDir = Split-Path $PSScriptRoot -Parent

# Get game files from parent directory
Push-Location $GameDir
Get-ChildItem -Path "." -Exclude "build", ".git", ".vscode", "scripts" | 
    Compress-Archive -DestinationPath $TempZip -Force
Pop-Location

# Rename zip to love file
if (Test-Path $LoveFile) {
    Remove-Item $LoveFile -Force
}
Move-Item -Path $TempZip -Destination $LoveFile -Force

# Combine with Love2D executable
Write-Host "Creating executable..." -ForegroundColor Green
$LoveExe = Join-Path $LovePath "love.exe"
if (Test-Path $LoveExe) {
    # Combine files into single executable
    $GameExe = Join-Path $ReleaseDir "$GameName.exe"
    cmd /c copy /b "`"$LoveExe`"+`"$LoveFile`"" "`"$GameExe`""
    
    # Copy required DLLs
    $DLLs = @(
        "love.dll",
        "lua51.dll",
        "mpg123.dll",
        "OpenAL32.dll",
        "SDL2.dll",
        "msvcp120.dll",
        "msvcr120.dll"
    )
    
    foreach ($dll in $DLLs) {
        $dllPath = Join-Path $LovePath $dll
        if (Test-Path $dllPath) {
            Copy-Item $dllPath -Destination $ReleaseDir
        } else {
            Write-Host "Warning: Could not find $dll" -ForegroundColor Yellow
        }
    }
    
    # Create ZIP archive of release
    $ZipFile = Join-Path $BuildDir "$GameName-windows.zip"
    Compress-Archive -Path (Join-Path $ReleaseDir "*") -DestinationPath $ZipFile -Force
    
    Write-Host "`nBuild completed successfully!" -ForegroundColor Green
    Write-Host "Executable: $GameExe"
    Write-Host "ZIP archive: $ZipFile"
} else {
    Write-Host "Error: Could not find Love2D installation at $LovePath" -ForegroundColor Red
    Write-Host "Please update the `$LovePath variable in the script." -ForegroundColor Red
}

# Cleanup
if (Test-Path $LoveFile) {
    Remove-Item $LoveFile -Force
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")