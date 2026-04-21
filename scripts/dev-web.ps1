Param(
  [switch]$EnableFirebaseWeb
)

$ErrorActionPreference = 'Stop'

function Test-DockerDaemon {
  try {
    docker info *> $null
    return $LASTEXITCODE -eq 0
  } catch {
    return $false
  }
}

function Wait-Backend {
  param(
    [int]$MaxSeconds = 25
  )

  for ($i = 0; $i -lt $MaxSeconds; $i++) {
    try {
      $null = Invoke-WebRequest -Uri 'http://localhost:8080/auth/login' -Method Get -TimeoutSec 2
      return $true
    } catch {
      $statusCode = $_.Exception.Response.StatusCode.value__
      if ($statusCode -eq 404 -or $statusCode -eq 405) {
        return $true
      }
    }
    Start-Sleep -Seconds 1
  }

  return $false
}

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
  Write-Error 'Docker CLI not found. Install Docker Desktop first.'
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-Error 'Flutter CLI not found in PATH.'
}

if (-not (Test-DockerDaemon)) {
  Write-Host 'Docker daemon is not running.' -ForegroundColor Yellow
  $dockerDesktop = 'C:\Program Files\Docker\Docker\Docker Desktop.exe'
  if (Test-Path $dockerDesktop) {
    Write-Host 'Trying to start Docker Desktop...' -ForegroundColor Yellow
    Start-Process -FilePath $dockerDesktop | Out-Null
  }
  Write-Host 'Wait until Docker Desktop is fully started, then rerun this script.' -ForegroundColor Yellow
  exit 1
}

Write-Host 'Starting backend stack (db, migrate, server)...' -ForegroundColor Cyan
& docker compose up -d db
& docker compose run --rm migrate
& docker compose up -d server

if (-not (Wait-Backend -MaxSeconds 30)) {
  Write-Host 'Backend did not become ready on localhost:8080 in time.' -ForegroundColor Yellow
  Write-Host 'Check logs: docker compose logs server --tail 200' -ForegroundColor Yellow
}

$flutterArgs = @(
  'run',
  '-d', 'web-server',
  '--web-hostname', '0.0.0.0',
  '--web-port', '8081',
  '--dart-define=API_BASE_URL=http://localhost:8080'
)

if ($EnableFirebaseWeb) {
  $flutterArgs += '--dart-define=ENABLE_FIREBASE_WEB=true'
}

Write-Host 'Starting Flutter Web on http://localhost:8081 ...' -ForegroundColor Cyan
& flutter @flutterArgs
