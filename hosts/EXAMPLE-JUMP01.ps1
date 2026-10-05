# Rename to <COMPUTERNAME>.ps1 and it loads only on that machine. Committed, so it follows you.
$env:HTTPS_PROXY = 'http://proxy.corp.example:8080'
Set-Location C:\Ops
Import-Module ActiveDirectory -ErrorAction SilentlyContinue
function Connect-Prod { Enter-PSSession prod-app-01 }
