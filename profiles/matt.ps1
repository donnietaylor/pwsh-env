# matt: loads when PSENV_PROFILE=matt. Set it as a user variable on a shared box and the box profile steps aside.
Write-Host 'matt profile loaded. Developer habits on an admin box.' -ForegroundColor DarkGray

# Land in the working folder this box has, not the one the box profile picked.
$work = 'C:\src', "$HOME\source", "$HOME/src" | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($work) { Set-Location $work }
function src { if ($work) { Set-Location $work } }

# Git, read-mostly. Looking at what changed matters more than committing from a jump box.
function gs   { git status -sb }
function glog { git log --oneline --decorate -10 }
function gwho { git shortlog -sn --since='30 days ago' }

# Fleet checks from wherever I happen to be sitting.
function Get-Uptime  { param([Parameter(Mandatory)]$ComputerName) Invoke-Command -ComputerName $ComputerName { (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime } }
function Connect-Dev { Enter-PSSession dev-app-01 }

# Developer defaults. Verbose git, no progress bars, no truncation when a table gets wide.
$env:GIT_PAGER = 'cat'
$FormatEnumerationLimit = -1
