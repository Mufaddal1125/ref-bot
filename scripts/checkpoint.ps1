# Jump to a phase tag, keeping your own work safe in a stash.
#
#   scripts\checkpoint.ps1 phase-2-start
#
# Recover what you had with:  git stash list  /  git stash pop

param([Parameter(Mandatory = $true)][string]$Tag)

$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

git rev-parse --verify "refs/tags/$Tag" *> $null
if (-not $?) {
    Write-Host "No such tag: $Tag" -ForegroundColor Red
    Write-Host "Available:" -ForegroundColor Yellow
    git tag --list "phase-*"
    exit 1
}

if (git status --porcelain) {
    $stamp = Get-Date -Format "yyyy-MM-dd HH:mm"
    git stash push --include-untracked -m "before $Tag ($stamp)"
    Write-Host "Your work is stashed. Restore it later with: git stash pop" -ForegroundColor Yellow
}

git checkout $Tag
Write-Host "`nNow at $Tag." -ForegroundColor Green
Write-Host "What this phase asks you to write:" -ForegroundColor Cyan
git diff "$Tag..$($Tag -replace '-start$', '-complete')" --stat
