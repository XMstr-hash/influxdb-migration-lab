@echo off
setlocal

echo ==========================================
echo     InfluxDB 3 Lab - One Click Setup
echo ==========================================
echo.

REM --- Ensure admin rights ---
net session >nul 2>&1
if errorlevel 1 (
    echo Requesting administrator rights...
    powershell -Command "Start-Process cmd -ArgumentList '/c %~s0' -Verb RunAs"
    exit /b
)

echo Running as Administrator
echo.

REM --- Define winget path explicitly (fix admin PATH issue) ---
set "WINGET=%LOCALAPPDATA%\Microsoft\WindowsApps\winget.exe"

if not exist "%WINGET%" (
    echo Winget not found.
    echo.
    echo Please install App Installer from Microsoft Store:
    echo https://apps.microsoft.com/store/detail/app-installer/9NBLGGH4NNS1
    start https://apps.microsoft.com/store/detail/app-installer/9NBLGGH4NNS1
    echo After installation, run this script again.
    pause
    exit /b
)

echo Winget is available.
echo.

REM ================================
REM Install Git
REM ================================
git --version >nul 2>&1
if errorlevel 1 (
    echo Git not found. Installing via winget...

    "%WINGET%" install --id Git.Git -e --source winget ^
    --accept-package-agreements --accept-source-agreements

    echo.
    echo Git installation finished.
    echo Please run this script again.
    pause
    exit /b
)

echo Git is installed.
echo.

REM ================================
REM Install Docker
REM ================================
docker --version >nul 2>&1
if errorlevel 1 (
    echo Docker not found. Installing via winget...

    "%WINGET%" install --id Docker.DockerDesktop -e --source winget ^
    --accept-package-agreements --accept-source-agreements

    echo.
    echo Docker installation started.
    echo A reboot is required.
    echo Please restart your PC and run this script again.
    pause
    exit /b
)

echo Docker is installed.
echo.

REM ================================
REM Ensure Docker is running
REM ================================
docker info >nul 2>&1
if errorlevel 1 (
    echo Docker is not running. Starting Docker Desktop...

    start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"

    echo Waiting for Docker to start...
    timeout /t 20 >nul

    docker info >nul 2>&1
    if errorlevel 1 (
        echo Docker failed to start.
        echo Please start Docker manually and run the script again.
        pause
        exit /b
    )
)

echo Docker is running.
echo.

REM ================================
REM Clone / Update Project
REM ================================
set "PROJECT_DIR=%USERPROFILE%\influxdb-migration-lab"

if not exist "%PROJECT_DIR%" (
    echo Cloning project...
    git clone https://github.com/XMstr-hash/influxdb-migration-lab.git "%PROJECT_DIR%"
    if errorlevel 1 (
        echo Failed to clone repository.
        pause
        exit /b
    )
) else (
    echo Project already exists. Pulling latest version...
    cd /d "%PROJECT_DIR%"
    git pull
)

cd /d "%PROJECT_DIR%"

REM ================================
REM Run deployment
REM ================================
echo.
echo Starting deployment...
powershell -ExecutionPolicy Bypass -File ".\scripts\install.ps1"

echo.
echo ==========================================
echo Setup completed!
echo ==========================================
echo Grafana: http://localhost:3000
echo.

pause