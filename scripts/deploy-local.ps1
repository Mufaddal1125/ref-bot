# Build the client for the room and bring the whole stack up on this machine.
#
#   scripts\deploy-local.ps1               # http://<this machine's LAN IP>
#   scripts\deploy-local.ps1 -Port 8080    # if something already owns 80
#   scripts\deploy-local.ps1 -HostIp 192.168.1.20
#   scripts\deploy-local.ps1 -SkipBuild    # backend-only change

param(
    [int]$Port = 80,
    [string]$HostIp,
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..")

# The client is compiled against one address, so it has to be the address the
# room types — not localhost. Physical adapters only: a VPN tunnel or a Hyper-V
# switch usually holds the default route, and neither is reachable from a phone.
$candidates = @()
$physical = @(Get-NetAdapter -Physical | Where-Object Status -eq "Up" | Select-Object -ExpandProperty Name)
if ($physical) {
    $candidates = @(Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object {
            $physical -contains $_.InterfaceAlias -and
            $_.IPAddress -notlike "169.254.*" -and $_.IPAddress -ne "127.0.0.1"
        } |
        Sort-Object { (Get-NetIPInterface -InterfaceIndex $_.InterfaceIndex -AddressFamily IPv4).InterfaceMetric })
}

if (-not $HostIp) {
    if (-not $candidates) {
        throw "Could not find a LAN address on any physical adapter. Pass -HostIp <ip>."
    }
    $HostIp = $candidates[0].IPAddress
    Write-Host "Serving on $HostIp ($($candidates[0].InterfaceAlias))." -ForegroundColor Cyan
    foreach ($other in $candidates | Select-Object -Skip 1) {
        Write-Host "  also available: -HostIp $($other.IPAddress)  ($($other.InterfaceAlias))" -ForegroundColor DarkGray
    }
}

$origin = if ($Port -eq 80) { "http://$HostIp" } else { "http://${HostIp}:$Port" }

$envFile = Join-Path $root ".env.deploy"
if (-not (Test-Path $envFile)) {
    Copy-Item (Join-Path $root ".env.deploy.example") $envFile
    $secret = -join ((48..57) + (97..122) | Get-Random -Count 50 | ForEach-Object { [char]$_ })
    (Get-Content $envFile) -replace '^DJANGO_SECRET_KEY=.*', "DJANGO_SECRET_KEY=$secret" |
        Set-Content $envFile
    Write-Host "Created .env.deploy with a fresh secret key." -ForegroundColor Yellow
    Write-Host "Put REFEREE_API_KEY in it before phase 3 matters." -ForegroundColor Yellow
}

if (-not $SkipBuild) {
    Write-Host "Building the client against $origin ..." -ForegroundColor Cyan
    Push-Location (Join-Path $root "app")
    try {
        flutter build web --release --dart-define=API_BASE_URL=$origin
        if ($LASTEXITCODE -ne 0) { throw "flutter build web failed." }
    } finally {
        Pop-Location
    }
}

$env:HTTP_PORT = "$Port"
$env:CSRF_TRUSTED_ORIGINS = $origin

docker compose --project-directory $root `
    -f (Join-Path $root "docker-compose.deploy.yml") `
    --env-file $envFile `
    up -d --build
if ($LASTEXITCODE -ne 0) { throw "docker compose up failed." }

Write-Host "`nRefBot is on $origin" -ForegroundColor Green
Write-Host "  admin      $origin/admin/"
Write-Host "  job queue  $origin/django-rq/"
Write-Host "  logs       docker compose -f docker-compose.deploy.yml logs -f backend worker"
Write-Host "  stop       docker compose -f docker-compose.deploy.yml down"
Write-Host "`nIf phones cannot reach it, open the port once, from an admin shell:" -ForegroundColor Yellow
Write-Host "  New-NetFirewallRule -DisplayName 'RefBot' -Direction Inbound -Protocol TCP -LocalPort $Port -Action Allow" -ForegroundColor Cyan
