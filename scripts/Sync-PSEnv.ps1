# Tier 2, unattended puller. Run on a schedule as the machine (Task Scheduler on Windows, cron on Linux).
# This clone is a consumer: whatever is on origin/main wins. Local edits are discarded on purpose.
#   Windows:  Register-ScheduledTask PSEnvSync -User SYSTEM -Trigger (New-ScheduledTaskTrigger -Daily -At 3am) `
#               -Action (New-ScheduledTaskAction pwsh "-NoProfile -File C:\ProgramData\pwsh-env\scripts\Sync-PSEnv.ps1")
#   Linux:    0 3 * * * pwsh -NoProfile -File /opt/pwsh-env/scripts/Sync-PSEnv.ps1
param([string]$Root = (Split-Path $PSScriptRoot))

$env:GIT_TERMINAL_PROMPT = '0'
$before = git -C $Root rev-parse HEAD
git -C $Root fetch --quiet origin
git -C $Root reset --hard --quiet origin/main
git -C $Root submodule update --init --quiet
git -C $Root clean -fdq
$after  = git -C $Root rev-parse HEAD

$msg = if ($before -ne $after) { "$before -> $after" } else { "current at $after" }
"$(Get-Date -Format s)  $msg" | Add-Content "$Root/sync.log"
