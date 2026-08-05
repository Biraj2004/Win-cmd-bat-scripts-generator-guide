# macOS (.sh) Script Style Guide

This document defines the **mandatory** structure, branding, presentation,
and safety conventions for every macOS-equivalent `.sh` script in this
repository. It mirrors `WIN_SCRIPT_STYLE_GUIDE.md` — every Windows script
must have a Bash twin built to this exact spec, so behavior and presentation
match 1:1 across platforms.

Reverse-engineered from
`Mac-Equivalent-Scripts/macOS_Add_numberring_based_on_creation_date_ascending.sh`.

---

## 1. File Naming Convention

**Pattern:** `macOS_Title_Case_With_Underscores.sh`

- Same Title_Case_With_Underscores base name as the Windows `.bat` twin,
  prefixed with `macOS_`.
- Every word starts with a **capital letter**; spaces become underscores.
- Extension is always lowercase `.sh`.
- Lives inside the `Mac-Equivalent-Scripts/` subfolder — **never** in the
  repo root. The root is reserved for Windows `.bat` scripts only.

```
Windows script (root)                 : Rename_Files_By_Creation_Date.bat
macOS equivalent (Mac-Equivalent-Scripts/) : macOS_Rename_Files_By_Creation_Date.sh
```

---

## 2. Overall File Skeleton

Every script follows this exact section order:

1. `#!/bin/bash` shebang
2. Header comment block (developer branding + full description)
3. Move into the script's own directory (mirrors Windows double-click behavior)
4. Console banner block (visual branding)
5. `[INFO]` block (parameters/behavior summary)
6. `[WARNING]` block (what will change, blast radius)
7. Y/N confirmation prompt (safety gate)
8. Cancel path (safe, no-op exit)
9. Proceed path → `[PROCESSING]` → scan/collect → per-folder/per-item loop
10. Footer `[SUMMARY]` + `[FINISHED]` banner
11. "Press any key to exit" + trailing `echo`

Nothing may run that changes files on disk before step 7's confirmation
is explicitly accepted.

---

## 3. Shebang + Header Comment Block

```bash
#!/bin/bash
# ===================================================================================================
# GitHub      : https://github.com/Biraj2004
# Developer   : Biraj
# Description : <What the script scans/targets>
#                <Sorting/selection rule, if any>
#                - <Key behavior bullet 1>
#                - <Key behavior bullet 2>
#                - Original filename text is NEVER modified beyond the documented change.
#                - Re-running this script is SAFE: <idempotency guarantee>.
# ===================================================================================================
```

Rules for this block:
- `GitHub` and `Developer` lines are **fixed** — copy them verbatim, identical
  to the Windows twin.
- The `Description` text should be functionally identical to the Windows
  script's description, only adapting platform-specific terms (e.g.
  `CreationTime` → `birthtime`).
- Separator lines use `# ` followed by **103 `=` characters**.

---

## 4. Move Into Script's Own Directory

Immediately after the header comment, so the script behaves the same
whether double-clicked or run from Terminal, and mirrors the Windows
`cd /d "%~dp0"` behavior:

```bash
# Move into this script's own folder (mirrors double-click behaviour on Windows)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
ROOT_DIR="$SCRIPT_DIR"
```

- Always use `${BASH_SOURCE[0]}`, never `$0`, so it resolves correctly when
  sourced or invoked via a symlink.
- Always `exit 1` if the `cd` fails — never continue in an unknown directory.
- Store the resolved path in a clearly named variable (`ROOT_DIR`) reused
  for all messaging and scanning below.

---

## 5. Console Banner Block

```bash
echo "======================================================================================================="
echo "                      FILE AUTO-NUMBERING SCRIPT"
echo "                      Developed by : Biraj"
echo "                      GitHub       : https://github.com/Biraj2004"
echo "======================================================================================================="
echo
```

- Separator lines are `echo "` + **103 `=` characters** + `"`.
- Title line indent and wording mirror the Windows banner exactly (same
  script title in caps, same "Developed by" / "GitHub" lines).
- Use bare `echo` for blank lines (not `echo ""`), matching the reference
  script's style.

---

## 6. `[INFO]` Block

```bash
echo "[INFO] Working Folder   : $ROOT_DIR"
echo "[INFO] Target Extensions: <ext1>, <ext2>, ..."
echo "[INFO] Sorting Rule     : <rule>, Ascending/Descending"
echo "[INFO] Numbering Format : <format rules, if applicable>"
echo "[INFO] Scope            : Current folder + ALL subfolders (Recursive)"
echo "[INFO] Numbering Rule   : <per-folder / global numbering rule, if applicable>"
echo "[INFO] Safety           : <what is protected / never modified>"
echo
```

- Content and label alignment must match the Windows twin's `[INFO]` block
  line-for-line (same labels, same order, same padding to align colons).
- Use `$ROOT_DIR` (or the relevant variable) instead of `%CD%`.

---

## 7. `[WARNING]` Block

```bash
echo "======================================================================================================="
echo " WARNING: This will <RENAME/DELETE/MOVE/CONVERT> <file types> inside:"
echo "   $ROOT_DIR"
echo " ...and every SUB-FOLDER inside it."          # omit this line if not recursive
echo "======================================================================================================="
echo
```

---

## 8. Y/N Safety Gate

**Every script that modifies files must ask for confirmation before doing
anything irreversible.** No exceptions — identical requirement to the
Windows twin.

```bash
read -r -p "Type Y and press Enter to proceed, or N to cancel : " CONFIRM

case "$CONFIRM" in
    [Yy]|[Yy][Ee][Ss])
        ;;
    *)
        echo
        echo "[CANCELLED] No files were scanned or renamed. Exiting safely."
        exit 0
        ;;
esac
```

- Accepts `Y` or `YES` (case-insensitive) only, matching Windows behavior.
- Implemented with a `case` statement using bracket-expression patterns
  (`[Yy]|[Yy][Ee][Ss]`) — do not use `read -p ... [[ ... ]]` regex matching
  instead, keep it consistent across all scripts.
- The cancel path must state clearly that **nothing was touched** and exit
  with code `0`.

---

## 9. Processing / Scan Phase

```bash
echo
echo "[PROCESSING] Scanning recursively..."
echo "-------------------------------------------------------------------------------------------------------"
```

- Header line uses the **light** separator (103 `-` characters), not the
  heavy `=` one — this matches the reference script and visually
  distinguishes "now actually doing work" from the banner sections above.

### 9.1 File Collection Conventions

- Collect files with `find ... -print0` piped into a `while IFS= read -r -d ''`
  loop, appended into a Bash array. This is the **only** acceptable pattern
  for building file lists — it safely handles spaces, newlines, and special
  characters in filenames. Never parse `ls` output or use unquoted globs.

  ```bash
  ALL_FILES=()
  while IFS= read -r -d '' f; do
      ALL_FILES+=("$f")
  done < <(find "$ROOT_DIR" -type f \( -iname "*.ext1" -o -iname "*.ext2" \) -print0)
  ```

- If zero matches are found, print an `[INFO]` line (not an error), then:
  ```bash
  echo
  read -n 1 -s -r -p "Press any key to exit..."
  echo
  exit 0
  ```

- To group files by folder, deduplicate directory names by iterating and
  comparing (as in the reference script), then sort with
  `IFS=$'\n' SORTED_FOLDERS=($(printf '%s\n' "${FOLDERS[@]}" | sort)); unset IFS`.
  Always `unset IFS` immediately after use.

### 9.2 Per-Folder / Per-Item Loop Conventions

- Every folder/group processed prints a `[FOLDER]` header followed by an
  indented detail line, e.g.:
  ```bash
  echo "-------------------------------------------------------------------------------------------------------"
  echo "[FOLDER]  $folder"
  echo "          $FOLDER_TOTAL file(s) -- using $DIGITS-digit numbering"
  ```
- Timestamp sorting uses `stat -f "%B"` (birthtime) with a fallback to
  `stat -f "%m"` (modified time) when birthtime is `0` or empty — this is
  the macOS/BSD `stat` equivalent of Windows `CreationTime` and must be
  used for any time-based sort:
  ```bash
  bt=$(stat -f "%B" "$f" 2>/dev/null)
  if [ -z "$bt" ] || [ "$bt" = "0" ]; then
      bt=$(stat -f "%m" "$f")
  fi
  ```
- **Log tag vocabulary** — identical set to the Windows guide, do not
  invent synonyms:
  - `[INFO]`, `[FOLDER]`, `[SKIP]`, `[ERROR]`, `[SUMMARY]`, `[SUCCESS]`,
    `[CANCELLED]`, `[PROCESSING]`, and the action verb tag
    (`[RENAMED]` / `[MOVED]` / `[CONVERTED]` / `[DELETED]`).
- No-op / already-correct items are `[SKIP]`, not silently ignored:
  ```bash
  echo "[SKIP]     $base  (already numbered correctly)"
  ```
- A completed action prints the "from" line, then an indented `-->` line
  with the "to" value, matching the Windows two-line style:
  ```bash
  echo "[RENAMED]  $base"
  echo "     -->   $new_name"
  ```
- Every mutation (`mv`, `rm`, `cp`, etc.) must check its exit status and
  route failures into `[ERROR]` plus a running error counter — never let
  one bad item abort the whole run:
  ```bash
  if mv "$filepath" "$dirpath/$new_name" 2>/tmp/.rename_err.$$; then
      echo "[RENAMED]  $base"
      echo "     -->   $new_name"
      GRAND_RENAMED=$((GRAND_RENAMED+1))
  else
      err=$(cat /tmp/.rename_err.$$ 2>/dev/null)
      echo "[ERROR]    Could not rename $filepath -- $err"
      GRAND_ERRORS=$((GRAND_ERRORS+1))
  fi
  rm -f /tmp/.rename_err.$$
  ```
  Always clean up any temp file used to capture stderr, using a
  PID-scoped name (`/tmp/.rename_err.$$`) to avoid collisions.
- Maintain running counters across the whole script:
  `GRAND_RENAMED` / `GRAND_SKIPPED` / `GRAND_ERRORS` (rename the first per
  the actual verb, e.g. `GRAND_MOVED`, `GRAND_CONVERTED`), initialized to
  `0` before the loop and incremented with `$((VAR+1))`.

---

## 10. No Color Codes in Bash Output

Unlike the Windows PowerShell engine (which uses `-ForegroundColor`), the
reference Bash script prints **plain, uncolored** `echo` output. Do not
introduce ANSI color codes (`\033[...]`) into macOS scripts — keep terminal
output monochrome so behavior is predictable across all terminal emulators
and matches the existing reference script. Visual hierarchy is conveyed
through the bracketed tags (`[FOLDER]`, `[SKIP]`, `[ERROR]`, ...) and
indentation only, not color.

---

## 11. Separator Lines Reference

Use exactly these two separator styles, both **103 characters** of the
repeated symbol wrapped in double quotes after `echo`:

| Style       | Usage                                                        | Weight               |
|-------------|---------------------------------------------------------------|----------------------|
| Heavy (`=`) | Header comment, console banner, `[WARNING]` block, footer     | Major section breaks |
| Light (`-`) | Start of `[PROCESSING]` phase, per-folder headers, `[SUMMARY]` header | Minor breaks   |

Do not shorten or lengthen these arbitrarily — copy an existing separator
line and edit only its surrounding text, so line width stays identical
across every script in the repo (and matches the Windows twin's line width).

---

## 12. Footer Block

```bash
echo
echo "-------------------------------------------------------------------------------------------------------"
echo "[SUMMARY] Total matched : $TOTAL"
echo "[SUMMARY] Folders       : ${#SORTED_FOLDERS[@]}"
echo "[SUMMARY] Renamed       : $GRAND_RENAMED"
echo "[SUMMARY] Skipped       : $GRAND_SKIPPED"
echo "[SUMMARY] Errors        : $GRAND_ERRORS"
echo "[SUCCESS] Numbering task complete!"
echo "======================================================================================================="
echo "[FINISHED] Script execution finished. GitHub: https://github.com/Biraj2004"
echo "======================================================================================================="
echo
read -n 1 -s -r -p "Press any key to exit..."
echo
```

- `[SUMMARY]` lines list every counter tracked by the script, labels
  left-aligned with colons lined up, mirroring the Windows `[SUMMARY]`
  block exactly (same rows, same order).
- `[SUCCESS]` restates the specific task completed (not a generic phrase).
- `[FINISHED]` line always restates the GitHub URL, identical to Windows.
- Always end with `read -n 1 -s -r -p "Press any key to exit..."` followed
  by a trailing `echo` — this is the Bash equivalent of Windows `pause`.

---

## 13. Full Minimal Template

Use this as the literal starting point for any new macOS script — replace
the `<...>` placeholders and fill in the scan/loop logic:

```bash
#!/bin/bash
# ===================================================================================================
# GitHub      : https://github.com/Biraj2004
# Developer   : Biraj
# Description : <Full description, with bullet points for key behaviors>
# ===================================================================================================

# Move into this script's own folder (mirrors double-click behaviour on Windows)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
ROOT_DIR="$SCRIPT_DIR"

echo "======================================================================================================="
echo "                      <SCRIPT TITLE IN CAPS>"
echo "                      Developed by : Biraj"
echo "                      GitHub       : https://github.com/Biraj2004"
echo "======================================================================================================="
echo
echo "[INFO] Working Folder   : $ROOT_DIR"
echo "[INFO] <...additional INFO lines...>"
echo
echo "======================================================================================================="
echo " WARNING: This will <ACTION> <target> inside:"
echo "   $ROOT_DIR"
echo "======================================================================================================="
echo
read -r -p "Type Y and press Enter to proceed, or N to cancel : " CONFIRM

case "$CONFIRM" in
    [Yy]|[Yy][Ee][Ss])
        ;;
    *)
        echo
        echo "[CANCELLED] No files were <verbed>. Exiting safely."
        exit 0
        ;;
esac

echo
echo "[PROCESSING] Scanning recursively..."
echo "-------------------------------------------------------------------------------------------------------"

# <collect files with find ... -print0 / while read -d '' pattern>
# <group / sort / loop, printing [FOLDER], [SKIP], [<VERB>], [ERROR] as appropriate>
# <increment GRAND_* counters>

echo
echo "-------------------------------------------------------------------------------------------------------"
echo "[SUMMARY] <counter rows...>"
echo "[SUCCESS] <task> complete!"
echo "======================================================================================================="
echo "[FINISHED] Script execution finished. GitHub: https://github.com/Biraj2004"
echo "======================================================================================================="
echo
read -n 1 -s -r -p "Press any key to exit..."
echo
```

---

## 14. Non-Negotiables Checklist

Before committing a new `.sh` script, confirm:

- [ ] Filename is `macOS_Title_Case_With_Underscores.sh` inside
      `Mac-Equivalent-Scripts/`, matching the Windows twin's base name.
- [ ] Header comment and console banner reference `Biraj` / `Biraj2004`
      branding exactly as shown, identical wording to the Windows twin.
- [ ] Script `cd`s into its own directory via `${BASH_SOURCE[0]}` before
      doing anything else.
- [ ] `[INFO]` block matches the Windows twin's `[INFO]` block line-for-line
      (adapted only for platform-specific terms).
- [ ] `[WARNING]` block states exactly what will change and where.
- [ ] Script **cannot** mutate anything without an explicit `Y`/`YES` prompt
      via the `case` pattern shown in Section 8.
- [ ] Cancel path exits cleanly with `exit 0` and touches nothing.
- [ ] File collection uses `find ... -print0` + `while IFS= read -r -d ''`
      (never unquoted globs or `ls` parsing).
- [ ] Time-based sorts use `stat -f "%B"` with `stat -f "%m"` fallback.
- [ ] No ANSI color codes — plain `echo` output only.
- [ ] Log tags match Section 9.2 exactly (same vocabulary as the Windows
      guide).
- [ ] `[SUMMARY]` + `[SUCCESS]` block is printed at the end, mirroring the
      Windows twin's counters.
- [ ] Ends with `read -n 1 -s -r -p "Press any key to exit..."` + `echo`.
- [ ] Behavior is functionally equivalent to its Windows `.bat` twin.
