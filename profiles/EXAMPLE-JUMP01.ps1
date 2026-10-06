# Rename to the value of PSENV_PROFILE on the box (or its machine name) and it loads there. Committed, so it follows you.
$env:HTTPS_PROXY = 'http://proxy.corp.example:8080'
Set-Location C:\Ops
Import-Module ActiveDirectory -ErrorAction SilentlyContinue
function Connect-Prod { Enter-PSSession prod-app-01 }
