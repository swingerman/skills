# Install git-worktree-runner (git gtr) on Windows.
#
# Requires Git for Windows (provides Git Bash). git-gtr is a bash script,
# so a POSIX shell is mandatory — we rely on the bash interpreter that
# ships with Git for Windows.
#
# Strategy: clone to %LOCALAPPDATA%\git-worktree-runner and add its bin/
# directory to the user-level PATH. No admin / Developer Mode required.
#
# Usage:
#   .\install-gtr.ps1 [-Force]

param([switch]$Force)

$ErrorActionPreference = "Stop"

function Log($msg)  { Write-Host "[gtr-install] $msg" -ForegroundColor Blue }
function Warn($msg) { Write-Host "[gtr-install] $msg" -ForegroundColor Yellow }
function Fail($msg) { Write-Host "[gtr-install] $msg" -ForegroundColor Red; exit 1 }

if (-not $Force) {
  $existing = Get-Command git-gtr -ErrorAction SilentlyContinue
  if ($existing) {
    $version = & git gtr version 2>$null
    Log "git-gtr already installed at $($existing.Source) ($version). Use -Force to reinstall."
    exit 0
  }
}

if (-not (Get-Command bash -ErrorAction SilentlyContinue)) {
  Fail "bash not found. Install Git for Windows from https://git-scm.com/download/win — Git Bash is required for git-gtr."
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  Fail "git not found on PATH. Install Git for Windows first."
}

$installRoot = Join-Path $env:LOCALAPPDATA "git-worktree-runner"
$binDir      = Join-Path $installRoot "bin"

Log "Installing to $installRoot"

if (Test-Path (Join-Path $installRoot ".git")) {
  Log "Repo already cloned — pulling latest."
  git -C $installRoot pull --ff-only
} else {
  git clone --depth 1 https://github.com/coderabbitai/git-worktree-runner.git $installRoot
}

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$pathEntries = if ($userPath) { $userPath -split ';' } else { @() }
if (-not ($pathEntries -contains $binDir)) {
  Log "Adding $binDir to user PATH (requires opening a new shell to take effect)."
  $newUserPath = if ($userPath) { "$userPath;$binDir" } else { $binDir }
  [Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")
  $env:Path = "$env:Path;$binDir"
} else {
  Log "$binDir already on user PATH."
}

$verify = & git gtr version 2>$null
if ($verify) {
  Log "Installed: $verify"
} else {
  Warn "Install completed but 'git gtr' is not usable in this shell yet."
  Warn "Open a new PowerShell window and re-run: git gtr version"
}
