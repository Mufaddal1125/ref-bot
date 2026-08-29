# Start everything except the Flutter client, which you run yourself so you can pick a device.
#
#   scripts\dev.ps1

$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$py = Join-Path $root "backend\.venv\Scripts\python.exe"

if (-not (Test-Path $py)) {
    Write-Host "No virtualenv. Run the setup steps in README.md first." -ForegroundColor Red
    exit 1
}

docker compose --project-directory $root up -d
& $py (Join-Path $root "backend\manage.py") migrate

Start-Process powershell -ArgumentList "-NoExit", "-Command", "& '$py' '$root\backend\manage.py' runserver"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "& '$py' '$root\backend\manage.py' rqworker referee --worker-class rq.SimpleWorker"

Write-Host "`nBackend on http://localhost:8000. Now start the client:" -ForegroundColor Green
Write-Host "  cd app; flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000" -ForegroundColor Cyan
