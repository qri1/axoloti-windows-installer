# Axoloti Windows Installer

One-command installer bootstrap for Axoloti on Windows.

Open PowerShell and run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/qri1/axoloti-windows-installer/main/install.ps1 | iex"
```

The command downloads the latest `Axoloti-Windows-Payload.zip` release asset,
extracts it to `%LOCALAPPDATA%\Axoloti`, installs/checks dependencies, builds
Axoloti and creates shortcuts.
