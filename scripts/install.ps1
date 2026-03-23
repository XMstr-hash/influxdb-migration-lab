Write-Host "=== InfluxDB 3 Lab One-Click Setup ==="

# 1. Check if Docker is installed
docker --version | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Docker is not installed!"
    exit
}

# 2. Create .env file if it does not exist
if (!(Test-Path ".env")) {
    Write-Host "Creating .env file..."
    @"
INFLUX_TOKEN=
INFLUX_DB=metrics
INFLUX_URL=http://influxdb3:8181
"@ | Out-File -Encoding utf8 .env
}

# 3. Start Docker containers
Write-Host "Starting containers..."
docker compose up -d

# Wait for services to initialize
Start-Sleep -Seconds 5

# 4. Check if token already exists in .env
$envContent = Get-Content .env
$tokenLine = $envContent | Where-Object { $_ -like "INFLUX_TOKEN=*" }

if ($tokenLine -match "INFLUX_TOKEN=$") {

    Write-Host "Generating admin token..."

    # Create admin token inside container
    $tokenOutput = docker exec influxdb3 influxdb3 create token --admin

    # Extract token from output
    $token = ($tokenOutput | Select-String "apiv3_").ToString().Trim()

    if (-not $token) {
        Write-Host "❌ Failed to generate token"
        exit
    }

    Write-Host "Token successfully created."

    # Save token into .env file
    (Get-Content .env) -replace "INFLUX_TOKEN=", "INFLUX_TOKEN=$token" |
        Set-Content .env
}
else {
    $token = ($tokenLine -replace "INFLUX_TOKEN=", "")
    Write-Host "Token already exists in .env"
}

# 5. Create database (if not exists)
Write-Host "Creating database (metrics)..."

docker exec influxdb3 influxdb3 create database metrics --token $token 2>$null

# 6. Restart Telegraf to apply new token
Write-Host "Restarting Telegraf..."
docker compose restart telegraf

# 7. Final output
Write-Host ""
Write-Host "✅ Setup complete!"
Write-Host ""
Write-Host "Access services:"
Write-Host "Grafana:     http://localhost:3000"
Write-Host "InfluxDB API: http://localhost:8181"
Write-Host ""