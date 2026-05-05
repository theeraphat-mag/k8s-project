@echo off
REM Terraform launcher for Windows CMD

setlocal enabledelayedexpansion

set "TERRAFORM_EXE=%USERPROFILE%\tools\terraform\terraform.exe"
if not exist "%TERRAFORM_EXE%" (
    set "TERRAFORM_EXE=C:\tools\terraform\terraform.exe"
)

if "%1"=="" (
    echo Terraform Launcher
    echo ==================
    echo Usage: terraform.bat [command]
    echo.
    echo Commands:
    echo   init      - Initialize Terraform
    echo   validate  - Validate Terraform files
    echo   plan      - Create and show plan
    echo   apply     - Apply Terraform changes
    echo   destroy   - Destroy infrastructure
    echo   clean     - Remove state files
    echo   show      - Show current state
    echo.
    echo Example: terraform.bat plan
    exit /b 0
)

REM Check if terraform.exe exists in known install locations
if not exist "%TERRAFORM_EXE%" (
    echo Error: Terraform not found in PATH
    echo Please run setup.ps1 first
    echo.
    echo Or download from: https://www.terraform.io/downloads
    exit /b 1
)

REM Execute terraform command
set cmd=%1
shift

if "%cmd%"=="init" (
    "%TERRAFORM_EXE%" init
) else if "%cmd%"=="validate" (
    "%TERRAFORM_EXE%" validate
) else if "%cmd%"=="plan" (
    "%TERRAFORM_EXE%" plan -out=tfplan
) else if "%cmd%"=="apply" (
    if exist tfplan (
        "%TERRAFORM_EXE%" apply tfplan
    ) else (
        "%TERRAFORM_EXE%" apply -auto-approve
    )
) else if "%cmd%"=="destroy" (
    "%TERRAFORM_EXE%" destroy
) else if "%cmd%"=="clean" (
    del /q .terraform.lock.hcl 2>nul
    rmdir /s /q .terraform 2>nul
    del /q terraform.tfstate* 2>nul
    del /q tfplan 2>nul
    del /q *.backup 2>nul
    echo Cleaned up Terraform files
) else if "%cmd%"=="show" (
    "%TERRAFORM_EXE%" show
) else (
    "%TERRAFORM_EXE%" %*
)
