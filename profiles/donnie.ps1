# donnie: loads when PSENV_PROFILE=donnie. My habits, nobody else's. Committed, so they follow me.

# Land in the repos folder, wherever this box keeps it.
$repos = 'D:\repos', 'C:\github\repos', "$HOME/repos" | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($repos -and $PWD.Path -eq $HOME) { Set-Location $repos }
function repos { Set-Location $repos }

# Git, the short way. Push-PSEnv / Update-PSEnv come from the engine; these are for every other repo.
function gs  { git status -sb }
function gl  { git log --oneline --graph --decorate -20 }
function gd  { git diff --stat; git diff }
function gco { param([Parameter(Mandatory)]$Branch) git switch $Branch 2>$null || git switch -c $Branch }

# Admin odds and ends. Nothing here assumes Windows.
function ll { Get-ChildItem -Force @args | Sort-Object { -not $_.PSIsContainer }, Name }
function Test-Admin {
    if ($IsWindows) { ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole('Administrators') }
    else            { (id -u) -eq 0 }
}
function Get-PublicIP { (Invoke-RestMethod https://api.ipify.org?format=json).ip }
Set-Alias .. Set-LocationParent; function Set-LocationParent { Set-Location .. }
