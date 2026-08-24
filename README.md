# Windows 11 In‑Place Upgrade Bypass

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue)](https://github.com/PowerShell/PowerShell)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub Stars](https://img.shields.io/github/stars/malnwaihi/windows11-upgrade-bypass)](https://github.com/malnwaihi/windows11-upgrade-bypass/stargazers)
[![GitHub Issues](https://img.shields.io/github/issues/malnwaihi/windows11-upgrade-bypass)](https://github.com/malnwaihi/windows11-upgrade-bypass/issues)

**A PowerShell script to perform an in‑place upgrade (repair install) of Windows 11 on unsupported hardware, bypassing CPU, TPM, SecureBoot, RAM, and storage checks.**

This script uses two powerful bypass methods:
1. **`/product server`** – tricks Setup into skipping consumer hardware requirements.
2. **`appraiserres.dll` patching** – replaces the compatibility checker with a dummy file (Rufus‑style).

It preserves all apps, personal files, and settings – **no data loss**.

---

## ⚡ One‑Liner Installation

To download and run the script in one step, copy and paste this command into **PowerShell as Administrator**:

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/malnwaihi/windows11-upgrade-bypass/main/Upgrade-Windows11.ps1'))
