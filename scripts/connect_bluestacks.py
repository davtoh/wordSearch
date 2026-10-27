"""
BlueStacks ADB Bridge & Flutter Connector
-----------------------------------------
Automates discovering and connecting BlueStacks 5 instances to Android SDK's ADB,
resolving version mismatch issues with bundled HD-Adb, and launching Flutter.

Also provides --install-skill to register an Antigravity AI Agent skill.
"""

import os
import sys
import re
import shutil
import argparse
import subprocess
from pathlib import Path

BLUESTACKS_CONF = Path(r"C:\ProgramData\BlueStacks_nxt\bluestacks.conf")

def get_android_sdk_adb() -> Path | None:
    """Locate Android SDK's adb.exe, explicitly avoiding BlueStacks HD-Adb.exe."""
    candidates = []
    
    # 1. Check local AppData Android SDK
    local_appdata = os.environ.get("LOCALAPPDATA")
    if local_appdata:
        candidates.append(Path(local_appdata) / "Android" / "Sdk" / "platform-tools" / "adb.exe")
        candidates.append(Path(local_appdata) / "Android" / "sdk" / "platform-tools" / "adb.exe")

    # 2. Check ANDROID_HOME / ANDROID_SDK_ROOT
    android_home = os.environ.get("ANDROID_HOME") or os.environ.get("ANDROID_SDK_ROOT")
    if android_home:
        candidates.append(Path(android_home) / "platform-tools" / "adb.exe")

    # 3. Check system PATH
    system_adb = shutil.which("adb")
    if system_adb:
        candidates.append(Path(system_adb))

    for candidate in candidates:
        if candidate and candidate.is_file():
            # Exclude BlueStacks bundled HD-Adb.exe
            if "bluestacks" not in str(candidate).lower():
                return candidate.resolve()
                
    return None

def detect_bluestacks_ports() -> list[dict]:
    """Parse active status.adb_port instances from bluestacks.conf."""
    if not BLUESTACKS_CONF.exists():
        return []
    
    try:
        content = BLUESTACKS_CONF.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        return []
    
    instances = []
    # Match: bst.instance.<inst>.status.adb_port="<port>"
    pattern = r'bst\.instance\.([^.]+)\.status\.adb_port="?(\d+)'
    for match in re.finditer(pattern, content):
        inst_name, port = match.groups()
        instances.append({"instance": inst_name, "port": int(port)})
        
    return instances

def run_cmd(cmd: list[str]) -> tuple[int, str]:
    """Run a subprocess command and return exit code + trimmed combined output."""
    try:
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, check=False)
        return res.returncode, res.stdout.strip()
    except Exception as e:
        return 1, str(e)

def install_agent_skill(target_dir: Path | None = None) -> bool:
    """Installs the flutter-bluestacks skill into Antigravity's global config."""
    if target_dir is None:
        user_home = Path.home()
        target_dir = user_home / ".gemini" / "config" / "skills" / "flutter-bluestacks"
    
    target_dir.mkdir(parents=True, exist_ok=True)
    scripts_dir = target_dir / "scripts"
    scripts_dir.mkdir(parents=True, exist_ok=True)

    # 1. Copy or write this script into the skill
    current_script = Path(__file__).resolve()
    target_script = scripts_dir / "connect_bluestacks.py"
    shutil.copy2(current_script, target_script)

    # 2. Generate SKILL.md
    skill_md_content = """---
name: flutter-bluestacks
description: Connect, diagnose, and run Flutter applications on BlueStacks Android emulator. Use when testing Flutter mobile apps on Windows without physical devices, fixing ADB server version mismatches (e.g. HD-Adb v36 vs Android SDK v41), resolving BlueStacks ADB connection ports, or troubleshooting 'No supported devices found' when targeting BlueStacks.
---

# Flutter BlueStacks Bridge: Agent Skill Guide

This skill enables AI agents to seamlessly connect, debug, and execute Flutter applications on local BlueStacks Android emulators on Windows.

## The Core Problem & Root Cause

1. **ADB Server Version Collision**:
   - BlueStacks bundles its own older ADB (`C:\\Program Files\\BlueStacks_nxt\\HD-Adb.exe`, version 1.0.36).
   - Flutter and the Android SDK use modern ADB (`%LOCALAPPDATA%\\Android\\Sdk\\platform-tools\\adb.exe`, version 1.0.41+).
   - If an agent or user runs `HD-Adb.exe connect 127.0.0.1:<port>`, it spawns a v36 ADB daemon. When `flutter run` is executed, Flutter's v41 ADB detects the mismatch, **kills the daemon**, and restarts it. Starting a new daemon erases all active network connections, causing Flutter to report: `No supported devices found`.

2. **Dynamic ADB Ports**:
   - BlueStacks dynamically assigns ports to running instances and stores them in `C:\\ProgramData\\BlueStacks_nxt\\bluestacks.conf` under `bst.instance.<name>.status.adb_port`.

## Quick Agent Workflow

### 1. Auto-Connect & Detect Active BlueStacks Devices
Run the bundled Python script:
```powershell
python "<skill-dir>/scripts/connect_bluestacks.py"
```
Or if running directly in the repository:
```powershell
python scripts/connect_bluestacks.py
# Or with PowerShell:
.\\scripts\\connect_bluestacks.ps1
```

### 2. Run Flutter App on Connected BlueStacks
Once connected, BlueStacks appears as an attached ADB device (e.g. `127.0.0.1:53245`):
```powershell
flutter run -d 127.0.0.1:<port>
```
Or use the automated `--run` flag:
```powershell
python "<skill-dir>/scripts/connect_bluestacks.py" --run
```

### 3. Manual Fallback Steps
If manual recovery is needed:
1. Always use Android SDK's ADB:
   ```powershell
   & "$env:LOCALAPPDATA\\Android\\Sdk\\platform-tools\\adb.exe" connect 127.0.0.1:<port>
   ```
2. Verify with:
   ```powershell
   & "$env:LOCALAPPDATA\\Android\\Sdk\\platform-tools\\adb.exe" devices
   ```
3. Never invoke `HD-Adb.exe`.
"""
    (target_dir / "SKILL.md").write_text(skill_md_content, encoding="utf-8")
    print(f"[OK] Skill installed successfully at: {target_dir}")
    print(f"     SKILL.md generated.")
    print(f"     Script bundled at: {target_script}")
    return True

def main():
    parser = argparse.ArgumentParser(
        description="BlueStacks ADB Bridge & Flutter Connector",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""Examples:
  python connect_bluestacks.py             # Auto-detect running instances & connect
  python connect_bluestacks.py --run       # Connect and immediately launch Flutter
  python connect_bluestacks.py --port 53245 # Connect to specific manual port
  python connect_bluestacks.py --doctor    # Check environment & versions
  python connect_bluestacks.py --install-skill # Register Antigravity AI Agent skill
"""
    )
    parser.add_argument("--port", type=int, help="Specify manual ADB port to connect to")
    parser.add_argument("--run", action="store_true", help="Launch 'flutter run -d <target>' after connecting")
    parser.add_argument("--doctor", action="store_true", help="Diagnose ADB versions and BlueStacks status")
    parser.add_argument("--install-skill", action="store_true", help="Install global Antigravity Agent Skill")

    args = parser.parse_args()

    if args.install_skill:
        install_agent_skill()
        return

    adb_path = get_android_sdk_adb()
    if not adb_path:
        print("[ERROR] Android SDK adb.exe could not be found.")
        print("Please ensure platform-tools are installed at %LOCALAPPDATA%\\Android\\Sdk\\platform-tools\\adb.exe")
        sys.exit(1)

    if args.doctor:
        print("=== BlueStacks Flutter Doctor ===")
        print(f"Android SDK ADB : {adb_path}")
        _, adb_ver = run_cmd([str(adb_path), "version"])
        print(f"ADB Version     : {adb_ver.splitlines()[0] if adb_ver else 'Unknown'}")
        
        hd_adb = Path(r"C:\Program Files\BlueStacks_nxt\HD-Adb.exe")
        if hd_adb.exists():
            _, hd_ver = run_cmd([str(hd_adb), "version"])
            print(f"BlueStacks ADB  : {hd_adb} (Version: {hd_ver.splitlines()[0] if hd_ver else 'Unknown'})")
            print("  [!] WARNING: Do not use HD-Adb.exe; it will trigger ADB server restarts.")
        
        ports = detect_bluestacks_ports()
        print(f"Detected Ports  : {ports}")
        return

    print("=== BlueStacks Flutter ADB Connector ===")
    print(f"[OK] Using Android SDK ADB: {adb_path}")

    targets = []
    if args.port:
        targets.append({"instance": "Manual", "port": args.port})
    else:
        targets = detect_bluestacks_ports()
        if not targets:
            print(f"[WARN] No running BlueStacks instances found in {BLUESTACKS_CONF}.")
            print("Ensure BlueStacks is open and ADB is enabled in Settings -> Advanced.")
            sys.exit(1)

    connected_target = None
    for item in targets:
        addr = f"127.0.0.1:{item['port']}"
        print(f"[>] Connecting to BlueStacks '{item['instance']}' at {addr}...")
        code, out = run_cmd([str(adb_path), "connect", addr])
        print(f"    {out}")
        if "connected to" in out.lower():
            connected_target = addr

    print("\n[OK] Current ADB Devices:")
    _, dev_out = run_cmd([str(adb_path), "devices"])
    print(dev_out)

    if args.run:
        if not connected_target:
            # Fallback to first available target if already connected
            if targets:
                connected_target = f"127.0.0.1:{targets[0]['port']}"
            else:
                print("[ERROR] No device available to run Flutter on.")
                sys.exit(1)

        # Locate Flutter project
        cwd = Path.cwd()
        flutter_dir = cwd / "word_search_app" if (cwd / "word_search_app").exists() else cwd
        print(f"\n[>] Launching Flutter app on {connected_target} (Dir: {flutter_dir})...")
        subprocess.run(["flutter", "run", "-d", connected_target], cwd=str(flutter_dir), check=False)
    else:
        print("\nTo run your Flutter app targeting this BlueStacks instance, run:")
        target_display = connected_target or f"127.0.0.1:{targets[0]['port']}"
        print(f"  flutter run -d {target_display}")

if __name__ == "__main__":
    main()
