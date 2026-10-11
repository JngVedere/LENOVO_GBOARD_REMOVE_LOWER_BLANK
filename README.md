# Lenovo Gboard Blank Patcher

Shrinks the blank strip under the on-screen keyboard (Gboard or any other) on Android tablets running a custom ROM. No root, no app, no bootloader unlock. It runs over USB with adb from a Windows PC.

## What you can change

| Option | Choices |
|---|---|
| Keyboard bottom row height | 32dp (minimum) · Default · 1.5x (84dp) · Custom 0–120dp |
| Globe (language switch) icon | Hide · Show |
| Collapse-keyboard arrow icon | Hide · Show |
| Animation speed (system-wide) | 0.5x · Default |

Changes stay after a reboot. To undo, pick **Default** or **Show**.

## Requirements

- A ROM signed with the **AOSP test key**. Many custom ROMs are, stock Lenovo firmware is not. The tool checks this and stops if your ROM isn't supported.
- **Android 17+** for the row height option.
- A Windows PC and a USB cable.

## Usage

1. On the tablet: Settings → About tablet → tap **Build number** 7 times. Then Settings → System → Developer options → turn on **USB debugging**.
2. Connect the tablet to the PC with a USB cable.
3. Run **`Lenovo Gboard Blank Patcher.exe`** (a single file, no install). The exe isn't code-signed, so Windows SmartScreen may warn you. Click **More info → Run anyway**. The tool unpacks itself to `%LOCALAPPDATA%\gboardblank`. If adb isn't installed, it downloads Google's platform-tools there too.
4. Pick your options and click **Apply to tablet (USB)**. If the tablet asks "Allow USB debugging?", tap **Allow** and click Apply again.

## Notes

- Values below 32dp can clip the globe and arrow buttons. On tablets with a taskbar, they also won't move the keyboard any lower.
- Hidden icons are transparent, not removed. Tapping their spot still works.
- The tool installs small resource-only overlay packages named `gboardblank.*`. You can remove them anytime with **Default** / **Show**, or with `adb uninstall <package>`.
- If a change disappears on its own (Play Protect can remove test-key-signed packages), apply it again.
- A ROM signed with the public AOSP test key lets any app signed with that key gain system privileges. Only install apps you trust on such a ROM.
- Not affiliated with Lenovo or Google. Use at your own risk.

## For developers

- `patch.cmd <module> <action>` is the command-line version. The actions for each module are listed at the top of `modules/<module>.sh`.
- `build.ps1` rebuilds `prebuilt/` from `apk/`, then packs the GUI into the exe (`launcher.cs`, compiled with the .NET Framework `csc` built into Windows). It needs a JDK and Android SDK build-tools 37 / platform 37. If you only changed scripts, run `.\build.ps1 -GapRange @()`. `keys/` holds the public AOSP platform test key from the Android source tree.
