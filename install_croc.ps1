# Variables
$downloadUrl = "https://api.github.com/repos/kasullian/croc/releases/latest"
$installDir = "C:\croc"
$zipFile = "$installDir\croc.zip"
$crocExe = "$installDir\croc.exe"
$contextMenuRegFile = "$installDir\add_context_menu.reg"
$protocolHandlerRegFile = "$installDir\add_protocol_handler.reg"
$downloadFolder = [System.Environment]::GetFolderPath('UserProfile') + "\Downloads"

# Function to create installation directory
function Create-InstallDir {
    if (Test-Path -Path $installDir) {
        Write-Host "Removing existing installation directory..."
        Remove-Item -Path $installDir -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path $installDir
}

# Function to download the latest croc release
function Download-LatestCroc {
    Write-Host "Fetching the latest croc release..."
    $releaseInfo = Invoke-RestMethod -Uri $downloadUrl -Headers @{"User-Agent"="PowerShell"}
    $zipUrl = $releaseInfo.assets | Where-Object { $_.name -like "*windows-64bit.zip" } | Select-Object -ExpandProperty browser_download_url
    Write-Host "Downloading $zipUrl..."
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipFile
}

# Function to remove existing croc.exe if it exists
function Remove-ExistingCroc {
    if (Test-Path -Path $crocExe) {
        Write-Host "Removing existing croc.exe..."
        Remove-Item -Path $crocExe -Force
    }
}

# Function to extract the downloaded zip file
function Extract-Zip {
    Write-Host "Extracting croc.zip to $installDir..."
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipFile, $installDir)
}

# Function to create the context menu registry script
function Create-ContextMenuRegistryScript {
    $escapedCrocExe = $crocExe -replace '\\', '\\\\'
    $regContent = @"
Windows Registry Editor Version 5.00

[HKEY_CLASSES_ROOT\*\shell\OpenWithCroc]
@="Upload with Croc"

[HKEY_CLASSES_ROOT\*\shell\OpenWithCroc\command]
@="\"$escapedCrocExe\" send \"%1\""
"@

    Set-Content -Path $contextMenuRegFile -Value $regContent
}

# Function to create the protocol handler registry script
function Create-ProtocolHandlerRegistryScript {
    $escapedCrocExe = $crocExe -replace '\\', '\\\\'
    $escapedDownloadFolder = $downloadFolder -replace '\\', '\\\\'
    $protocolRegContent = @"
Windows Registry Editor Version 5.00

[HKEY_CLASSES_ROOT\croc]
@="URL:Croc Protocol"
"URL Protocol"=""

[HKEY_CLASSES_ROOT\croc\shell]

[HKEY_CLASSES_ROOT\croc\shell\open]

[HKEY_CLASSES_ROOT\croc\shell\open\command]
@="\"$escapedCrocExe\" --yes --out \"$escapedDownloadFolder\" \"%1\""
"@

    Set-Content -Path $protocolHandlerRegFile -Value $protocolRegContent
}

# Function to add the context menu entry
function Add-ContextMenu {
    Write-Host "Adding context menu entry..."
    & reg import $contextMenuRegFile
}

# Function to add the protocol handler entry
function Add-ProtocolHandler {
    Write-Host "Adding protocol handler entry..."
    & reg import $protocolHandlerRegFile
}

# Function to clean up installation files
function Cleanup {
    Write-Host "Cleaning up installation files..."
    Remove-Item -Path $zipFile -Force
    Remove-Item -Path $contextMenuRegFile -Force
    Remove-Item -Path $protocolHandlerRegFile -Force
}

# Main script execution
Create-InstallDir
Download-LatestCroc
Remove-ExistingCroc
Extract-Zip
Create-ContextMenuRegistryScript
Create-ProtocolHandlerRegistryScript
Add-ContextMenu
Add-ProtocolHandler
Cleanup

Write-Host "Installation complete. Croc has been installed to $installDir, the context menu entry has been added, and the croc:// protocol handler has been registered."
