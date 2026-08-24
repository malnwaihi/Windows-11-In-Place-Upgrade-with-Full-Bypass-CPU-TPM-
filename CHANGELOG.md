# Changelog

All notable changes to this project will be documented in this file.

## [v1.0] - 2025-08-24

### Added
- Initial release
- Interactive menu with 6 options
- Windows 11 hardware compatibility check (CPU, TPM, SecureBoot, RAM, storage)
- Disk space check for upgrade
- ISO language detection and compatibility check
- In-place upgrade with two bypass methods:
  - `/product server` trick
  - `appraiserres.dll` patching (Rufus-style)
- Self-elevation to Administrator
- Registry bypass keys added and removed automatically
- Verbose logging and error handling


### Fixed
- Drive letter normalization (accepts `E`, `E:`, `E:\`)
- ISO language detection using `dism` for reliability
- Parse errors due to special characters
