<#
.SYNOPSIS
    Is it up, and is the port I care about open? For one box or a list of them.
.EXAMPLE
    Test-Endpoint jump01, prod-app-01
    Get-Content .\servers.txt | Test-Endpoint -Port 3389 -Log C:\Logs\reach.log
.NOTES
    Lives in pwsh-env/scripts, so it is a command on every machine. -Log uses Write-Log
    from the PoshMTLogging submodule, which autoloads from pwsh-env/modules. Scripts calling
    modules from the same repo is the point.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
    [string[]]$ComputerName,
    [int]$Port = 5985,           # WinRM. 3389 RDP, 22 SSH, 443 whatever is pretending to be secure.
    [int]$TimeoutMs = 1500,
    [string]$Log
)

process {
    foreach ($name in $ComputerName) {
        $ping = Test-Connection $name -Count 1 -Quiet -TimeoutSeconds ([math]::Ceiling($TimeoutMs / 1000)) -ErrorAction SilentlyContinue

        $tcp = [Net.Sockets.TcpClient]::new()
        $open = try   { $tcp.ConnectAsync($name, $Port).Wait($TimeoutMs) -and $tcp.Connected }
                catch { $false }
                finally { $tcp.Dispose() }

        $result = [pscustomobject]@{
            ComputerName = $name
            Ping         = $ping
            Port         = $Port
            PortOpen     = $open
            Checked      = Get-Date
        }

        if ($Log) {
            $level = if ($open) { 'INFO' } elseif ($ping) { 'WARN' } else { 'ERROR' }
            Write-Log -text "$name ping=$ping port$Port=$open" -level $level -log $Log
        }

        $result
    }
}
