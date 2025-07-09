# Run as Admin!
# If needed, run: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# Catching path for log file
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$logFile = "$scriptDir\log.txt"

Function Log {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Out-File -FilePath $logFile -Append
    Write-Host $message
}

Log "========== Starting Settings =========="

# --------------------------
# INSTALL PROGRAMS WITH WINGET
# --------------------------

Log "Trying to install program with Winget..."

$apps = @(
    "Google.Chrome",
    "Microsoft.DotNet.DesktopRuntime.6",
    "RARLab.WinRAR",
    "Microsoft.Office"
)

foreach ($app in $apps) {
    Log "Installing: $app"
    winget install --id=$app -e --accept-source-agreements --accept-package-agreements >> $logFile 2>&1
}

# --------------------------
# SYSTEM SETTINGS
# --------------------------

Log "Desable TaskBar's widgets..."
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarDa /t REG_DWORD /d 0 /f >> $logFile 2>&1

Log "Desable TaskView button..."
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowTaskViewButton /t REG_DWORD /d 0 /f >> $logFile 2>$1

#  Windows Update
Log "Verifying Windows updates..."
try {
    Install-Module PSWindowsUpdate -Force -Confirm:$false -Scope CurrentUser >> $logFile 2>&1
    Import-Module PSWindowsUpdate >> $logFile 2>&1
    Get-WindowsUpdate -AcceptAll -Install -AutoReboot >> $logFile 2>&1
} catch {
    Log "Updates verification error: $_"
}

# --------------------------
# REMOVE BLOATWARE
# --------------------------

Log "Removing bloatware..."
$bloatApps = @("*xbox*", "*bing*", "*gethelp*", "*skypeapp*", "*feedback*", "*yourphone*", "*people*", "*solitaire*")

foreach ($app in $bloatApps) {
    Log "Removing: $app"
    Get-AppxPackage -Name $app | Remove-AppxPackage -ErrorAction SilentlyContinue >> $logFile 2>&1
}

# --------------------------
# UNINSTALL COPILOT
# --------------------------

Log "Removing Windows Copilot..."
reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f >> $logFile 2>&1
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f >> $logFile 2>&1

# --------------------------
# PERFORMANCE SETTINGS (Opcional)
# --------------------------

$resp = Read-Host "Want to apply performance settings? (y/n)"

if ($resp -eq "y" -or $resp -eq "Y") {
    Log "Applying performance settings..."

    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    Set-ItemProperty -Path $regPath -Name VisualFXSetting -Value 2 >> $logFile 2>&1

    $effects = @{
        "AnimateMinMax" = 0
        "ComboBoxAnimation" = 0
        "CursorShadow" = 0
        "DropShadow" = 1
        "ListBoxSmoothScrolling" = 0
        "MenuAnimation" = 0
        "MenuFade" = 0
        "SelectionFade" = 0
        "TooltipAnimation" = 0
        "WindowAnimation" = 0
        "FontSmoothing" = 1
        "DragFullWindows" = 1
    }

    $regEffectsPath = "HKCU:\Control Panel\Desktop"

    foreach ($key in $effects.Keys) {
        Set-ItemProperty -Path $regEffectsPath -Name $key -Value $effects[$key] >> $logFile 2>&1
    }

    rundll32.exe user32.dll,UpdatePerUserSystemParameters
    Log "Visual effects settings applied."

    Log "Setting power mode: Max Performance..."
    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 >> $logFile 2>&1
    powercfg -setactive e9a42b02-d5df-448d-aa00-03f14749eb61 >> $logFile 2>&1
    Log "Power mode defined."
} else {
    Log "Performance settings ignored."
}

Log "========== End configuration =========="
