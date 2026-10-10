# pwsh-env: one repo, in git, on every machine.
# $PROFILE on each machine is a single line:   . "$HOME\pwsh-env\pwsh-env.ps1"
# Which personality loads is PSENV_PROFILE (user or system variable), falling back to the machine name.

$PSEnvRoot = $PSScriptRoot

# ---- Sync in the background, never make the shell wait --------------------
# --ff-only: a machine that only consumes main can never end up mid-merge.
# GIT_TERMINAL_PROMPT=0: a credential problem fails fast instead of hanging behind the shell.
$env:GIT_TERMINAL_PROMPT = '0'
$PSEnvSync = Start-ThreadJob -ArgumentList $PSEnvRoot -ScriptBlock {
    param($root)
    # On a branch other than main this machine has opted out of sync, on purpose. Leave it alone.
    $branch = git -C $root branch --show-current
    if ($branch -ne 'main') { return [pscustomobject]@{ Ok = $true; New = 0; Branch = $branch } }
    # Can't write to the clone? Then this is a shared box and its scheduled Sync-PSEnv owns updates. Not an error.
    try { [IO.File]::Create("$root/.git/pwsh-env.probe", 1, 'DeleteOnClose').Dispose() } catch { return [pscustomobject]@{ Ok = $true; New = 0 } }
    $before = git -C $root rev-parse HEAD
    $out    = git -C $root pull --ff-only --quiet 2>&1 | Out-String
    $ok     = $LASTEXITCODE -eq 0
    $after  = git -C $root rev-parse HEAD
    git -C $root submodule update --init --quiet          # modules/ are submodules pinned to a commit; bring them to that commit
    [pscustomobject]@{ Ok = $ok; New = if ($before -ne $after) { git -C $root rev-list --count "$before..$after" } else { 0 }; Error = "$out" }
}

# ---- Scripts and modules from the repo, on every machine ----------------
# scripts/Get-Thing.ps1 is a command. modules/<Name>/<Name>.psd1 autoloads. That is the whole feature.
$env:PATH         = "$PSEnvRoot/scripts$([IO.Path]::PathSeparator)$env:PATH"
$env:PSModulePath = "$PSEnvRoot/modules$([IO.Path]::PathSeparator)$env:PSModulePath"

# ---- Shell -----------------------------------------------------------------
Set-PSReadLineOption -EditMode Windows -BellStyle None -HistoryNoDuplicates -HistorySearchCursorMovesToEnd -PredictionSource HistoryAndPlugin -PredictionViewStyle ListView
Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Tab       -Function MenuComplete
# Anything that looks like a credential still runs, it just never lands in the history file.
Set-PSReadLineOption -AddToHistoryHandler { param($line) $line -notmatch '(?i)password|secret|token|apikey|AsPlainText' }

$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$ProgressPreference = 'SilentlyContinue'
if ($IsWindows) { [Console]::OutputEncoding = [Text.Encoding]::UTF8 }

# ---- Functions -------------------------------------------------------------
function Push-PSEnv { param([Parameter(Mandatory)]$Message) git -C $PSEnvRoot add -A; git -C $PSEnvRoot commit -m $Message; git -C $PSEnvRoot push }
function Update-PSEnv {
    # -Latest moves every submodule to the tip of its branch instead of the pinned commit. Commit the result to share it.
    param([switch]$Latest)
    git -C $PSEnvRoot pull --ff-only
    if ($Latest) { git -C $PSEnvRoot submodule update --remote --merge } else { git -C $PSEnvRoot submodule update --init }
    Write-Host 'Reload:  . $PROFILE' -ForegroundColor Yellow
}
function Edit-PSEnv { code $PSEnvRoot }
function which ($name) { Get-Command $name -All | Select-Object Name, CommandType, Source }

# ---- Prompt ----------------------------------------------------------------
function prompt {
    # Report the background pull once, the first time the prompt draws after it finishes.
    if ($PSEnvSync -and $PSEnvSync.State -ne 'Running') {
        $r = Receive-Job $PSEnvSync; Remove-Job $PSEnvSync; $global:PSEnvSync = $null
        if ($r.New -gt 0)  { Write-Host "pwsh-env: pulled $($r.New) commit(s). Reload:  . `$PROFILE" -ForegroundColor Yellow }
        elseif (-not $r.Ok) { Write-Host "pwsh-env: not synced. $($r.Error -split "`n" -match '^fatal')" -ForegroundColor DarkYellow }
    }
    $branch = git branch --show-current 2>$null
    $Host.UI.RawUI.WindowTitle = "$env:USERNAME@$([Environment]::MachineName)"
    Write-Host "$([Environment]::MachineName.ToLower()) " -NoNewline -ForegroundColor DarkCyan
    Write-Host ($PWD.Path -replace [regex]::Escape($HOME), '~') -NoNewline -ForegroundColor Cyan
    # Branch in magenta. Anything but main in yellow: you are off the sync path and should know it.
    if ($branch) { Write-Host " ($branch)" -NoNewline -ForegroundColor $(if ($branch -eq 'main') { 'Magenta' } else { 'Yellow' }) }
    "> "
}

# ---- Profiles ---------------------------------------------------------------
# profiles/<name>.ps1 is committed. <name> is $env:PSENV_PROFILE, or this machine's name if unset.
#   Laptop:      PSENV_PROFILE=donnie as a user variable. My aliases, my prompt tweaks.
#   Shared box:  PSENV_PROFILE=jumpserver01 as a system variable: proxy, default folder, Connect-* helpers.
#                Any admin who wants their own sets the user variable and overrides it.
# local.ps1 is gitignored: anything that must never leave this machine. Loaded last, so it wins.
$PSEnvProfile = $env:PSENV_PROFILE ?? [Environment]::MachineName
foreach ($f in "profiles/$PSEnvProfile.ps1", 'local.ps1') {
    if (Test-Path "$PSEnvRoot/$f") { . "$PSEnvRoot/$f" }
}
