<#
╔══════════════════════════════════════════════════════════════════╗
║        航班信息跟踪平台 - 一键启动脚本                         ║
║        适用系统: Windows 11 / Windows 10 + PowerShell          ║
╚══════════════════════════════════════════════════════════════════╝
#>

$ErrorActionPreference = "Continue"
$PROJECT_ROOT = Split-Path -Parent $PSScriptRoot
$FRONTEND_ROOT = Join-Path (Split-Path -Parent $PROJECT_ROOT) "flight-tracking-frontend"

# ============================================================
# 颜色输出函数
# ============================================================
function Write-Info   { Write-Host "[INFO] $($args[0])" -ForegroundColor Cyan }
function Write-Success{ Write-Host "[OK]   $($args[0])" -ForegroundColor Green }
function Write-Warn   { Write-Host "[WARN] $($args[0])" -ForegroundColor Yellow }
function Write-Error  { Write-Host "[ERROR] $($args[0])" -ForegroundColor Red }
function Write-Section{ Write-Host "`n$('='*60)"; Write-Host "  $($args[0])" -ForegroundColor Magenta; Write-Host "$('='*60)" }

# ============================================================
# 第〇步：前置检查
# ============================================================
Write-Section "前置环境检查"

# 1. 检查工具
$tools = @(
    @{Name="Docker"; Cmd="docker --version"},
    @{Name="Docker Compose"; Cmd="docker-compose --version"},
    @{Name="Maven"; Cmd="mvn --version"},
    @{Name="Node.js"; Cmd="node --version"},
    @{Name="npm"; Cmd="npm --version"},
    @{Name="Python"; Cmd="python --version"}
)

$allToolsOk = $true
foreach ($tool in $tools) {
    try {
        $result = Invoke-Expression $tool.Cmd 2>&1
        if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq $null) {
            Write-Success "$($tool.Name): $($result -split "`n" | Select-Object -First 1)"
        } else {
            Write-Error "$($tool.Name): 未找到"
            $allToolsOk = $false
        }
    } catch {
        Write-Error "$($tool.Name): 未找到 - $_"
        $allToolsOk = $false
    }
}

if (-not $allToolsOk) {
    Write-Error "请安装缺少的工具后再试！"
    exit 1
}

# 2. 检查端口占用
Write-Info "检查关键端口占用..."
$ports = @(3306, 6379, 8848, 18080, 8081, 8082, 8083, 8084, 5000, 5173)
$occupiedPorts = @()
foreach ($port in $ports) {
    $conn = netstat -ano | Select-String ":$port\s+.*LISTENING"
    if ($conn) {
        $occupiedPorts += $port
        Write-Warn "端口 $port 已被占用"
    } else {
        Write-Success "端口 $port 可用"
    }
}

# 3. 检查 Nacos 地址配置
Write-Info "检查 Nacos 地址配置..."
$nacosFiles = @(
    "$PROJECT_ROOT/api-gateway/src/main/resources/application.yml",
    "$PROJECT_ROOT/flight-info-service/src/main/resources/bootstrap.yml",
    "$PROJECT_ROOT/flight-status-service/src/main/resources/bootstrap.yml",
    "$PROJECT_ROOT/airport-map-service/src/main/resources/bootstrap.yml",
    "$PROJECT_ROOT/data-collector-service/src/main/resources/bootstrap.yml"
)

$nacosOk = $true
foreach ($file in $nacosFiles) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw
        if ($content -match "172\.17\.0\.1:8080") {
            Write-Warn "$(Split-Path -Leaf (Split-Path -Parent $file)) 中 Nacos 地址仍为 172.17.0.1:8080"
            Write-Info "  请修改为 localhost:8848"
            $nacosOk = $false
        } else {
            Write-Success "$(Split-Path -Leaf (Split-Path -Parent $file)) Nacos 地址配置正确"
        }
    }
}

if (-not $nacosOk) {
    Write-Warn "请手动修改上述文件中的 Nacos 地址后继续"
}

# ============================================================
# 第一步：启动基础设施（Docker）
# ============================================================
Write-Section "第一步：启动基础设施（Docker）"

# 创建 Docker 网络（如果不存在）
$networkExists = docker network ls | Select-String "nacos_flight-network"
if (-not $networkExists) {
    Write-Info "创建 Docker 网络: nacos_flight-network..."
    docker network create nacos_flight-network
    Write-Success "Docker 网络已创建"
} else {
    Write-Success "Docker 网络 nacos_flight-network 已存在"
}

# 启动 Nacos
Write-Info "启动 Nacos..."
Set-Location "$PROJECT_ROOT/deploy/nacos"
docker-compose up -d
if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq $null) {
    Write-Success "Nacos 启动命令已发送"
} else {
    Write-Error "Nacos 启动失败"
}

# 启动 MySQL + Redis
Write-Info "启动 MySQL 和 Redis..."
Set-Location "$PROJECT_ROOT/deploy/mysql-redis"
docker-compose up -d
if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq $null) {
    Write-Success "MySQL + Redis 启动命令已发送"
} else {
    Write-Error "MySQL + Redis 启动失败"
}

Write-Info "等待基础设施启动完成（30秒）..."
Start-Sleep -Seconds 30

# ============================================================
# 第二步：构建 common 模块
# ============================================================
Write-Section "第二步：构建 common 模块"

Write-Info "构建 common 公共依赖模块..."
Set-Location $PROJECT_ROOT
mvn -f "$PROJECT_ROOT/pom.xml" -pl common -am install -DskipTests
if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq $null) {
    Write-Success "common 模块构建成功"
} else {
    Write-Error "common 模块构建失败"
}

# ============================================================
# 第三步：启动 API Gateway
# ============================================================
Write-Section "第三步：启动 API Gateway（端口 18080）"

Write-Info "在后台启动 API Gateway..."
Start-Process -WindowStyle Normal -FilePath "powershell" -ArgumentList @(
    "-NoExit", "-Command",
    "Set-Location '$PROJECT_ROOT/api-gateway'; mvn -DskipTests spring-boot:run"
)
Write-Info "等待网关启动（15秒）..."
Start-Sleep -Seconds 15
Write-Success "API Gateway 已在后台启动（端口 18080）"

# ============================================================
# 第四步：启动后端微服务
# ============================================================
Write-Section "第四步：启动后端微服务"

$services = @(
    @{Name="flight-info-service";   Port=8081; Dir="flight-info-service"},
    @{Name="flight-status-service"; Port=8082; Dir="flight-status-service"},
    @{Name="airport-map-service";   Port=8083; Dir="airport-map-service"},
    @{Name="data-collector-service";Port=8084; Dir="data-collector-service"}
)

foreach ($svc in $services) {
    Write-Info "启动 $($svc.Name)（端口 $($svc.Port)）..."
    Start-Process -WindowStyle Hidden -FilePath "powershell" -ArgumentList @(
        "-NoExit", "-Command",
        "Set-Location '$PROJECT_ROOT/$($svc.Dir)'; mvn -DskipTests spring-boot:run"
    )
    Write-Success "$($svc.Name) 已在后台启动"
    Start-Sleep -Seconds 2
}

# ============================================================
# 第五步：启动 AI 分析服务
# ============================================================
Write-Section "第五步：启动 AI 分析服务（端口 5000）"

$aiDir = "$PROJECT_ROOT/ai-analysis-service"
if (Test-Path "$aiDir/app.py") {
    Write-Info "安装 AI 服务依赖..."
    pip install -r "$aiDir/requirements.txt" -q 2>$null

    Write-Info "启动 AI 服务..."
    Start-Process -WindowStyle Hidden -FilePath "powershell" -ArgumentList @(
        "-NoExit", "-Command",
        "Set-Location '$aiDir'; python app.py"
    )
    Write-Success "AI 分析服务已在后台启动（端口 5000）"
} else {
    Write-Warn "AI 服务目录不存在，跳过..."
}

# ============================================================
# 第六步：启动前端
# ============================================================
Write-Section "第六步：启动前端（端口 5173）"

if (Test-Path "$FRONTEND_ROOT/package.json") {
    Write-Info "安装前端依赖..."
    Set-Location $FRONTEND_ROOT
    npm install --silent

    Write-Info "启动前端开发服务器..."
    Start-Process -WindowStyle Normal -FilePath "powershell" -ArgumentList @(
        "-NoExit", "-Command",
        "Set-Location '$FRONTEND_ROOT'; npm run dev"
    )
    Write-Success "前端已在后台启动（端口 5173）"
} else {
    Write-Error "前端目录不存在: $FRONTEND_ROOT"
}

# ============================================================
# 启动完成
# ============================================================
Write-Section "启动完成！"

Write-Success "所有服务已启动！以下为访问地址："
Write-Host ""
Write-Host "  🌐  前端界面:       http://localhost:5173" -ForegroundColor Green
Write-Host "  📋  Nacos 控制台:   http://localhost:8848/nacos" -ForegroundColor Green
Write-Host "  ⚙️  网关地址:       http://localhost:18080" -ForegroundColor Green
Write-Host "  🤖  AI 服务:        http://localhost:5000" -ForegroundColor Green
Write-Host ""
Write-Host "  Nacos 默认账号密码: nacos / nacos" -ForegroundColor Yellow
Write-Host ""
Write-Host "  💡 提示：按 Ctrl+C 不会停止后台服务" -ForegroundColor Cyan
Write-Host "  要停止所有服务，请关闭对应的 PowerShell 窗口" -ForegroundColor Cyan
Write-Host ""
