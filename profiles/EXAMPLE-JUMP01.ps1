# The box's personality. Loads when PSENV_PROFILE is EXAMPLE-JUMP01 (set as a system variable on the shared box).
# Committed, so every admin on every box like this gets the same setup.
Write-Host 'JUMP01 shared profile. Set PSENV_PROFILE as a user variable to use your own.' -ForegroundColor DarkGray
if (Test-Path C:\Ops) { Set-Location C:\Ops }
Import-Module ActiveDirectory -ErrorAction SilentlyContinue
function Connect-Prod { Enter-PSSession prod-app-01 }