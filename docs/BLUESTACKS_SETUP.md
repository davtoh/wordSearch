# BlueStacks 5 Android Testing Guide for Flutter

This document details how to configure, connect, and test Flutter applications on the BlueStacks 5 Android emulator on Windows, resolving common pitfalls such as ADB version mismatches and dynamic port discovery.

---

## 1. Quick Start (Automated)

The project includes pre-built connectors that automatically resolve the correct Android SDK ADB binary, parse the active BlueStacks port from the configuration, connect to the emulator, and launch your Flutter app.

### Option A: Python Connector (Recommended)
```powershell
# Auto-detect running BlueStacks instance and connect
python scripts/connect_bluestacks.py

# Connect and immediately launch the Flutter app
python scripts/connect_bluestacks.py --run

# Run diagnostic check on ADB versions and ports
python scripts/connect_bluestacks.py --doctor

# Register global Antigravity AI Agent skill
python scripts/connect_bluestacks.py --install-skill
```

### Option B: PowerShell Connector
```powershell
# Auto-detect and connect
.\scripts\connect_bluestacks.ps1

# Connect and launch Flutter app
.\scripts\connect_bluestacks.ps1 -Run
```

---

## 2. The Core Problem: The ADB Server Version Trap

When testing Flutter with BlueStacks on Windows, you may encounter the following error:

```text
flutter run -d 127.0.0.1:<port>
No supported devices found with name or id matching '127.0.0.1:<port>'
```

Even after successfully connecting via `HD-Adb.exe connect 127.0.0.1:<port>`.

### Root Cause
1. **Version Mismatch**:
   - BlueStacks bundles its own internal ADB utility: `C:\Program Files\BlueStacks_nxt\HD-Adb.exe` (version **1.0.36**).
   - Flutter and the Android SDK use modern ADB: `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe` (version **1.0.41+**).
2. **Daemon Reset**:
   - When `HD-Adb.exe` runs, it kills any active ADB v41 server and spawns an older v36 daemon.
   - When `flutter run` is executed, Flutter invokes Android SDK's `adb.exe` (v41). It sees the outdated daemon, **kills it**, and restarts a v41 daemon.
   - **Whenever an ADB daemon terminates, all active TCP/IP connections are lost.**
   - As a result, BlueStacks is instantly disconnected before Flutter can inspect connected devices.

---

## 3. Configuration & Ports

### Step 1: Enable ADB in BlueStacks
1. Launch **BlueStacks 5**.
2. Open **Settings** (gear icon) -> **Advanced**.
3. Under **Android Debug Bridge (ADB)**, toggle the switch to **On**.
4. BlueStacks will display the local IP and port (e.g. `127.0.0.1:53245`).

### Step 2: Automatic Port Discovery
BlueStacks assigns dynamic ports on startup and records the active running port in:
`C:\ProgramData\BlueStacks_nxt\bluestacks.conf`

Under the key:
```ini
bst.instance.<InstanceName>.status.adb_port="<Port>"
```
*(Our scripts parse this file automatically, so you never need to look up or hardcode the port).*

---

## 4. Manual Connection Steps

If you prefer to connect manually without the scripts:

1. **Always use the Android SDK ADB**:
   ```powershell
   & "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" connect 127.0.0.1:<port>
   ```
   *(Never use `HD-Adb.exe`).*

2. **Verify connection**:
   ```powershell
   & "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices
   ```
   Output:
   ```text
   List of devices attached
   127.0.0.1:53245	device
   ```

3. **Verify Flutter detects the device**:
   ```powershell
   flutter devices
   ```
   Output:
   ```text
   SM G998B (mobile) • 127.0.0.1:53245 • android-x64 • Android 7.1.2 (API 25)
   ```

4. **Launch the application**:
   ```powershell
   cd word_search_app
   flutter run -d 127.0.0.1:53245
   ```

---

## 5. Permanent System Recommendations

1. **Add Android SDK Platform-Tools to User PATH**:
   Run once in PowerShell to make `adb` available universally:
   ```powershell
   [Environment]::SetEnvironmentVariable(
       "Path",
       [Environment]::GetEnvironmentVariable("Path", "User") + ";$env:LOCALAPPDATA\Android\Sdk\platform-tools",
       "User"
   )
   ```

2. **(Optional) BlueStacks Binary Alignment**:
   To prevent BlueStacks from ever starting an outdated daemon internally, copy `adb.exe` from `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe` and overwrite `C:\Program Files\BlueStacks_nxt\HD-Adb.exe` (requires administrator privileges).

---

## 6. Antigravity AI Agent Integration

This workflow is registered as a global Antigravity Skill (`flutter-bluestacks`) located at:
`C:\Users\User\.gemini\config\skills\flutter-bluestacks\`

Any AI agent interacting with this repository or any other Flutter repository on this workstation automatically inherits the ability to:
- Detect running BlueStacks instances.
- Connect using the correct ADB version.
- Diagnose and run Flutter applications on BlueStacks without manual setup.
