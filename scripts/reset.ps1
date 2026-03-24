Write-Host "=== InfluxDB Lab RESET ==="
Write-Host ""

# 1. Stop containers
Write-Host "Stopping containers..."
docker compose down

# 2. Remove volumes (IMPORTANT!)
Write-Host "Removing volumes..."
docker volume rm influxdb-migration-lab_influxdb3-data -f 2>$null
docker volume rm influxdb-migration-lab_grafana-data -f 2>$null

# 3. Optional: remove .env
if (Test-Path ".env") {
    Write-Host "Removing .env file..."
    Remove-Item .env -Force
}

# 4. Cleanup dangling containers (optional)
Write-Host "Cleaning up unused Docker resources..."
docker system prune -f

Write-Host ""
Write-Host "✅ Reset complete!"
Write-Host "You can now run install.ps1 again."
Write-Host ""