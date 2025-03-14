# Define remote access tools to monitor
$monitoredApps = @("mstsc.exe", "AnyDesk.exe", "TeamViewer.exe", "LogMeIn.exe", "ChromeRemoteDesktop.exe", "VNC.exe")

# Email Alert Settings
$emailParams = @{
    To = "admin@example.com"
    From = "security@example.com"
    Subject = "🚨 ALERT: Remote Access Detected!"
    SMTPServer = "smtp.example.com"
}

# Monitor Active Processes
$activeRemoteTools = Get-Process | Where-Object { $_.ProcessName -in $monitoredApps }

# If any remote access tool is running, send an alert
if ($activeRemoteTools) {
    $body = "The following remote access tools were detected running: `n`n"
    $body += ($activeRemoteTools.ProcessName -join "`n")

    # Add body content to email
    $emailParams["Body"] = $body

    # Send email alert
    Send-MailMessage @emailParams -ErrorAction SilentlyContinue

    Write-Host "🚨 Remote access detected! Email alert sent."
} else {
    Write-Host "✅ No unauthorized remote access tools detected."
}
