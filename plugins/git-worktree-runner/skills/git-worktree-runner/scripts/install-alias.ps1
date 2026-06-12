# Install a `gwtr` function in your PowerShell $PROFILE that wraps `git gtr`.
#
# Idempotent: guarded by a `# >>> git-worktree-runner >>>` marker block.
# Re-running replaces the block in place rather than appending duplicates.
#
# Note: `git gtr init <shell>` upstream only emits bash/zsh/fish helpers.
# There is no PowerShell `gtr-cd` equivalent, so this script wires up the
# `gwtr` function only. Inside Git Bash, run install-alias.sh instead to
# get the full bash navigation helper.
#
# Usage:
#   .\install-alias.ps1

$ErrorActionPreference = "Stop"

function Log($msg)  { Write-Host "[gtr-alias] $msg" -ForegroundColor Blue }
function Warn($msg) { Write-Host "[gtr-alias] $msg" -ForegroundColor Yellow }
function Fail($msg) { Write-Host "[gtr-alias] $msg" -ForegroundColor Red; exit 1 }

if (-not (Get-Command git-gtr -ErrorAction SilentlyContinue)) {
  Fail "git-gtr is not on PATH. Run .\install-gtr.ps1 first (then open a new shell)."
}

if (-not (Test-Path $PROFILE)) {
  Log "Creating $PROFILE"
  New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}

$startMarker = "# >>> git-worktree-runner >>>"
$endMarker   = "# <<< git-worktree-runner <<<"

$block = @"
$startMarker
# Managed by ops.ai git-worktree-runner skill. Edit between the markers if needed,
# but re-running install-alias.ps1 will replace the entire block.
function gwtr { git gtr @args }
$endMarker
"@

$content = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
if (-not $content) { $content = "" }

if ($content -match [regex]::Escape($startMarker)) {
  Log "Existing block found in $PROFILE — replacing."
  $pattern = "(?s)" + [regex]::Escape($startMarker) + ".*?" + [regex]::Escape($endMarker)
  $content = [regex]::Replace($content, $pattern, $block)
} else {
  Log "Appending block to $PROFILE"
  if ($content.Length -gt 0) {
    $content = $content.TrimEnd() + "`n`n" + $block + "`n"
  } else {
    $content = $block + "`n"
  }
}

Set-Content -Path $PROFILE -Value $content

Log "Done. Reload your profile:  . `$PROFILE   (or open a new PowerShell window)"
Log "Then try:  gwtr ls"
Warn "PowerShell has no 'gtr-cd' helper — to enter a worktree, use:"
Warn "  Set-Location (git gtr go <branch>)"
Warn "Or run install-alias.sh inside Git Bash to get the full navigation helper there."
