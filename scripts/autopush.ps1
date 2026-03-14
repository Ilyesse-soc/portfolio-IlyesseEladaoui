param(
  [string]$RepoRoot = "",
  [int]$DebounceMs = 800,
  [int]$PollMs = 250,
  [string]$Branch = "main"
)

$ErrorActionPreference = 'Stop'

function Resolve-RepoRoot {
  param([string]$Provided)
  if (-not [string]::IsNullOrWhiteSpace($Provided)) {
    return (Resolve-Path $Provided).Path
  }
  return (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
}

$repo = Resolve-RepoRoot -Provided $RepoRoot

Write-Host "[autopush] Repo: $repo" -ForegroundColor Cyan
Write-Host "[autopush] Watching for changes… (Ctrl+C to stop)" -ForegroundColor Cyan

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $repo
$watcher.IncludeSubdirectories = $true
$watcher.Filter = '*.*'
$watcher.NotifyFilter = [IO.NotifyFilters]'FileName, DirectoryName, LastWrite, Size'
$watcher.EnableRaisingEvents = $true

$script:pending = $false
$script:lastEvent = Get-Date

function Should-IgnorePath {
  param([string]$fullPath)
  if ([string]::IsNullOrWhiteSpace($fullPath)) { return $true }
  if ($fullPath -match "\\\.git(\\|$)") { return $true }
  if ($fullPath -match "\\node_modules(\\|$)") { return $true }
  if ($fullPath -match "\\\.vscode(\\|$)\\\.log$") { return $true }
  return $false
}

$handler = {
  $p = $Event.SourceEventArgs.FullPath
  if (Should-IgnorePath -fullPath $p) { return }
  $script:pending = $true
  $script:lastEvent = Get-Date
}

Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $handler | Out-Null
Register-ObjectEvent -InputObject $watcher -EventName Created -Action $handler | Out-Null
Register-ObjectEvent -InputObject $watcher -EventName Deleted -Action $handler | Out-Null
Register-ObjectEvent -InputObject $watcher -EventName Renamed -Action $handler | Out-Null

function Git-HasChanges {
  param([string]$root)
  Push-Location $root
  try {
    $out = git status --porcelain
    return -not [string]::IsNullOrWhiteSpace($out)
  } finally {
    Pop-Location
  }
}

function Git-AutoCommitPush {
  param([string]$root, [string]$branch)

  Push-Location $root
  try {
    git add -A | Out-Null

    # If nothing staged, skip.
    git diff --cached --quiet
    if ($LASTEXITCODE -eq 0) {
      return
    }

    $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $msg = "chore: auto-sync $ts"

    git commit -m $msg | Out-Null
    git push origin $branch | Out-Null

    Write-Host "[autopush] Pushed: $msg" -ForegroundColor Green
  } catch {
    # Avoid crashing the watcher on transient git errors.
    Write-Host "[autopush] Git error: $($_.Exception.Message)" -ForegroundColor Yellow
  } finally {
    Pop-Location
  }
}

while ($true) {
  Start-Sleep -Milliseconds $PollMs

  if (-not $script:pending) { continue }

  $elapsed = (New-TimeSpan -Start $script:lastEvent -End (Get-Date)).TotalMilliseconds
  if ($elapsed -lt $DebounceMs) { continue }

  $script:pending = $false

  if (Git-HasChanges -root $repo) {
    Git-AutoCommitPush -root $repo -branch $Branch
  }
}
