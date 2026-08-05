# Version: 1.0
$currentVersion = "1.0"
$serverIP = "172.30.10.169"
$port = 5000
$hostname = $env:COMPUTERNAME

# ลิงก์สำหรับโหลดไฟล์โค้ดเวอร์ชันใหม่ (เช่น ลิงก์ Raw จาก GitHub)
$updateUrl = "https://raw.githubusercontent.com/ชื่อผู้ใช้/ชื่อโปรเจกต์/main/client.ps1"

while ($true) {
    try {
        $random = [guid]::NewGuid().ToString()
        $remoteScript = Invoke-RestMethod -Uri "$updateUrl?t=$random" -UseBasicParsing
        
        if ($remoteScript -match "# Version:\s*([0-9.]+)") {
            $remoteVersion = $matches[1]
            
            if ([version]$remoteVersion -gt [version]$currentVersion) {
                
                $remoteScript | Out-File -FilePath $PSCommandPath -Encoding UTF8
                
                Start-Process powershell -ArgumentList "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSCommandPath`""
                
                Exit
            }
        }
    } catch {
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
    } catch {}
    
    Start-Sleep -Seconds 60
}
