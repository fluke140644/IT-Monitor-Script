[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Version: 1.0.3
$currentVersion = "1.0.3"
$serverIP = "172.30.109.220"
$port = 5000
$hostname = $env:COMPUTERNAME

while ($true) {
    try {
        $random = [guid]::NewGuid().ToString()
        $remoteScript = Invoke-RestMethod -Uri "https://raw.githubusercontent.com/fluke140644/IT-Monitor-Script/refs/heads/main/client.ps1?t=$random" -UseBasicParsing
        
        if ($remoteScript -match "# Version:\s*([0-9.]+)") {
            $remoteVersion = $matches[1]
            
            if ([version]$remoteVersion -gt [version]$currentVersion) {
                $remoteScript | Out-File -FilePath $PSCommandPath -Encoding UTF8
                
                Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
                Exit
            }
        }
    } catch { 
        Write-Host "Update Error: $_" -ForegroundColor Red
    }
    
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $result = $tcpClient.BeginConnect($serverIP, $port, $null, $null)
        $success = $result.AsyncWaitHandle.WaitOne(3000, $true)

        if ($success) {
            $tcpClient.EndConnect($result)
            $stream = $tcpClient.GetStream()
            
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($hostname)
            $stream.Write($bytes, 0, $bytes.Length)
            
            $stream.Close()
            $tcpClient.Close()
        }
    } catch { }
    
    Start-Sleep -Seconds 30
}
