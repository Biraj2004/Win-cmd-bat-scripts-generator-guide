# Win & macOS Script Suite & Generator Guide

[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS-blue.svg)](https://github.com/Biraj2004)
[![Engine](https://img.shields.io/badge/Engine-PowerShell%20%7C%20Bash-green.svg)](https://github.com/Biraj2004)
[![Safety](https://img.shields.io/badge/Safety-Confirmation%20Gate%20%2B%20Idempotent-orange.svg)](https://github.com/Biraj2004)
[![Developer](https://img.shields.io/badge/Developer-Biraj2004-purple.svg)](https://github.com/Biraj2004)

A production-grade collection of automated file-management scripts for **Windows** (`.bat` backed by PowerShell) and **macOS** (`.sh` backed by Bash), built with strict visual branding, Safety Confirmation Gates, idempotency guarantees, and cross-platform functional parity.

---

## 📋 Script Pair Matrix

Every script in the repository is built as part of a 1:1 platform twin pair. Windows scripts live in the root directory, while macOS twin scripts live inside `Mac-Equivalent-Scripts/`.

| Task / Purpose | Windows Script | macOS Twin Script | Key Action |
| :--- | :--- | :--- | :--- |
| **Auto-Numbering** | [`Win_Add_Prefix_Numberring_Based_On_Creation_Date_Ascending.bat`](./Win_Add Prefix_Numberring_Based_On_Creation_Date_Ascending.bat) | [`macOS_Add_Prefix_Numberring_Based_On_Creation_Date_Ascending.sh`](./Mac-Equivalent-Scripts/macOS_Add_Prefix Numberring_Based_On_Creation_Date_Ascending.sh) | Sorts Video (`.mp4`, `.mkv`, `.webm`) and PDF (`.pdf`) files by creation date and numbers them **independently** (`01..N` for videos, `01..M` for PDFs) in each folder. |
| **Remove Watermark** | [`Win_Remove_Hamaracollege_Text_From_Udemy_Videos.bat`](./Win_Remove_Hamaracollege_Text_From_Udemy_Videos.bat) | [`macOS_Remove_Hamaracollege_Text_From_Udemy_Videos.sh`](./Mac-Equivalent-Scripts/macOS_Remove_Hamaracollege_Text_From_Udemy_Videos.sh) | Scans for `@hamaracollege` / `@hmaracollege` (case-insensitive watermark tags) across all file types and strips only the watermark tag text. |
| **Strip Numeric Prefix** | [`Win_Strip_Mismatched_Numbered_Prefix.bat`](./Win_Strip_Mismatched_Numbered_Prefix.bat) | [`macOS_Strip_Mismatched_Numbered_Prefix.sh`](./Mac-Equivalent-Scripts/macOS_Strip_Mismatched_Numbered_Prefix.sh) | Detects leading pure-numeric prefixes (`07-`, `12 -`) before the first hyphen on media files and removes them safely. |
| **Fix Double Extensions & Convert WebM** | [`Win_Fix_Double_Extensions_And_Convert_Webm_To_Mp4.bat`](./Win_Fix_Double_Extensions_And_Convert_Webm_To_Mp4.bat) | [`macOS_Fix_Double_Extensions_And_Convert_Webm_To_Mp4.sh`](./Mac-Equivalent-Scripts/macOS_Fix_Double_Extensions_And_Convert_Webm_To_Mp4.sh) | Strips double video extensions (`.mp4.mkv`, `.mp4.webm` -> `.mp4`) and converts standalone `.webm` files to `.mp4` preserving timestamps and metadata. |
| **FFmpeg Auto-Installer & PATH Setup** | [`Win_Install_FFmpeg_And_Set_Env_Path.bat`](./Win_Install_FFmpeg_And_Set_Env_Path.bat) | [`macOS_Install_FFmpeg_And_Set_Env_Path.sh`](./Mac-Equivalent-Scripts/macOS_Install_FFmpeg_And_Set_Env_Path.sh) | Checks if FFmpeg is installed; if present, displays full executable path and version. If missing, downloads FFmpeg full build and sets environment PATH variable. |
| **Stremio MPV Player Integration** | [`Win_Setup_Stremio_To_Play_In_MPV.bat`](./Win_Setup_Stremio_To_Play_In_MPV.bat) | [`macOS_Setup_Stremio_To_Play_In_MPV.sh`](./Mac-Equivalent-Scripts/macOS_Setup_Stremio_To_Play_In_MPV.sh) | Configures Stremio to add MPV player integration ("Play in MPV"), patches server.js with quoted paths and sanitized start times, with automatic backup. |
| **Explorer Context Menu Cleaner** | [`Win_Clean_Explorer_Context_Menu_Entries.bat`](./Win_Clean_Explorer_Context_Menu_Entries.bat) | *N/A (Windows Registry Specific)* | Scans context menu registry locations (`Directory`, `Background`, `Folder`, `*` in `HKLM`/`HKCU`), detects missing executables / uninstalled app leftovers, creates `.reg` backups, and supports selective or bulk removal. |

---

## ⭐ Key Architectural Features

1. **Independent Video & PDF Auto-Numbering**:
   - Course folders containing both lecture videos and slide PDFs get fresh, separate numbering sequences starting at `01 - ` for videos and `01 - ` for PDFs.
   - Dynamic digit padding (`2-digit` for $<100$ files, `3+-digit` for $\ge 100$ files).
2. **Safety Confirmation Gate**:
   - No script will mutate disk files without explicit `Y`/`YES` confirmation.
   - Declining prompt exits cleanly without touching any files (`exit 0`).
3. **PowerShell Base64 Payload Engine (Windows)**:
   - Heavy batch operations pass execution to Base64 UTF-16LE Encoded PowerShell commands (`-EncodedCommand`), avoiding quote/escaping issues and supporting Unicode filenames natively.
4. **Tasteful Minimal Color Hierarchy & Tag Vocabulary**:
   - Banners & Main Section Titles: **Cyan/Blue**
   - Body Text, Info Labels & File Paths: Clean **White** for maximum legibility and zero visual noise
   - Status & Completion: **Green** (`[INFO]`, `[SUCCESS]`)
   - Warnings & Safety Gates: **Yellow** (`WARNING:`, `UPDATE AVAILABLE`)
   - Section Dividers: **Gray** (`===`, `---`)
   - Standard log tag vocabulary: `[INFO]`, `[FOLDER]`, `[SKIP]`, `[RENAMED]`, `[ERROR]`, `[SUMMARY]`, `[SUCCESS]`
5. **Idempotency Guarantee**:
   - Re-running any script is 100% safe. Files that already meet target criteria are logged as `[SKIP]` without double-prefixing or failing.

---

## 🚀 Quick Start & Usage

### Running on Windows
Place the `.bat` file into the folder you wish to process and **double-click it**, or run from Command Prompt:

```cmd
Win_Add_Prefix_Numberring_Based_On_Creation_Date_Ascending.bat
```

### Running on macOS
Copy the `.sh` file from `Mac-Equivalent-Scripts/` into the target folder, grant permissions, and run:

```bash
chmod +x macOS_Add_Prefix_Numberring_Based_On_Creation_Date_Ascending.sh
./macOS_Add_Prefix_Numberring_Based_On_Creation_Date_Ascending.sh
```

---

## 📁 Repository Structure

```text
.
├── Win_Add_Prefix_Numberring_Based_On_Creation_Date_Ascending.bat
├── Win_Clean_Explorer_Context_Menu_Entries.bat
├── Win_Fix_Double_Extensions_And_Convert_Webm_To_Mp4.bat
├── Win_Install_FFmpeg_And_Set_Env_Path.bat
├── Win_Remove_Hamaracollege_Text_From_Udemy_Videos.bat
├── Win_Setup_Stremio_To_Play_In_MPV.bat
├── Win_Strip_Mismatched_Numbered_Prefix.bat
├── Mac-Equivalent-Scripts/
│   ├── macOS_Add_Prefix_Numberring_Based_On_Creation_Date_Ascending.sh
│   ├── macOS_Fix_Double_Extensions_And_Convert_Webm_To_Mp4.sh
│   ├── macOS_Install_FFmpeg_And_Set_Env_Path.sh
│   ├── macOS_Remove_Hamaracollege_Text_From_Udemy_Videos.sh
│   ├── macOS_Setup_Stremio_To_Play_In_MPV.sh
│   └── macOS_Strip_Mismatched_Numbered_Prefix.sh
├── guide/
│   ├── WIN_SCRIPT_STYLE_GUIDE.md
│   ├── MACOS_SCRIPT_STYLE_GUIDE.md
│   └── Test_Script.md
└── README.md
```

---

## 📘 Documentation & Style Guides

- **[Windows Style Guide](./guide/WIN_SCRIPT_STYLE_GUIDE.md)**: Mandatory standards for creating Windows `.bat` scripts.
- **[macOS Style Guide](./guide/MACOS_SCRIPT_STYLE_GUIDE.md)**: Mandatory standards for creating macOS `.sh` Bash twins.
- **[Test Script Guide & Harness](./guide/Test_Script.md)**: Complete automated testing methodology and python test suite.

---

## 👤 Author & Licensing

- **Developer**: Biraj
- **GitHub**: [https://github.com/Biraj2004](https://github.com/Biraj2004)