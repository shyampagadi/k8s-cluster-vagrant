@echo off
REM copy-kubeconfig.bat - Copy kubeconfig from vagrant cluster to Windows kubectl config

setlocal enabledelayedexpansion

echo Copying kubeconfig from vagrant cluster...

REM Check if admin.conf exists
if not exist "admin.conf" (
    echo ERROR: admin.conf not found in current directory.
    echo    Make sure you've run 'vagrant up' and the master node has completed initialization.
    exit /b 1
)

REM Set paths
set "CURRENT_DIR=%CD%"
set "KUBECONFIG_LOCAL=%CURRENT_DIR%\kubeconfig"
set "KUBE_DIR=%USERPROFILE%\.kube"
set "KUBECONFIG_GLOBAL=%KUBE_DIR%\config"

REM Create timestamp for backup (using PowerShell for better compatibility)
for /f %%i in ('powershell -command "Get-Date -Format 'yyyyMMdd_HHmmss'"') do set "TIMESTAMP=%%i"

REM Copy to current directory
echo Copying to current directory...
if exist "%KUBECONFIG_LOCAL%" (
    echo Backing up existing kubeconfig to kubeconfig.backup.%TIMESTAMP%
    copy "%KUBECONFIG_LOCAL%" "kubeconfig.backup.%TIMESTAMP%" >nul
)
copy "admin.conf" "%KUBECONFIG_LOCAL%" >nul

REM Copy to global kubectl config location
echo Copying to global kubectl config location...
if not exist "%KUBE_DIR%" mkdir "%KUBE_DIR%"
if exist "%KUBECONFIG_GLOBAL%" (
    echo Backing up existing global kubeconfig to config.backup.%TIMESTAMP%
    copy "%KUBECONFIG_GLOBAL%" "%KUBE_DIR%\config.backup.%TIMESTAMP%" >nul
)
copy "admin.conf" "%KUBECONFIG_GLOBAL%" >nul

echo SUCCESS: Kubeconfig copied successfully!
echo.
echo Local copy: %KUBECONFIG_LOCAL%
echo Global copy: %KUBECONFIG_GLOBAL%
echo.
echo You can now use kubectl commands from anywhere:
echo    kubectl get nodes
echo    kubectl get pods -A
echo    kubectl get services
echo.
echo To use the local copy instead:
echo    kubectl --kubeconfig=%KUBECONFIG_LOCAL% get nodes
echo.
echo To restore your previous global config:
echo    copy "%KUBE_DIR%\config.backup.%TIMESTAMP%" "%KUBECONFIG_GLOBAL%"

pause
