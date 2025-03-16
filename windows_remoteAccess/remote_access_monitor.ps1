# Define remote access tools to monitor
$monitoredApps = @("mstsc.exe", "AnyDesk.exe", "TeamViewer.exe", "LogMeIn.exe", "ChromeRemoteDesktop.exe", "VNC.exe")

# Email Alert Settings (Replace with your actual credentials)
$fromEmail = "your-email@gmail.com"  # Replace with your email
$toEmail = "admin@example.com"  # Replace with the recipient email
$smtpServer = "smtp.gmail.com"  # Use your SMTP server (Gmail, Outlook, etc.)
$smtpPort = 587
$smtpUser = "your-email@gmail.com"  # Replace with your email
$smtpPassword = "your-app-password"  # Use Gmail App Password (Not your normal password!)


# Infinite Loop - Runs every 5 minutes
while ($true) {
    Write-Host "Checking for active remote access connections..."

    # Monitor Active Processes
    $activeRemoteTools = Get-Process | Where-Object { $_.ProcessName -in $monitoredApps }

    # Check Active Network Connections for Remote Access Tools
    $activeConnections = Get-NetTCPConnection | Where-Object { $_.RemoteAddress -ne '127.0.0.1' -and $_.OwningProcess -in ($activeRemoteTools.Id) }

    # Check for Active RDP Sessions
    $activeRdpSessions = query session | Select-String "rdp-tcp"

    # Check Event Logs for Recent Remote Access Activity
    $recentEvents = @(
        # Check RDP Connection and Authentication Events
        Get-WinEvent -FilterHashtable @{
            LogName="Microsoft-Windows-TerminalServices-RemoteConnectionManager/Operational"
            StartTime=(Get-Date).AddMinutes(-10)
        } -ErrorAction SilentlyContinue |
        Where-Object { $_.Id -in @(1149, 261) } # 1149 = Authentication Success, 261 = New Connection

        # Check RDP Session Events
        Get-WinEvent -FilterHashtable @{
            LogName="Microsoft-Windows-TerminalServices-LocalSessionManager/Operational"
            StartTime=(Get-Date).AddMinutes(-10)
        } -ErrorAction SilentlyContinue
    )

    # If RDP or any remote access tool is running, send an alert
    if ($activeRemoteTools -or $activeRdpSessions) {
        $body = "Remote Access Alert! `n`n"

        if ($activeRemoteTools) { 
            $body += "Running Remote Access Tools: `n" + ($activeRemoteTools | Format-Table -Property ProcessName, StartTime, Id -AutoSize | Out-String) + "`n`n"
        }

        if ($activeConnections) { 
            $body += "Active Remote Sessions Detected: `n" + ($activeConnections | Format-Table -AutoSize | Out-String) + "`n`n"
        }

        if ($activeRdpSessions) { 
            $body += "Active RDP Sessions Found! `n"
        }

        if ($recentEvents) {
            $body += "Recent Remote Access Activity: `n"
            $body += ($recentEvents | 
                Select-Object TimeCreated, Id,
                @{Name='Event';Expression={
                    switch ($_.Id) {
                        1149 {'RDP Authentication Success'}
                        261 {'RDP Connection Attempt'}
                        21 {'RDP Session Logon'}
                        23 {'RDP Session Logoff'}
                        24 {'RDP Session Disconnected'}
                        25 {'RDP Session Reconnected'}
                        default {"Event ID: $($_.Id)"}
                    }
                }},
                Message |
                Format-Table -AutoSize |
                Out-String)
        }

        # Email Parameters
        $emailParams = @{
            From       = $fromEmail
            To         = $toEmail
            Subject    = "Remote Access Alert!"
            Body       = $body
            SmtpServer = $smtpServer
            Port       = $smtpPort
            Credential = New-Object System.Management.Automation.PSCredential ($smtpUser, (ConvertTo-SecureString $smtpPassword -AsPlainText -Force))
            UseSsl     = $true
        }

        # Check if enough time has passed since the last alert
        $currentTime = Get-Date
        if (-not $lastAlertTime -or ($currentTime - $lastAlertTime).TotalMinutes -ge 10) {
            # Send Email
            Send-MailMessage @emailParams -ErrorAction SilentlyContinue
            Write-Host "Remote access detected! Email alert sent."
            $lastAlertTime = $currentTime
        } else {
            Write-Host "Remote access detected, but alert throttled. Last alert sent at: $lastAlertTime"
        }
    } else {
        Write-Host "No active remote sessions detected."
    }

    # Wait for 5 minutes before checking again
    Write-Host "Waiting for 5 minutes before next check..."
    Start-Sleep -Seconds 300  # 300 seconds = 5 minutes
}