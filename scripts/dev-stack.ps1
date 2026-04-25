Param(
  [switch]$Observability,
  [switch]$Tools,
  [switch]$LoadTest
)

$ErrorActionPreference = 'Stop'

function Invoke-Compose {
  param([string[]]$Args)
  & docker compose @Args
}

function Wait-HttpReady {
  param(
    [string]$Url,
    [int]$MaxSeconds = 45
  )

  for ($i = 0; $i -lt $MaxSeconds; $i++) {
    try {
      $response = Invoke-WebRequest -Uri $Url -TimeoutSec 2
      if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 500) {
        return $true
      }
    } catch {
      Start-Sleep -Seconds 1
    }
  }

  return $false
}

$profiles = @()
if ($Observability) { $profiles += '--profile', 'observability' }
if ($Tools) { $profiles += '--profile', 'tools' }

Write-Host 'Building and starting HabitDuel backend containers...' -ForegroundColor Cyan
Invoke-Compose ($profiles + @('up', '-d', '--build', 'db', 'migrate', 'server'))

if ($Observability) {
  Invoke-Compose ($profiles + @('up', '-d', 'dozzle'))
}

if ($Tools) {
  Invoke-Compose ($profiles + @('up', '-d', 'adminer'))
}

if (Wait-HttpReady -Url 'http://localhost:8080/healthz') {
  Write-Host 'API is ready: http://localhost:8080/healthz' -ForegroundColor Green
} else {
  Write-Host 'API health check did not respond in time.' -ForegroundColor Yellow
}

if ($Observability) {
  Write-Host 'Live logs UI: http://localhost:9999' -ForegroundColor Green
}

if ($Tools) {
  Write-Host 'Adminer UI: http://localhost:8088' -ForegroundColor Green
}

if ($LoadTest) {
  Write-Host 'Running k6 load scenario...' -ForegroundColor Cyan
  Invoke-Compose (@('--profile', 'load', 'run', '--rm', 'k6'))
  Write-Host 'k6 summary: load-tests/results/api-summary.json' -ForegroundColor Green
}
