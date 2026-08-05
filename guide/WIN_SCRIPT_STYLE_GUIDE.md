# Windows (.bat) Script Style Guide

This document defines the **mandatory** structure, branding, presentation, and
safety conventions for every Windows `.bat` script added to this repository.
It is reverse-engineered from `Win_Add_Numberring_Based_On_Creation_Date_Ascending.bat`
and must be followed **exactly** so all scripts feel like one consistent family.

---

## 1. File Naming Convention

**Pattern:** `Win_Title_Case_With_Underscores.bat`

- Every Windows script filename **must start with the `Win_` prefix**,
  mirroring the `macOS_` prefix used on the Mac side. This makes the
  platform obvious at a glance in file listings, search results, and
  release archives.
- After the `Win_` prefix, every word starts with a **capital letter**.
- Spaces between words are replaced with a single underscore `_`.
- No spaces, no hyphens, no camelCase, no ALL_CAPS words.
- File extension is always lowercase `.bat`.
- Lives in the **root** of the repository (never in a subfolder).

```
Correct   : Win_Rename_Files_By_Creation_Date.bat
Correct   : Win_Compress_Images_To_Webp.bat
Incorrect : Rename_Files_By_Creation_Date.bat   (missing Win_ prefix)
Incorrect : win_rename_files_by_creation_date.bat   (no capitals, lowercase prefix)
Incorrect : WinRenameFilesByCreationDate.bat        (camelCase, no underscores)
Incorrect : Win-Rename-Files-By-Creation-Date.bat   (hyphens instead of underscores)
```

The **base name** is everything after the `Win_` prefix
(e.g. `Rename_Files_By_Creation_Date`). The Mac equivalent of this file
must reuse the **exact same base name** (see `MACOS_SCRIPT_STYLE_GUIDE.md`),
just prefixed with `macOS_` instead of `Win_`, and placed in
`Mac-Equivalent-Scripts/`.

```
Windows : Win_Rename_Files_By_Creation_Date.bat
macOS   : macOS_Rename_Files_By_Creation_Date.sh
```

### Current Repository Script Pairs

| Windows Script (`/`) | macOS Twin (`Mac-Equivalent-Scripts/`) | Purpose |
| :--- | :--- | :--- |
| `Win_Add_Numberring_Based_On_Creation_Date_Ascending.bat` | `macOS_Add_Numberring_Based_On_Creation_Date_Ascending.sh` | Independent Video & PDF auto-numbering by creation date |
| `Win_Remove_Hamaracollege_Text_From_Udemy_Videos.bat` | `macOS_Remove_Hamaracollege_Text_From_Udemy_Videos.sh` | Case-insensitive watermark tag removal |
| `Win_Strip_Mismatched_Numbered_Prefix.bat` | `macOS_Strip_Mismatched_Numbered_Prefix.sh` | Pure numeric prefix stripping before first hyphen |

---

## 2. Overall File Skeleton

Every script follows this exact section order:

1. `@echo off` + `setlocal EnableDelayedExpansion`
2. `title` bar branding
3. `cd /d "%~dp0"` (always operate relative to the script's own location)
4. Header comment block (developer branding + full description)
5. Console banner block (visual restatement of branding)
6. `[INFO]` block (parameters/behavior summary)
7. `[WARNING]` block (what will change, blast radius)
8. Y/N confirmation prompt (safety gate)
9. Cancel path (safe, no-op exit)
10. Proceed path → `[PROCESSING]` → engine launch (PowerShell, etc.)
11. Footer `[FINISHED]` banner
12. `pause` + `endlocal`

Nothing may run that changes files on disk before step 8's confirmation
is explicitly accepted.

---

## 3. Top-of-File Setup

```bat
@echo off
setlocal EnableDelayedExpansion
title <Short Script Purpose> - by Biraj2004
cd /d "%~dp0"
```

- `title` format is always: `<Human-readable purpose> - by Biraj2004`.
- `cd /d "%~dp0"` must come immediately after the title so the script always
  operates on its own folder, regardless of where it was launched from.

---

## 4. Header Comment Block (Branding + Description)

Placed right after the setup lines. Uses `::` comments, wrapped top and
bottom by a separator line of **103 `=` characters** after `:: `.

```bat
:: ===================================================================================================
:: GitHub      : https://github.com/Biraj2004
:: Developer   : Biraj
:: Description : <What the script scans/targets>
::                <Sorting/selection rule, if any>
::                - <Key behavior bullet 1>
::                - <Key behavior bullet 2>
::                - Original filename text is NEVER modified beyond the documented change.
::                - Re-running this script is SAFE: <idempotency guarantee>.
:: ===================================================================================================
```

Rules for this block:
- `GitHub` and `Developer` lines are **fixed** — copy them verbatim.
- `Description` is a multi-line wrapped paragraph, continuation lines indented
  to align under the text that follows `Description : `.
- Always state, in plain bullets, whether the operation is **idempotent**
  (safe to re-run) and whether original content/names are altered vs. only
  prefixed/suffixed/moved.

---

## 5. Console Banner Block

Immediately follows the header comment, printed to the console so the user
sees identical branding at runtime (not just in the source file).

```bat
echo =====================================================================================================
echo                       <SCRIPT TITLE IN CAPS>
echo                       Developed by : Biraj
echo                       GitHub       : https://github.com/Biraj2004
echo =====================================================================================================
echo.
```

- Separator lines are `echo ` followed by **103 `=` characters**.
- Title is centered-ish with a fixed left indent (22 spaces), matching the
  reference script.
- Always followed by a blank `echo.`.

---

## 6. `[INFO]` Block

A flat list of `[INFO]` lines summarizing exactly what the script will do,
using aligned labels (pad label column so `:` lines up):

```bat
echo [INFO] Working Folder   : %CD%
echo [INFO] Target Extensions: <ext1>, <ext2>, ...
echo [INFO] Sorting Rule     : <rule>, Ascending/Descending
echo [INFO] Numbering Format : <format rules, if applicable>
echo [INFO] Scope            : Current folder + ALL subfolders (Recursive)
echo [INFO] Safety           : <what is protected / never modified>
echo.
```

- Only include the `[INFO]` lines that are relevant to the script; do not
  pad the list with filler.
- Labels are left-aligned; colons line up vertically wherever practical.

---

## 7. `[WARNING]` Block

Always precedes the confirmation prompt. States precisely what will be
changed and where, in capital `WARNING`:

```bat
echo =====================================================================================================
echo  WARNING: This will <RENAME/DELETE/MOVE/CONVERT> <file types> inside:
echo    %CD%
echo  ...and every SUB-FOLDER inside it.          <-- omit this line if not recursive
echo =====================================================================================================
echo.
```

---

## 8. Y/N Safety Gate

**Every script that modifies files must ask for confirmation before doing
anything irreversible.** No exceptions.

```bat
set "CONFIRM="
set /p CONFIRM=Type Y and press Enter to proceed, or N to cancel : 

if /i "%CONFIRM%"=="Y" goto :PROCEED
if /i "%CONFIRM%"=="YES" goto :PROCEED

echo.
echo [CANCELLED] No files were scanned or renamed. Exiting safely.
echo.
pause
endlocal
exit /b 0

:PROCEED
```

- Accepts `Y` or `YES` (case-insensitive) only; anything else cancels safely.
- The cancel path must state clearly that **nothing was touched** and exit
  with code `0`.
- Never default to "proceed" on empty input.

---

## 9. Processing / Engine Launch

```bat
echo.
echo [PROCESSING] Launching PowerShell engine...
echo =====================================================================================================

where powershell >nul 2>&1
if errorlevel 1 (
    echo [ERROR] PowerShell was not found on this system. Cannot continue.
    echo.
    pause
    exit /b 1
)

powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -EncodedCommand "<Base64-encoded UTF-16LE PowerShell script>"
```

- Heavy logic (recursion, sorting, renaming, error handling) lives in
  **PowerShell**, not raw batch, for reliability with special characters,
  Unicode filenames, and structured objects.
- The PowerShell payload is passed via `-EncodedCommand` using a
  **Base64-encoded UTF-16LE** string (this is what `-EncodedCommand` requires).
  This avoids all batch quoting/escaping issues for complex scripts.
- Always check `where powershell` exists first and fail gracefully with
  `[ERROR]` + `pause` + `exit /b 1` if missing.

### 9.1 PowerShell Sub-Script Conventions

Inside the encoded PowerShell payload:

- `$ErrorActionPreference = 'Stop'` at the top.
- Use `Write-Host` (not `Write-Output`) for all user-facing log lines so
  color control (`-ForegroundColor`) is available.
- **Color palette** (use consistently, do not invent new colors per script):

  | Purpose                                             | Color         |
  |------------------------------------------------------|---------------|
  | General `[INFO]` / neutral status                    | `Gray`        |
  | Nothing found / soft warning                          | `Yellow`      |
  | Folder/group header (e.g. `[FOLDER]`)                 | `Magenta`     |
  | Sub-detail under a folder header                      | `DarkMagenta` |
  | Skipped item (already correct, no-op)                 | `DarkGray`    |
  | Successful individual action detail (e.g. `-->` line) | `Cyan`        |
  | Error for a single item                               | `Red`         |
  | `[SUMMARY]` totals block + final `[SUCCESS]` line      | `Green`       |
  | Section separators / labels with no special meaning   | *(default, no color override)* |

- **Log tag vocabulary** — use these exact bracketed tags, do not invent
  synonyms:
  - `[INFO]` — informational, non-actionable statement.
  - `[FOLDER]` — entering/reporting on a specific folder/group.
  - `[SKIP]` — item intentionally left unchanged.
  - `[RENAMED]` / `[MOVED]` / `[CONVERTED]` / `[DELETED]` — the actual
    action verb performed, uppercase, matching the script's operation.
  - `[ERROR]` — a single item failed but the script continues.
  - `[SUMMARY]` — final aggregate counts block.
  - `[SUCCESS]` — final one-line completion statement.
  - `[CANCELLED]` — user declined the Y/N prompt.
  - `[PROCESSING]` — hand-off point from batch to the PowerShell engine.
- When an action is performed on an item that spans two lines, print the
  "from" line first, then an indented `-->` line with the "to" value in
  `Cyan`:

  ```
  [RENAMED]  old-file-name.mp4
       -->   01 - old-file-name.mp4
  ```
- Every loop that mutates files must wrap the mutation in `try { } catch { }`
  and increment a running `$grandErrors` counter on failure — never let one
  bad file abort the whole run.
- Maintain three running counters across the whole script where applicable:
  `$grandRenamed` / `$grandSkipped` / `$grandErrors` (rename the first per
  the actual verb, e.g. `$grandMoved`, `$grandConverted`).
- End of run: print a `-----` separator, then a `[SUMMARY]` block covering
  every counter tracked, then a final `[SUCCESS]` line, all in `Green`.
- Always end interactive PowerShell logic with:
  ```powershell
  Write-Host ""
  Write-Host "Press any key to exit..."
  [void][System.Console]::ReadKey($true)
  ```

---

## 10. Separator Lines Reference

Use exactly these two separator styles, both **103 characters** of the
repeated symbol after the `echo ` (or `:: `) prefix:

| Style              | Batch usage                          | Weight              |
|---------------------|--------------------------------------|----------------------|
| Heavy (`=`)         | `echo` banners, header/footer blocks | Major section breaks |
| Light (`-`)         | Between the processing banner and the engine's own output | Minor breaks |

Do not shorten or lengthen these arbitrarily — copy an existing separator
line and edit only its surrounding text, so line width stays identical
across every script in the repo.

---

## 11. Footer Block

```bat
echo ---------------------------------------------------------------------------
echo =====================================================================================================
echo [FINISHED] Script execution finished. GitHub: https://github.com/Biraj2004
echo =====================================================================================================
echo.
pause
endlocal
```

- `[FINISHED]` line always restates the GitHub URL.
- Always end with `pause` (so double-clicked `.bat` windows don't vanish)
  followed by `endlocal`.

---

## 12. Full Minimal Template

Use this as the literal starting point for any new Windows script — replace
the `<...>` placeholders and fill in the PowerShell logic:

```bat
@echo off
setlocal EnableDelayedExpansion
title <Purpose> - by Biraj2004
cd /d "%~dp0"

:: ===================================================================================================
:: GitHub      : https://github.com/Biraj2004
:: Developer   : Biraj
:: Description : <Full description, with bullet points for key behaviors>
:: ===================================================================================================

echo =====================================================================================================
echo                       <SCRIPT TITLE IN CAPS>
echo                       Developed by : Biraj
echo                       GitHub       : https://github.com/Biraj2004
echo =====================================================================================================
echo.
echo [INFO] Working Folder   : %CD%
echo [INFO] <...additional INFO lines...>
echo.
echo =====================================================================================================
echo  WARNING: This will <ACTION> <target> inside:
echo    %CD%
echo =====================================================================================================
echo.
set "CONFIRM="
set /p CONFIRM=Type Y and press Enter to proceed, or N to cancel : 

if /i "%CONFIRM%"=="Y" goto :PROCEED
if /i "%CONFIRM%"=="YES" goto :PROCEED

echo.
echo [CANCELLED] No files were <verbed>. Exiting safely.
echo.
pause
endlocal
exit /b 0

:PROCEED
echo.
echo [PROCESSING] Launching PowerShell engine...
echo =====================================================================================================

where powershell >nul 2>&1
if errorlevel 1 (
    echo [ERROR] PowerShell was not found on this system. Cannot continue.
    echo.
    pause
    exit /b 1
)

powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -EncodedCommand "<Base64 payload>"

echo ---------------------------------------------------------------------------
echo =====================================================================================================
echo [FINISHED] Script execution finished. GitHub: https://github.com/Biraj2004
echo =====================================================================================================
echo.
pause
endlocal
```

---

## 13. Non-Negotiables Checklist

Before committing a new `.bat` script, confirm:

- [ ] Filename is `Win_Title_Case_With_Underscores.bat` (starts with the
      `Win_` prefix) in the repo root.
- [ ] `title`, header comment, and console banner all reference
      `Biraj` / `Biraj2004` branding exactly as shown.
- [ ] `[INFO]` block accurately lists every parameter that affects behavior.
- [ ] `[WARNING]` block states exactly what will change and where.
- [ ] Script **cannot** mutate anything without an explicit `Y`/`YES` prompt.
- [ ] Cancel path exits cleanly with `exit /b 0` and touches nothing.
- [ ] Heavy logic is in PowerShell via `-EncodedCommand`, not raw batch.
- [ ] Color palette and log tags match Section 9.1 exactly.
- [ ] `[SUMMARY]` + `[SUCCESS]` block is printed at the end, in `Green`.
- [ ] Ends with `pause` + `endlocal`.
- [ ] A matching macOS script exists per `MACOS_SCRIPT_STYLE_GUIDE.md`.
