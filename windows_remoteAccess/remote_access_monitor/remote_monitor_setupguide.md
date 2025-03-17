# Remote Access Monitoring Guide

## 1. Preliminary Checks

### Check RDP Service Status
```powershell
# Check if RDP service is running
Get-Service -Name TermService | Select-Object Name, Status, StartType
```

### Check RDP Status
```powershell
# Check if RDP is enabled (0 = enabled, 1 = disabled)
$rdpStatus = (Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections").fDenyTSConnections
if ($rdpStatus -eq 0) {
    Write-Host "RDP is enabled" -ForegroundColor Green
} else {
    Write-Host "RDP is disabled" -ForegroundColor Red
}
```

### Monitor Third-Party Remote Access Tools
```powershell
# Check for running remote access applications
$remoteTools = @(
    "TeamViewer",
    "AnyDesk",
    "LogMeIn",
    "VNC",
    "ChromeRemoteDesktop"
)

Get-Process | Where-Object { 
    $_.ProcessName -match ($remoteTools -join '|') 
} | Select-Object ProcessName, Id, StartTime
```

## 2. Setting Up Automated Monitoring

### Step 1: Create VBS Wrapper Script
Create a new file named `run_monitor.vbs`:
```vbscript
Set objShell = CreateObject("WScript.Shell")
objShell.Run "powershell.exe -ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File ""C:\Scripts\remote_access_monitor.ps1""", 0, False
```

### Step 2: Configure Task Scheduler

1. **Open Task Scheduler**
   - Run `taskschd.msc`
   - Or search "Task Scheduler" in Start menu

2. **Create New Task**
   - Right-click "Task Scheduler Library"
   - Select "Create Task" (not "Basic Task")

3. **General Tab Settings**
   - Name: "RDP Monitor Script"
   - Description: "Monitor remote accesses"
   - Security Options:
     - ✅ Run with highest privileges
   - Configure for: Your Windows version

4. **Triggers Tab**
   Add two triggers:
   
   A. Logon Trigger:
   - On logon
   - Repetition:
     - ✅ Repeat task every: 5 minutes
     - ✅ For a duration of: 1 day
     - ✅ Enabled
   
   B. Daily Trigger:
   - One time per day
   - Recur every: 1 day
   - ✅ Enabled

5. **Actions Tab**
   - Action: Start a program
   - Program/script: `wscript.exe`
   - Arguments: `"C:\Users\[username]\Desktop\remote_access_monitor.vbs"`

6. **Settings Tab**
   - ✅ Allow task to be run on demand
   - ✅ Run task as soon as possible after a scheduled start is missed
   - Execution time limit: 72 hours
   - ✅ Start when available
   - Multiple instances: Ignore new instance
   - Task priority: 7 (Above normal)

7. **Additional Settings**
   - Stop task if runs longer than: 72 hours
   - If task is already running: Do not start a new instance

### Step 3: Test the Setup

1. **Manual Test**
   - Right-click the task → "Run"
   - Check Task History for success/failure
   - Verify email alerts are received

2. **Monitor Script Logs**
   - Check Windows Event Viewer
   - Application and Services Logs
   - Microsoft → Windows → TaskScheduler

## 3. Troubleshooting

### Common Issues:
1. **Task not running:**
   - Check "History" tab in Task Scheduler
   - Verify account permissions
   - Check script paths are correct

2. **No email alerts:**
   - Test SMTP settings
   - Check firewall rules
   - Verify email credentials

3. **Missing events:**
   - Run PowerShell as Administrator
   - Enable required Event Log channels
   - Check Event Viewer permissions

### Useful Commands for Troubleshooting
```powershell
# Test email settings
Send-MailMessage -From $fromEmail -To $toEmail -Subject "Test" -Body "Test" -SmtpServer $smtpServer -Port $smtpPort -UseSsl -Credential $credential

# Check Event Log status
Get-WinEvent -ListLog "Microsoft-Windows-TerminalServices-*" | Select-Object LogName, IsEnabled

# Verify script execution policy
Get-ExecutionPolicy
```

## 4. Maintenance

- Review and update monitored applications list regularly
- Check email alert settings monthly
- Monitor disk space for log files
- Update PowerShell scripts as needed
- Review security permissions periodically

