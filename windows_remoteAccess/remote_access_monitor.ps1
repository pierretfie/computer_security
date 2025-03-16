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
        # Check RDP Connection and Authentication Events with user details
        Get-WinEvent -FilterHashtable @{
            LogName="Microsoft-Windows-TerminalServices-RemoteConnectionManager/Operational"
            ID=1149  # Authentication Success
            StartTime=(Get-Date).AddMinutes(-10)
        } -ErrorAction SilentlyContinue | 
        Select-Object TimeCreated,
            @{Name='Event';Expression={'RDP Authentication Success'}},
            @{Name='Username';Expression={$_.Properties[0].Value}},
            @{Name='SourceIP';Expression={$_.Properties[2].Value}}

        # Check RDP Session Events with user details
        Get-WinEvent -FilterHashtable @{
            LogName="Microsoft-Windows-TerminalServices-LocalSessionManager/Operational"
            ID=@(21,23,24,25)  # Session events
            StartTime=(Get-Date).AddMinutes(-10)
        } -ErrorAction SilentlyContinue |
        Select-Object TimeCreated,
            @{Name='Event';Expression={
                switch ($_.ID) {
                    21 {'RDP Session Logon'}
                    23 {'RDP Session Logoff'}
                    24 {'RDP Session Disconnected'}
                    25 {'RDP Session Reconnected'}
                }
            }},
            @{Name='Username';Expression={$_.Properties[0].Value}},
            @{Name='SourceIP';Expression={$_.Properties[2].Value}}
    )

    # If RDP or any remote access tool is running, send an alert
    if ($activeRemoteTools -or $activeRdpSessions -or $recentEvents) {
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
                Format-Table TimeCreated, Event, Username, SourceIP -AutoSize |
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