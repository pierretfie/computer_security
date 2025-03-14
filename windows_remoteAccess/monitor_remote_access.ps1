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

    # Check Event Logs for Recent Remote Logins
    $recentLogins = Get-WinEvent -LogName Security | Where-Object { $_.Id -in @(4624, 1149) } | Select-Object -First 5

    # If any remote access tool is running and has an active session, send an alert
    if ($activeRemoteTools -or $activeConnections -or $activeRdpSessions -or $recentLogins) {
        $body = "Remote Access Alert! `n`n"

        if ($activeRemoteTools) { 
            $body += "Running Remote Access Tools: `n" + ($activeRemoteTools.ProcessName -join "`n") + "`n`n"
        }

        if ($activeConnections) { 
            $body += "Active Remote Sessions Detected: `n" + ($activeConnections | Format-Table -AutoSize | Out-String) + "`n`n"
        }

        if ($activeRdpSessions) { 
            $body += "Active RDP Sessions Found! `n"
        }

        if ($recentLogins) { 
            $body += "Recent Remote Logins Detected: `n" + ($recentLogins | Format-Table -AutoSize | Out-String) + "`n`n"
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

        # Send Email
        Send-MailMessage @emailParams -ErrorAction SilentlyContinue
        Write-Host "Remote access detected! Email alert sent."
    } else {
        Write-Host "No active remote sessions detected."
    }

    # Wait for 5 minutes before checking again
    Write-Host "Waiting for 5 minutes before next check..."
    Start-Sleep -Seconds 300  # 300 seconds = 5 minutes
}