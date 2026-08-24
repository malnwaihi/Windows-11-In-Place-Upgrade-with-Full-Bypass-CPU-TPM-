# Windows 11 In‑Place Upgrade Bypass

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue)](https://github.com/PowerShell/PowerShell)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub Stars](https://img.shields.io/github/stars/malnwaihi/Windows-11-In-Place-Upgrade-with-Full-Bypass-CPU-TPM-)](https://github.com/malnwaihi/Windows-11-In-Place-Upgrade-with-Full-Bypass-CPU-TPM-/stargazers)
[![GitHub Issues](https://img.shields.io/github/issues/malnwaihi/Windows-11-In-Place-Upgrade-with-Full-Bypass-CPU-TPM-)](https://github.com/malnwaihi/Windows-11-In-Place-Upgrade-with-Full-Bypass-CPU-TPM-/issues)

**A PowerShell script to perform an in‑place upgrade (repair install) of Windows 11 on unsupported hardware, bypassing CPU, TPM, SecureBoot, RAM, and storage checks.**

This script uses two powerful bypass methods:
1. **`/product server`** – tricks Setup into skipping consumer hardware requirements.
2. **`appraiserres.dll` patching** – replaces the compatibility checker with a dummy file (Rufus‑style).

It preserves all apps, personal files, and settings – **no data loss**.

---

## ⚡ One‑Liner Installation

To download and run the script in one step, copy and paste this command into **PowerShell as Administrator**:

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/malnwaihi/Windows-11-In-Place-Upgrade-with-Full-Bypass-CPU-TPM-/main/Upgrade-Windows11.ps1'))
````
⚠️ Important:

This command temporarily bypasses the execution policy only for the current PowerShell session.

It downloads the script directly from GitHub and runs it immediately.

Always review scripts downloaded from the internet before running them.

The script will auto‑elevate to Administrator if needed.
````
🔧 Features
✅ Preserves files and applications – it’s an upgrade, not a clean install.

✅ Bypasses all hardware checks (CPU, TPM, SecureBoot, RAM, storage).

✅ Two‑stage fallback – tries the simple /product server first, then automatically patches appraiserres.dll if needed.

✅ Verbose logging – shows exit codes and relevant log snippets on failure.

✅ Reliable ISO language detection – warns if the ISO language differs from your system language (prevents accidental clean installs).

✅ Self‑elevation – automatically restarts as Administrator.

✅ Interactive menu – check compatibility, disk space, ISO language, set drive, and perform upgrade.
````

📋 Prerequisites
````
A mounted Windows 11 ISO (drive letter will be prompted).

At least 8 GB free disk space (only if patching is needed, for temporary copy of the ISO).

Run the script – it will auto‑elevate.
````
🚀 Quick Start
````
Mount the Windows 11 ISO (double‑click it) – ensure it appears as a drive.

Run the one‑liner above (or download the script and run it manually).

Use the interactive menu:

Option 5 to set the ISO drive.

Option 3 to check language compatibility.

Option 4 to perform the upgrade.

Follow the on‑screen instructions. Setup will launch with the GUI; confirm “Keep personal files and apps” is selected.

The system will reboot several times. After completion, you’ll be running Windows 11.
````
🛠 How It Works
````
Registry Bypass – Adds LabConfig keys to HKLM\SYSTEM\Setup to disable hardware checks.

Method 1 – Launches setup.exe with /product server /auto upgrade .... This makes Setup think it’s upgrading a Server edition, which ignores consumer hardware requirements.

If Method 1 fails, it copies the ISO contents to a temporary folder, replaces sources\appraiserres.dll with an empty file, and runs Setup again. (This is the same technique used by Rufus.)

On success, the temporary folder is deleted and the bypass registry keys are removed. Logs and exit codes help diagnose any issues.

Note: When using /product server, the Setup GUI says “Installing Windows Server” – this is normal. You are actually installing Windows 11.
````
📦 Configuration
````
At the top of the script, you can adjust:

$patchAppraiser – Set to $false to disable the second method.

$tempFolder – Change the location for the temporary ISO copy.

The drive letter is prompted each time you run the script, so no need to hardcode.
````
❗ Disclaimer
````
This script is provided as‑is for educational and convenience purposes. Bypassing hardware requirements may lead to an unstable system or unsupported configurations. Use at your own risk. Always back up important data before performing an upgrade.
````
📄 License
````
This project is licensed under the MIT License – see the LICENSE file for details.
````
🤝 Contributing
Feel free to open issues or submit pull requests with improvements. Please ensure any changes are well tested.

🌟 Support
If this script helped you, please star this repository to make it easier for others to find!
