[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;

# Version: 1.0.6
$currentVersion = "1.0.6";
$serverIP = "172.30.109.220";
$port = 5000;
$hostname =$env:COMPUTERNAME;

while ($true) {
    try {
        $random = [guid]::NewGuid().ToString();
        $remoteScript = Invoke-RestMethod -Uri "https://raw.githubusercontent.com/fluke140644/IT-Monitor-Script/refs/heads/main/client.ps1?t=$random" -UseBasicParsing;
        
        if ($remoteScript -match "# Version:\s*([0-9.]+)") {
            $remoteVersion =$matches[1];
            
            if ([version]$remoteVersion -gt [version]$currentVersion) {
                # ใช้วิธีเขียนไฟล์แบบ .NET เพื่อป้องกันปัญหาช่องว่างหายตอนก๊อปปี้
                [System.IO.File]::WriteAllText($PSCommandPath,$remoteScript, [System.Text.Encoding]::UTF8);
                
                Start-Process powershell -ArgumentList "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSCommandPath`"";
                Exit;
            }
        }
    } catch { 
        Write-Host "Update Error: $_" -ForegroundColor Red;
    }
    
    try {
        $vncService = Get-Service -Name "tvnserver" -ErrorAction SilentlyContinue;
        $hasVNC = if ($vncService -and$vncService.Status -eq 'Running') { "VNC:ON" } 
                  elseif ($vncService) { "VNC:Stop" } 
                  else { "VNC:No" };

        $anydeskService = Get-Service -Name "AnyDesk*" -ErrorAction SilentlyContinue;
        $anydeskProcess = Get-Process -Name "AnyDesk" -ErrorAction SilentlyContinue;
        $anydeskPath = (Test-Path "${env:ProgramFiles(x86)}\AnyDesk\AnyDesk.exe") -or (Test-Path "$env:ProgramFiles\AnyDesk\AnyDesk.exe");

        $hasAnyDesk = if (($anydeskService -and $anydeskService.Status -eq 'Running') -or$anydeskProcess) { "AD:ON" }
                      elseif ($anydeskService -or$anydeskPath) { "AD:Stop" }
                      else { "AD:No" };

        $payload = "$hostname ($hasVNC ,$hasAnyDesk)";

        $tcpClient = New-Object System.Net.Sockets.TcpClient;
        $result = $tcpClient.BeginConnect($serverIP, $port,$null, $null);$success = $result.AsyncWaitHandle.WaitOne(3000,$true);

        if ($success) {$tcpClient.EndConnect($result);$stream = $tcpClient.GetStream();$bytes = [System.Text.Encoding]::UTF8.GetBytes($payload);$stream.Write($bytes, 0,$bytes.Length);
            
            $stream.Close();$tcpClient.Close();
        }
    } catch { }
    
    Start-Sleep -Seconds 30;
}
