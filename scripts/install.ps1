$ErrorActionPreference = "Stop"

Write-Host "=== InfluxDB 3 Lab Install ==="
Write-Host ""

function Step($msg) {
    Write-Host ""
    Write-Host "---- $msg ----"
}

function Fail($msg) {
    Write-Host ""
    Write-Host "ERROR: $msg"
    exit 1
}

Step "Check Docker"
docker --version
if ($LASTEXITCODE -ne 0) {
    Fail "Docker is not installed or not in PATH."
}

Step "Create .env if missing"
if (!(Test-Path ".env")) {
@"
INFLUX_TOKEN=
INFLUX_DB=metrics
INFLUX_URL=http://influxdb3:8181
"@ | Out-File -Encoding utf8 .env
    Write-Host ".env created"
} else {
    Write-Host ".env already exists"
}

Step "Current .env content"
Get-Content .env

Step "Start containers"
docker compose up -d
if ($LASTEXITCODE -ne 0) {
    Fail "docker compose up failed."
}

Step "Wait for InfluxDB"
Start-Sleep -Seconds 8

Step "Show container status"
docker ps

Step "Show InfluxDB startup logs"
docker logs --tail 30 influxdb3

Step "Read token line from .env"
$envContent = Get-Content .env
$tokenLine = $envContent | Where-Object { $_ -like "INFLUX_TOKEN=*" }

if (-not $tokenLine) {
    Fail "INFLUX_TOKEN line not found in .env"
}

Write-Host "Token line: $tokenLine"

if ($tokenLine -eq "INFLUX_TOKEN=") {
    Step "Generate admin token"

    $tokenOutput = docker exec influxdb3 influxdb3 create token --admin 2>&1
    $raw = ($tokenOutput | Out-String).Trim()

    Write-Host "Raw token output:"
    Write-Host "-----------------"
    Write-Host $raw
    Write-Host "-----------------"

    if ($raw -match 'apiv3_[A-Za-z0-9\-_]+') {
        $token = $Matches[0]
        Write-Host "Extracted token: $token"

        (Get-Content .env) -replace '^INFLUX_TOKEN=.*', "INFLUX_TOKEN=$token" |
            Set-Content .env

        Write-Host ".env updated"
    } else {
        Fail "Could not extract token from CLI output."
    }
}
else {
    $token = $tokenLine -replace "^INFLUX_TOKEN=", ""
    Write-Host "Token already present in .env"
    Write-Host "Token: $token"
}

Step "Show .env after token step"
Get-Content .env

if (-not $token -or $token -eq "apiv3_replace_me") {
    Fail "Token is empty or placeholder."
}

Step "Create database"
$dbLine = $envContent | Where-Object { $_ -like "INFLUX_DB=*" }
if (-not $dbLine) {
    Fail "INFLUX_DB line not found in .env"
}
$db = $dbLine -replace "^INFLUX_DB=", ""
Write-Host "Database name: $db"

$createDbOutput = docker exec influxdb3 influxdb3 create database $db --token $token 2>&1
Write-Host "Create database output:"
Write-Host "-----------------------"
Write-Host ($createDbOutput | Out-String).Trim()
Write-Host "-----------------------"

Step "Verify databases"
$showDbOutput = docker exec influxdb3 influxdb3 show databases --token $token 2>&1
Write-Host ($showDbOutput | Out-String).Trim()

Step "Restart Telegraf"
docker compose restart telegraf
if ($LASTEXITCODE -ne 0) {
    Fail "Failed to restart Telegraf."
}

Start-Sleep -Seconds 15

Step "Show Telegraf logs"
docker logs --tail 30 telegraf

Write-Host ""
Write-Host "=== Setup complete ==="
Write-Host "Grafana:      http://localhost:3000"
Write-Host "InfluxDB API: http://localhost:8181"
Write-Host ""