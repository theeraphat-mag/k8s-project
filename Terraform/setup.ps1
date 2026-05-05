<#
  setup.ps1
  - Installs Terraform for the current user by default.
  - If run as Administrator, installs to C:\tools\terraform.
  - Avoids special characters to prevent PowerShell parsing issues.
#>

param(
    [string]$Version = "1.15.1",
    [string]$InstallPathExplicit = ""
)

$ErrorActionPreference = 'Stop'

function Write-Info($m) { Write-Host $m }

# Determine install path: Admin -> C:\tools\terraform, otherwise -> %UserProfile%\tools\terraform
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
if ($InstallPathExplicit -ne '') {
    $InstallPath = $InstallPathExplicit
} elseif ($isAdmin) {
    $InstallPath = 'C:\tools\terraform'
} else {
    $InstallPath = Join-Path $env:USERPROFILE 'tools\terraform'
}

Write-Info "Installing Terraform $Version to: $InstallPath"

# Create install directory
New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null

# Download Terraform
$url = "https://releases.hashicorp.com/terraform/$Version/terraform_${Version}_windows_amd64.zip"
$zipPath = Join-Path $env:TEMP 'terraform.zip'

Write-Info "Downloading from $url ..."
Invoke-WebRequest -Uri $url -OutFile $zipPath

Write-Info "Extracting..."
Expand-Archive -Path $zipPath -DestinationPath $InstallPath -Force
Remove-Item $zipPath -Force

# Add install path to User PATH if not present
$currentUserPath = [Environment]::GetEnvironmentVariable('PATH', [EnvironmentVariableTarget]::User)
if ($currentUserPath -notlike "*${InstallPath}*") {
    $newUserPath = if ($currentUserPath -and $currentUserPath.Trim() -ne '') { "$currentUserPath;$InstallPath" } else { $InstallPath }
    [Environment]::SetEnvironmentVariable('PATH', $newUserPath, [EnvironmentVariableTarget]::User)
    Write-Info "Added $InstallPath to User PATH"
} else {
    Write-Info "Install path already in User PATH"
}

Write-Info "Installation complete."
Write-Info "Please close and reopen your terminal (or run: $env:ComSpec /k) to pick up PATH changes."

try {
    & "$InstallPath\terraform.exe" -version
} catch {
    Write-Info "Unable to run terraform from $InstallPath now. Please reopen terminal and run 'terraform -version'"
}
