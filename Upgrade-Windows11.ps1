# ============================================================
# Windows 11 In-Place Upgrade with Full Bypass (CPU/TPM)
# - Interactive menu with drive selection (option 5)
# - Checks compatibility, disk space, ISO language (reliable)
# - Runs upgrade with bypasses when selected
# ============================================================

# --- Ensure script runs as Administrator (self-elevates via UAC if needed) ---
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "`n[INFO] Elevating to Administrator..." -ForegroundColor Cyan
    $scriptPath = if ($PSCommandPath) { $PSCommandPath } else { $MyInvocation.MyCommand.Path }
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
    exit
}

# --- Theme colors (exactly like RDP Multi-Session Enabler) ---
$bannerColor = "Cyan"
$menuColor = "Cyan"
$infoColor = "Cyan"
$successColor = "Green"
$errorColor = "Red"
$warningColor = "Yellow"

# --- Global variables ---
$patchAppraiser = $true
$tempFolder = "C:\Win11_Upgrade_Temp"
$global:ISODrive = $null
$global:DisclaimerShown = $false

# --- Display Banner (exact RDP Multi-Session Enabler style) ---
function Show-Banner {
    Clear-Host
    Write-Host "=============================================" -ForegroundColor $bannerColor
    Write-Host "  Windows 11 Upgrade Assistant (Bypass Mode)  " -ForegroundColor $bannerColor
    Write-Host "               v1.0                            " -ForegroundColor $bannerColor
    Write-Host "=============================================" -ForegroundColor $bannerColor
    Write-Host ""
}

# --- Display Disclaimer (once) ---
function Show-Disclaimer {
    Write-Host "=============================================" -ForegroundColor $errorColor
    Write-Host "           IMPORTANT DISCLAIMER              " -ForegroundColor $errorColor
    Write-Host "=============================================" -ForegroundColor $errorColor
    Write-Host "This script bypasses Windows 11 hardware requirements"
    Write-Host "(CPU, TPM, SecureBoot, RAM, storage)."
    Write-Host ""
    Write-Host "Bypassing these checks may lead to:"
    Write-Host "  - System instability or crashes"
    Write-Host "  - Inability to receive future Windows updates"
    Write-Host "  - Voided warranty or support from Microsoft"
    Write-Host ""
    Write-Host "ALWAYS BACK UP YOUR IMPORTANT DATA before proceeding."
    Write-Host "Use this script at your own risk."
    Write-Host ""
    Write-Host "Press Enter to continue or Ctrl+C to exit..."
    Read-Host
}

if (-not $global:DisclaimerShown) {
    Show-Disclaimer
    $global:DisclaimerShown = $true
}

# --- Helper: Normalize drive letter ---
function Normalize-Drive {
    param([string]$drive)
    return $drive.TrimEnd('\').TrimEnd(':').ToUpper() + ':'
}

# --- Helper: Validate a drive letter ---
function Test-ISODrive {
    param([string]$driveLetter)
    $drive = Normalize-Drive $driveLetter
    $setupPath = "$drive\setup.exe"
    $installWim = "$drive\sources\install.wim"
    $installEsd = "$drive\sources\install.esd"
    return (Test-Path $setupPath) -and ((Test-Path $installWim) -or (Test-Path $installEsd))
}

# --- Helper: Prompt for ISO drive ---
function Set-ISODrive {
    Write-Host "Enter the drive letter where the Windows 11 ISO is mounted (e.g., D:):" -ForegroundColor $infoColor
    $drive = Read-Host
    if ([string]::IsNullOrWhiteSpace($drive)) {
        Write-Host "[ERROR] No drive letter entered." -ForegroundColor $errorColor
        return $false
    }
    $drive = Normalize-Drive $drive
    if (Test-ISODrive $drive) {
        $global:ISODrive = $drive
        Write-Host "[SUCCESS] ISO drive set to $global:ISODrive" -ForegroundColor $successColor
        return $true
    } else {
        Write-Host "[ERROR] No valid Windows installation found on $drive. Please mount the ISO and try again." -ForegroundColor $errorColor
        return $false
    }
}

# --- Reliable ISO language detection using dism ---
function Get-ISOLanguage {
    param([string]$driveLetter)
    $drive = Normalize-Drive $driveLetter
    $langIni = "$drive\sources\lang.ini"
    if (Test-Path $langIni) {
        $content = Get-Content $langIni -Raw
        if ($content -match 'DefaultLanguage\s*=\s*([A-Za-z-]+)') {
            return $matches[1]
        }
    }
    $bootWim = "$drive\sources\boot.wim"
    if (Test-Path $bootWim) {
        try {
            $output = & dism /Get-ImageInfo /ImageFile:"$bootWim" /Index:1 2>$null
            foreach ($line in $output) {
                if ($line -match 'Language:\s*([A-Za-z-]+)') {
                    return $matches[1]
                }
            }
        } catch {
            # ignore
        }
    }
    return $null
}

# --- Option 1: Check Windows 11 compatibility ---
function Check-Compatibility {
    Show-Banner
    Write-Host "Windows 11 Compatibility Check" -ForegroundColor $bannerColor
    Write-Host ""
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $cpuName = $cpu.Name
    Write-Host "CPU: $cpuName ($($cpu.NumberOfCores) cores)"
    if ($cpuName -match "Intel.*?-(\d{4,5})") {
        $modelNum = $matches[1]
        $gen = [int]($modelNum.Substring(0, $modelNum.Length - 3))
        if ($gen -ge 8) {
            Write-Host "  CPU generation: $gen (supports Windows 11)" -ForegroundColor $successColor
        } else {
            Write-Host "  CPU generation: $gen (may not be officially supported)" -ForegroundColor $warningColor
        }
    } else {
        Write-Host "  CPU model may not be officially supported." -ForegroundColor $warningColor
    }
    $tpm = Get-Tpm
    if ($tpm.TpmPresent) {
        Write-Host "TPM: Present, version $($tpm.TpmVersion)" -ForegroundColor $successColor
    } else {
        Write-Host "TPM: Not present or not detected" -ForegroundColor $errorColor
    }
    $secureBoot = Confirm-SecureBootUEFI
    if ($secureBoot) {
        Write-Host "SecureBoot: Enabled" -ForegroundColor $successColor
    } else {
        Write-Host "SecureBoot: Disabled or not supported" -ForegroundColor $errorColor
    }
    $ram = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB
    Write-Host "RAM: $([math]::Round($ram,2)) GB"
    if ($ram -ge 4) {
        Write-Host "  RAM meets minimum requirement (4 GB)" -ForegroundColor $successColor
    } else {
        Write-Host "  RAM is below minimum requirement (4 GB)" -ForegroundColor $errorColor
    }
    $drive = Get-PSDrive -Name $env:SystemDrive.TrimEnd(':')
    $free = $drive.Free / 1GB
    Write-Host "Free disk space on $env:SystemDrive : $([math]::Round($free,2)) GB"
    if ($free -ge 64) {
        Write-Host "  Disk space meets recommended requirement (64 GB)" -ForegroundColor $successColor
    } else {
        Write-Host "  Disk space is below recommended (64 GB)" -ForegroundColor $warningColor
    }
    Write-Host "`n[NOTE] This script bypasses these checks, so you can still upgrade." -ForegroundColor $infoColor
}

# --- Option 2: Check disk space for upgrade ---
function Check-DiskSpace {
    Show-Banner
    Write-Host "Disk Space Check for Upgrade" -ForegroundColor $bannerColor
    Write-Host ""
    $systemDrive = Get-PSDrive -Name $env:SystemDrive.TrimEnd(':')
    $freeSys = $systemDrive.Free / 1GB
    Write-Host "$env:SystemDrive free space: $([math]::Round($freeSys,2)) GB"
    if ($freeSys -lt 20) {
        Write-Host "  [WARNING] Less than 20 GB free. Upgrade may fail due to insufficient space." -ForegroundColor $errorColor
    } elseif ($freeSys -lt 40) {
        Write-Host "  [WARNING] Recommended at least 40 GB free for a smooth upgrade." -ForegroundColor $warningColor
    } else {
        Write-Host "  [OK] Sufficient space detected." -ForegroundColor $successColor
    }
    $tempDriveLetter = $tempFolder.Split(':')[0]
    if ($tempDriveLetter -ne $env:SystemDrive.TrimEnd(':')) {
        $tempDrive = Get-PSDrive -Name $tempDriveLetter
        $freeTemp = $tempDrive.Free / 1GB
        Write-Host "$tempDriveLetter`: free space: $([math]::Round($freeTemp,2)) GB"
        if ($freeTemp -lt 6) {
            Write-Host "  [WARNING] Less than 6 GB free on $tempDriveLetter`. Temporary copy of ISO may fail." -ForegroundColor $errorColor
        }
    }
}

# --- Option 3: Check ISO language compatibility ---
function Check-ISOLanguage {
    Show-Banner
    Write-Host "ISO Language Compatibility" -ForegroundColor $bannerColor
    Write-Host ""
    if (-not $global:ISODrive) {
        Write-Host "[WARNING] No ISO drive set. Please set it first (option 5)." -ForegroundColor $warningColor
        if (Set-ISODrive) {
            Write-Host "[INFO] ISO drive set to $global:ISODrive" -ForegroundColor $successColor
        } else {
            return
        }
    }
    $isoLang = Get-ISOLanguage -driveLetter $global:ISODrive
    $currentLang = (Get-WinSystemLocale).Name
    if ($isoLang) {
        Write-Host "ISO language detected: $isoLang" -ForegroundColor $infoColor
    } else {
        Write-Host "[WARNING] Could not determine ISO language. Please verify manually." -ForegroundColor $warningColor
    }
    Write-Host "Current system language: $currentLang"
    if ($isoLang -and $isoLang -ne $currentLang) {
        Write-Host "`n[WARNING] The ISO language does NOT match your current system language." -ForegroundColor $errorColor
        Write-Host "If you proceed with the upgrade, Windows Setup will perform a clean install (all apps and files will be deleted)." -ForegroundColor $errorColor
        Write-Host "To keep your files, please mount an ISO with the same language as your current OS." -ForegroundColor $warningColor
    } elseif (-not $isoLang) {
        Write-Host "`n[WARNING] Language unknown. Proceed with caution." -ForegroundColor $warningColor
    } else {
        Write-Host "[OK] Language matches. Upgrade should preserve apps and files." -ForegroundColor $successColor
    }
}

# --- Option 4: Perform upgrade (bypass) ---
function Invoke-Upgrade {
    Show-Banner
    Write-Host "Starting Windows 11 Upgrade" -ForegroundColor $bannerColor
    Write-Host ""
    if (-not $global:ISODrive) {
        Write-Host "[WARNING] No ISO drive set. Please set it first (option 5)." -ForegroundColor $warningColor
        if (Set-ISODrive) {
            Write-Host "[INFO] ISO drive set to $global:ISODrive" -ForegroundColor $successColor
        } else {
            return
        }
    }
    $isoLang = Get-ISOLanguage -driveLetter $global:ISODrive
    $currentLang = (Get-WinSystemLocale).Name
    if ($isoLang -and $isoLang -ne $currentLang) {
        Write-Host "=============================================" -ForegroundColor $errorColor
        Write-Host "          !!! CRITICAL WARNING !!!            " -ForegroundColor $errorColor
        Write-Host "=============================================" -ForegroundColor $errorColor
        Write-Host "The ISO language ($isoLang) does NOT match your current system language ($currentLang)." -ForegroundColor $errorColor
        Write-Host "If you continue, Windows Setup will perform a CLEAN INSTALL, which will remove ALL your apps, settings, and personal files." -ForegroundColor $errorColor
        Write-Host "This is irreversible." -ForegroundColor $errorColor
        Write-Host ""
        Write-Host "To keep your files and apps, you must use an ISO with the same language as your current Windows installation." -ForegroundColor $warningColor
        $confirm = Read-Host "Type 'CONTINUE' to proceed with the clean install (or press Enter to cancel)"
        if ($confirm -ne "CONTINUE") {
            Write-Host "[CANCELLED] Upgrade cancelled." -ForegroundColor $warningColor
            return
        }
        Write-Host "[WARNING] Proceeding with clean install (all data will be lost)." -ForegroundColor $errorColor
    } elseif (-not $isoLang) {
        Write-Host "[WARNING] Could not determine ISO language. Upgrading may risk data loss if language mismatches." -ForegroundColor $warningColor
        $confirm = Read-Host "Type 'CONTINUE' to proceed anyway (or press Enter to cancel)"
        if ($confirm -ne "CONTINUE") {
            Write-Host "[CANCELLED] Upgrade cancelled." -ForegroundColor $warningColor
            return
        }
    }
    $setupPath = "$global:ISODrive\setup.exe"
    $regPath = "HKLM:\SYSTEM\Setup\LabConfig"
    if (!(Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
    $bypassKeys = @{
        "BypassCPUCheck" = 1
        "BypassTPMCheck" = 1
        "BypassSecureBootCheck" = 1
        "BypassRAMCheck" = 1
        "BypassStorageCheck" = 1
    }
    foreach ($key in $bypassKeys.Keys) {
        New-ItemProperty -Path $regPath -Name $key -Value $bypassKeys[$key] -PropertyType DWord -Force | Out-Null
    }
    Write-Host "[OK] Registry bypass keys added." -ForegroundColor $successColor
    function Remove-BypassKeys {
        foreach ($key in $bypassKeys.Keys) { Remove-ItemProperty -Path $regPath -Name $key -Force -ErrorAction SilentlyContinue }
        Write-Host "[OK] Registry bypass keys removed." -ForegroundColor $successColor
    }
    Write-Host "`n[INFO] The '/product server' switch will make Setup display 'Installing Windows Server'." -ForegroundColor $infoColor
    Write-Host "[INFO] This is normal - you are still installing Windows 11." -ForegroundColor $infoColor
    Write-Host "Press Enter to start the upgrade..."
    Read-Host
    Write-Host "[INFO] Method 1: Running Setup with '/product server'..." -ForegroundColor $infoColor
    $arguments1 = "/product server /auto upgrade /noreboot /compat IgnoreWarning /telemetry disable"
    $proc1 = Start-Process -FilePath $setupPath -ArgumentList $arguments1 -Wait -PassThru -NoNewWindow
    $exit1 = $proc1.ExitCode
    if ($exit1 -eq 0) {
        Write-Host "[SUCCESS] Setup succeeded with /product server. The system may need to reboot." -ForegroundColor $successColor
        Remove-BypassKeys
        return
    } else {
        Write-Host "[ERROR] Method 1 failed with exit code $exit1." -ForegroundColor $errorColor
        $logPaths = @("$env:SystemRoot\Panther\setuperr.log","$env:SystemDrive\`$WINDOWS.~BT\Sources\Panther\setuperr.log")
        foreach ($log in $logPaths) { if (Test-Path $log) { Write-Host "`n--- Last 10 lines of $log ---" -ForegroundColor $warningColor; Get-Content $log -Tail 10 } }
    }
    if ($patchAppraiser) {
        Write-Host "[INFO] Method 2: Patching appraiserres.dll..." -ForegroundColor $infoColor
        if (Test-Path $tempFolder) { Remove-Item -Path $tempFolder -Recurse -Force -ErrorAction SilentlyContinue }
        Write-Host "[INFO] Copying ISO contents to $tempFolder (may take a few minutes)..." -ForegroundColor $infoColor
        try { Copy-Item -Path "$global:ISODrive\*" -Destination $tempFolder -Recurse -Force -ErrorAction Stop; Write-Host "[OK] Copy successful." -ForegroundColor $successColor }
        catch { Write-Host "[ERROR] Failed to copy ISO contents: $_" -ForegroundColor $errorColor; return }
        $appraiserPath = "$tempFolder\sources\appraiserres.dll"
        if (Test-Path $appraiserPath) { $null = New-Item -Path $appraiserPath -ItemType File -Force; Write-Host "[OK] Patched appraiserres.dll." -ForegroundColor $successColor }
        $patchedSetup = "$tempFolder\setup.exe"
        Write-Host "[INFO] Launching Setup from patched media..." -ForegroundColor $infoColor
        $arguments2 = "/auto upgrade /noreboot /compat IgnoreWarning /telemetry disable"
        $proc2 = Start-Process -FilePath $patchedSetup -ArgumentList $arguments2 -Wait -PassThru -NoNewWindow
        $exit2 = $proc2.ExitCode
        if ($exit2 -eq 0) {
            Write-Host "[SUCCESS] Setup succeeded with patched appraiserres.dll. System may need reboot." -ForegroundColor $successColor
            Remove-Item -Path $tempFolder -Recurse -Force -ErrorAction SilentlyContinue
            Remove-BypassKeys
            return
        } else {
            Write-Host "[ERROR] Method 2 failed with exit code $exit2." -ForegroundColor $errorColor
            Write-Host "[INFO] Temporary files kept at $tempFolder for inspection." -ForegroundColor $infoColor
        }
    } else {
        Write-Host "[WARNING] Patching disabled. Set `$patchAppraiser = `$true to enable." -ForegroundColor $warningColor
    }
    Write-Host "[ERROR] All bypass attempts failed. Try using Rufus with 'Remove requirements' option." -ForegroundColor $errorColor
}

# --- Option 5: Set/Change ISO drive ---
function Set-ISODriveMenu {
    Show-Banner
    Write-Host "Set / Change ISO Drive" -ForegroundColor $bannerColor
    Write-Host ""
    if ($global:ISODrive) { Write-Host "Current ISO drive: $global:ISODrive" -ForegroundColor $infoColor }
    else { Write-Host "Current ISO drive: Not set" -ForegroundColor $warningColor }
    if (Set-ISODrive) { Write-Host "[SUCCESS] ISO drive updated." -ForegroundColor $successColor }
    else { Write-Host "[ERROR] Failed to set ISO drive." -ForegroundColor $errorColor }
}

# --- Main Menu ---
do {
    Show-Banner
    Write-Host "Main Menu" -ForegroundColor $bannerColor
    Write-Host ""
    Write-Host "  1. Check Windows 11 compatibility" -ForegroundColor $menuColor
    Write-Host "  2. Check disk space for upgrade" -ForegroundColor $menuColor
    Write-Host "  3. Check ISO language compatibility" -ForegroundColor $menuColor
    Write-Host "  4. Perform upgrade (with bypass)" -ForegroundColor $menuColor
    Write-Host "  5. Set/Change ISO drive" -ForegroundColor $menuColor
    Write-Host "  6. Exit" -ForegroundColor $menuColor
    Write-Host ""
    $choice = Read-Host "Enter choice (1-6)"
    switch ($choice) {
        "1" { Check-Compatibility }
        "2" { Check-DiskSpace }
        "3" { Check-ISOLanguage }
        "4" { Invoke-Upgrade }
        "5" { Set-ISODriveMenu }
        "6" { Write-Host "`n[INFO] Exiting...`n" -ForegroundColor $infoColor; break }
        default { Write-Host "`n[ERROR] Invalid choice. Please enter 1-6.`n" -ForegroundColor $errorColor }
    }
    if ($choice -ne "6") {
        Write-Host "`nPress Enter to return to menu..."
        Read-Host
    }
} while ($choice -ne "6")
