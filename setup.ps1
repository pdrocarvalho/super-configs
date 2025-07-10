# Run as Admin!
# If needed, run: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# Catching path for log file
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$logFile = "$scriptDir\log.txt"

function Log {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Out-File -FilePath $logFile -Append
}

function Show-Status {
    param(
	[string]$action,
	[scriptblock]$command
    )

    $dots = '.' * (50 - $action.Length)
    Write-Host -NoNewLine "$action$dots"

    try {
	& $command
	Write-Host "[  " -NoNewLine
	Write-Host "OK" -ForegroundColor Green -NoNewLine
	Write-Host "  ]"
	Log "$action - SUCCED" 
    } catch { 
	Write-Host "[" -NoNewLine
	Write-Host "FAILED" -ForegroundColor Red -NoNewLine
	Write-Host "]" 
	Log "$action - FAILED: $_"
    }
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
    Show-Status "Installing: $app"{ winget install --id=$app -e --accept-source-agreements --accept-package-agreements >> $logFile 2>&1 }
    }


# --------------------------
# SYSTEM SETTINGS
# --------------------------

Show-Status "Desable TaskBar's widgets" { 
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarDa /t REG_DWORD /d 0 /f >> $logFile 2>&1
}

Show-Status "Desable TaskView button" {
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowTaskViewButton /t REG_DWORD /d 0 /f >> $logFile 2>$1
}
#  Windows Update
Show-Status "Verifying Windows updates" {
try {
    Install-Module PSWindowsUpdate -Force -Confirm:$false -Scope CurrentUser >> $logFile 2>&1
    Import-Module PSWindowsUpdate >> $logFile 2>&1
    Get-WindowsUpdate -AcceptAll -Install -AutoReboot >> $logFile 2>&1
} catch {
    Log "Updates verification error: $_"
}
}

# --------------------------
# REMOVE BLOATWARE
# --------------------------

Log "Removing bloatware..."
$bloatApps = @("*xbox*", "*bing*", "*gethelp*", "*skypeapp*", "*feedback*", "*yourphone*", "*people*", "*solitaire*")

foreach ($app in $bloatApps) {
    Show-Status "Removing: $app" {
    Get-AppxPackage -Name $app | Remove-AppxPackage -ErrorAction SilentlyContinue >> $logFile 2>&1
    }
}


# --------------------------
# UNINSTALL COPILOT
# --------------------------

Show-Status "Removing Windows Copilot"{
reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f >> $logFile 2>&1
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f >> $logFile 2>&1
}

# --------------------------
# PERFORMANCE SETTINGS (Opcional)
# --------------------------

$resp = Read-Host "Want to apply performance settings? (y/n)"

if ($resp -eq "y" -or $resp -eq "Y") {

    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    
    Show-Status "Applying performance settings" {
    Set-ItemProperty -Path $regPath -Name VisualFXSetting -Value 2 >> $logFile 2>&1
    }

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
	Show-Status "Setting $key" {
        Set-ItemProperty -Path $regEffectsPath -Name $key -Value $effects[$key] >> $logFile 2>&1
	}
    }

    rundll32.exe user32.dll,UpdatePerUserSystemParameters
    Log "Visual effects settings applied."

    Show-Status "Setting power mode: Max Performance"{
    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 >> $logFile 2>&1
    powercfg -setactive e9a42b02-d5df-448d-aa00-03f14749eb61 >> $logFile 2>&1
    }
} else {
    Log "Performance settings ignored."
}

Log "========== End configuration =========="
