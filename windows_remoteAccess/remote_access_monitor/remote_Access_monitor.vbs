Set objShell = CreateObject("WScript.Shell")
objShell.Run "powershell -ExecutionPolicy Bypass -File remote_access_monitor.ps1", 0, False
Set objShell = Nothing