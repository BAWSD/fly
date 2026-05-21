# Flight Tracking Platform - One-Click Start Script
# Usage: Right-click -> Run with PowerShell
$ErrorActionPreference = "Continue"
$base = Split-Path -Parent $MyInvocation.MyCommand.Path
$platform = Join-Path $base "flight-tracking-platform"
$frontend = Join-Path $base "flight-tracking-frontend"

# Setup Java Environment
#$env:JAVA_HOME = "C:/Users/Administrator/.jdks/openjdk-25.0.1"
#$env:Path = "$env:JAVA_HOME/bin;$env:Path"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Flight Tracking Platform - Quick Start" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check/Start Docker containers
Write-Host "[1/5] Checking infrastructure (MySQL/Redis/Nacos)..." -ForegroundColor Yellow
$mysqlRunning = docker ps --format "{{.Names}}" 2>$null | Select-String "flight-mysql"
$nacosRunning = docker ps --format "{{.Names}}" 2>$null | Select-String "flight-nacos"
$redisRunning = docker ps --format "{{.Names}}" 2>$null | Select-String "flight-redis"

if (-not $mysqlRunning -or -not $nacosRunning -or -not $redisRunning) {
    Write-Host "  Starting Docker containers..." -ForegroundColor Gray
    docker network create nacos_flight-network 2>$null | Out-Null
    Push-Location (Join-Path $platform "deploy/nacos")
    docker-compose up -d 2>$null | Out-Null
    Pop-Location
    Start-Sleep -Seconds 5
    Push-Location (Join-Path $platform "deploy/mysql-redis")
    docker-compose up -d 2>$null | Out-Null
    Pop-Location
    Write-Host "  Waiting for MySQL to be ready..." -ForegroundColor Gray
    Start-Sleep -Seconds 15
    Write-Host "  Docker containers started" -ForegroundColor Green
} else {
    Write-Host "  Docker containers already running" -ForegroundColor Green
}

# Step 2: Check database initialization
Write-Host "[2/5] Checking database..." -ForegroundColor Yellow
try {
    $count = docker exec flight-mysql mysql -uroot -p123456 -e "SELECT COUNT(*) FROM flight_info.flight_info" -sN 2>$null
    if ([int]$count -lt 20) {
        Write-Host "  Initializing database..." -ForegroundColor Gray
        $sqlFile = Join-Path $base "init-all.sql"
        $cmd = 'docker exec -i flight-mysql mysql -uroot -p123456 --default-character-set=utf8mb4 < "' + $sqlFile + '"'
        cmd /c $cmd 2>$null
        Write-Host "  Database initialized" -ForegroundColor Green
    } else {
        Write-Host "  Database ready ($count flight records)" -ForegroundColor Green
    }
} catch {
    Write-Host "  Database check skipped" -ForegroundColor DarkGray
}

# Step 3: Check/Build backend
Write-Host "[3/5] Checking backend build..." -ForegroundColor Yellow
$jarPath = Join-Path $platform "api-gateway/target/api-gateway-1.0.0.jar"
if (-not (Test-Path $jarPath)) {
    Write-Host "  Building backend (may take a while on first run)..." -ForegroundColor Gray
    Push-Location $platform
    mvn clean package -DskipTests -T 4 2>$null
    Pop-Location
    Write-Host "  Build complete" -ForegroundColor Green
} else {
    Write-Host "  Backend already built" -ForegroundColor Green
}

# Step 4: Stop old processes and start backend services
Write-Host "[4/5] Starting backend services..." -ForegroundColor Yellow

# Stop old Java processes
$oldJava = Get-Process -Name "java" -ErrorAction SilentlyContinue
if ($oldJava) {
    Write-Host "  Stopping old backend processes..." -ForegroundColor Gray
    taskkill /F /IM java.exe 2>$null | Out-Null
    Start-Sleep -Seconds 3
}

$services = @(
    @{ Name = "API-Gateway"; Jar = "api-gateway/target/api-gateway-1.0.0.jar"; Port = 18080 },
    @{ Name = "Flight-Info"; Jar = "flight-info-service/target/flight-info-service-1.0.0.jar"; Port = 8081 },
    @{ Name = "Flight-Status"; Jar = "flight-status-service/target/flight-status-service-1.0.0.jar"; Port = 8082 },
    @{ Name = "Airport-Map"; Jar = "airport-map-service/target/airport-map-service-1.0.0.jar"; Port = 8083 },
    @{ Name = "Data-Collector"; Jar = "data-collector-service/target/data-collector-service-1.0.0.jar"; Port = 8084 }
)

foreach ($svc in $services) {
    $jar = Join-Path $platform $svc.Jar
    if (Test-Path $jar) {
        Start-Process -FilePath "$env:JAVA_HOME/bin/java.exe" `
                      -ArgumentList "-jar", $jar `
                      -WorkingDirectory $platform `
                      -WindowStyle Hidden
        Write-Host "  Starting $($svc.Name) (port $($svc.Port))..." -ForegroundColor Gray
    } else {
        Write-Host "  SKIP $($svc.Name) (jar not found)" -ForegroundColor Red
    }
}

Write-Host "  Waiting for backend services (about 30s)..." -ForegroundColor Gray
Start-Sleep -Seconds 30

# Verify backend ports
$allOk = $true
foreach ($port in @(18080, 8081, 8082, 8083, 8084)) {
    $listening = netstat -ano | Select-String ":$port " | Select-String "LISTENING"
    if ($listening) {
        Write-Host "  Port $port OK" -ForegroundColor DarkGreen
    } else {
        Write-Host "  Port $port NOT READY" -ForegroundColor DarkYellow
        $allOk = $false
    }
}

if (-not $allOk) {
    Write-Host "  Some services still starting, waiting more..." -ForegroundColor DarkYellow
    Start-Sleep -Seconds 15
}

# Step 5: Start frontend
Write-Host "[5/5] Starting frontend..." -ForegroundColor Yellow

# Stop old node processes
$oldNode = Get-Process -Name "node" -ErrorAction SilentlyContinue
if ($oldNode) {
    Write-Host "  Stopping old frontend process..." -ForegroundColor Gray
    taskkill /F /IM node.exe 2>$null | Out-Null
    Start-Sleep -Seconds 2
}

Push-Location $frontend
if (-not (Test-Path "node_modules")) {
    Write-Host "  Installing frontend dependencies..." -ForegroundColor Gray
    npm install 2>$null | Out-Null
}
Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "npm run dev" -WindowStyle Minimized
Pop-Location
Start-Sleep -Seconds 8

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  START COMPLETE!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Frontend:  http://localhost:5173" -ForegroundColor White
Write-Host "  API Gateway: http://localhost:18080" -ForegroundColor White
Write-Host "  Nacos:     http://localhost:8848/nacos" -ForegroundColor White
Write-Host ""
Write-Host "  Press any key to exit (services will keep running)..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
