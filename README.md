# computer_security

# Remote Access Monitor

A PowerShell script that monitors and alerts administrators about remote access activities on Windows systems, including RDP connections and various remote access tools.
files under remote_access_monitor folder
## Features

- Monitors multiple remote access tools:
  - Remote Desktop (RDP)
  - AnyDesk
  - TeamViewer
  - LogMeIn
  - Chrome Remote Desktop
  - VNC

- Detects and reports:
  - Active remote access processes
  - Network connections from remote access tools
  - RDP authentication events
  - Active RDP sessions
  - User login details (username and source IP)

- Alert System:
  - Sends consolidated email alerts
  - Includes detailed information about detected remote access
  - Throttles alerts (one alert per 10 minutes)
  - Uses SSL for secure email transmission

## Prerequisites

- Windows Operating System
- PowerShell 5.1 or higher
- Administrator privileges
- SMTP email account (e.g., Gmail)
- If using Gmail:
  - Enable 2-factor authentication
  - Generate an App Password

## Configuration

1. Open `remote_access_monitor.ps1`
2. Update the email settings:
```powershell
$fromEmail = "your-email@gmail.com"
$toEmail = "admin@example.com"
$smtpServer = "smtp.gmail.com"
$smtpPort = 587
$smtpUser = "your-email@gmail.com"
$smtpPassword = "your-app-password"
```

## Usage

1. Configure email settings in the script
2. Run PowerShell as Administrator
3. Navigate to script directory
4. Execute the script:
```powershell
.\remote_access_monitor.ps1
```

## Alert Format

The email alert includes:
- RDP Authentication Details (if any)
  - Login Time
  - Username
  - Source IP Address
- Running Remote Access Tools
- Active Network Connections
- Active RDP Sessions

## Monitoring Interval

- Checks for remote access every 5 minutes
- Alerts are throttled to maximum one per 10 minutes
- Monitors events from the last 10 minutes

## Security Considerations

- Store email credentials securely
- Run with appropriate permissions
- Monitor script logs for proper operation
- Review and adjust monitoring intervals as needed

## Customization

You can modify:
- List of monitored applications (`$monitoredApps`)
- Check interval (default: 5 minutes)
- Alert throttle time (default: 10 minutes)
- Event monitoring window (default: 10 minutes)

## Troubleshooting

If no alerts are received:
1. Check email settings
2. Verify SMTP server access
3. Check Windows Event Log access
4. Run script with administrator privileges

## License

[Specify your license here]

## Author

[maina350p]