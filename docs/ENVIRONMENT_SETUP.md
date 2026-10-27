# Flutter Development Environment Setup Guide

This guide details the complete, step-by-step installation instructions for setting up a Flutter development environment (Dart 3.x) targeting macOS, Android, iOS, Web, and Desktop.

---

## 1. System Requirements & Prerequisites

- **macOS:** macOS Catalina (10.15.4) or newer. Apple Silicon (M1/M2/M3/M4) or Intel x86_64.
- **Disk Space:** At least 10 GB free space for Flutter SDK, Android Studio, Xcode, and command-line tools.
- **Homebrew** (recommended package manager for macOS):
  ```bash
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ```

---

## 2. Flutter SDK Installation

### Method A: Homebrew (Fastest on macOS)
```bash
brew install --cask flutter
```

### Method B: Manual Download (Official Archive)
1. Download the latest stable Flutter SDK zip from [flutter.dev](https://docs.flutter.dev/get-started/install/macos).
2. Extract the archive into your preferred development directory (e.g. `~/development/flutter`):
   ```bash
   mkdir -p ~/development
   cd ~/development
   unzip ~/Downloads/flutter_macos_*.zip
   ```
3. Add `flutter` to your `PATH` across sessions:
   - For **Zsh** (macOS default, `~/.zshrc`):
     ```bash
     echo 'export PATH="$HOME/development/flutter/bin:$PATH"' >> ~/.zshrc
     source ~/.zshrc
     ```
   - For **Bash** (`~/.bash_profile` or `~/.bashrc`):
     ```bash
     echo 'export PATH="$HOME/development/flutter/bin:$PATH"' >> ~/.bashrc
     source ~/.bashrc
     ```
4. Verify Flutter & Dart:
   ```bash
   which flutter
   flutter --version
   ```

---

## 3. Host OS & Platform Toolchains

### A. Android Setup (Android Studio & SDK)
1. **Install Android Studio**:
   - Download from [developer.android.com/studio](https://developer.android.com/studio) or install via Homebrew:
     ```bash
     brew install --cask android-studio
     ```
2. **Install Android SDK Command-line Tools**:
   - Open Android Studio -> **Settings / Preferences** -> **Languages & Framworks** -> **Android SDK**.
   - Navigate to the **SDK Tools** tab.
   - Check **Android SDK Command-line Tools (latest)** and click **Apply**.
   - or run command
     ```bash
     brew install --cask android-commandlinetoolso
     ```
3. **Environment Variables**:
   Add the following to your `~/.zshrc`:
   ```bash
   export ANDROID_HOME=$HOME/Library/Android/sdk
   export PATH=$PATH:$ANDROID_HOME/emulator
   export PATH=$PATH:$ANDROID_HOME/platform-tools
   export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
   ```
4. **Accept Android Licenses**:
   ```bash
   flutter doctor --android-licenses
   ```

### B. iOS & macOS Setup (Xcode & CocoaPods)
1. **Install Xcode**:
   - Install Xcode from the Mac App Store or download via Apple Developer portal.
2. **Configure Xcode Command-line Tools**:
   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   ```
3. **Install CocoaPods**:
   ```bash
   brew install cocoapods
   # Or via Ruby gem:
   sudo gem install cocoapods
   ```

### C. Web & Chrome Setup
Flutter Web requires Google Chrome or Chromium:
```bash
brew install --cask google-chrome
```

---

## 4. Visual Studio Code Configuration

1. **Install VS Code**:
   ```bash
   brew install --cask visual-studio-code
   ```
2. **Install Required Extensions**:
   - **Flutter**: Extension ID `Dart-Code.flutter`
   - **Dart**: Extension ID `Dart-Code.dart-code`
3. **Install via Command Line**:
   ```bash
   code --install-extension Dart-Code.flutter
   code --install-extension Dart-Code.dart-code
   ```

---

## 5. Verification: `flutter doctor -v`

Run the diagnostic tool in your terminal:
```bash
flutter doctor -v
```

### Typical Checklist Output:
- [x] **Flutter (Channel stable, 3.x.x)**
- [x] **Android toolchain** (Android SDK version, licenses accepted)
- [x] **Xcode** (iOS and macOS development)
- [x] **Chrome** (Web development)
- [x] **Android Studio**
- [x] **VS Code** (Flutter extension installed)
- [x] **Connected device** (Emulator, simulator, or browser)
- [x] **Network resources**

---

## 6. Common Issues & Troubleshooting

| Issue / Error | Cause | Resolution |
| :--- | :--- | :--- |
| `zsh: command not found: flutter` | `flutter/bin` is not in `$PATH` | Add `export PATH="$HOME/development/flutter/bin:$PATH"` to `~/.zshrc` and run `source ~/.zshrc`. |
| `cmdline-tools component is missing` | Android SDK Command-line Tools not installed | In Android Studio, open SDK Manager -> SDK Tools -> Check "Android SDK Command-line Tools" -> Apply. |
| `Android license status unknown` | Licenses not agreed to | Run `flutter doctor --android-licenses` and accept all prompts (`y`). |
| `CocoaPods not installed` | Missing CocoaPods for iOS/macOS pod dependency resolution | Run `brew install cocoapods` or `sudo gem install cocoapods`. |
| `Unable to locate a Java Runtime` | JDK not installed or Android Studio bundled JDK not linked | Install JDK via `brew install openjdk` or set `JAVA_HOME` to Android Studio's bundled jbr: `export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"`. |
| `Xcode installation is incomplete` | Xcode command line tools pointing to CLT instead of full Xcode | Run `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`. |
| `No supported devices found matching '127.0.0.1:<port>'` (BlueStacks) | ADB daemon restarted due to version mismatch between BlueStacks `HD-Adb.exe` (v36) and Android SDK `adb.exe` (v41) | Connect using the Android SDK's `adb.exe` or run `python scripts/connect_bluestacks.py`. See [BLUESTACKS_SETUP.md](file:///c:/dev/phone_projects/python/wordSearch/docs/BLUESTACKS_SETUP.md). |

---

## 7. Windows & Emulator Testing

For running and testing the Flutter mobile application on Windows without physical devices, see the [BlueStacks 5 Android Testing Guide](file:///c:/dev/phone_projects/python/wordSearch/docs/BLUESTACKS_SETUP.md). It includes automated connection scripts (`scripts/connect_bluestacks.py`, `scripts/connect_bluestacks.ps1`) and instructions for resolving dynamic port discovery and ADB version mismatches.


