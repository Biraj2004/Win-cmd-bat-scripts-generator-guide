#!/bin/bash
# =======================================================================================================
# GitHub      : https://github.com/Biraj2004
# Developer   : Biraj
# Description : Recursively scans this folder and ALL subfolders for
#                .mp4, .mkv, .webm, and .pdf files, and strips a leading numeric
#                prefix (e.g. "07-", "12 -") from each filename, IF
#                the text before the FIRST hyphen is made up of
#                digits only.
#                - Only the part up to and including the first "-"
#                  is removed. Everything after it is left untouched.
#                - Files whose prefix is NOT purely numeric (e.g.
#                  "Part1-Intro.mp4") are left alone.
#                - Files with no hyphen at all are left alone.
#                - Re-running this script is SAFE: files without a numeric
#                  prefix are skipped automatically.
# =======================================================================================================

# Move into this script's own folder (mirrors double-click behaviour on Windows)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
ROOT_DIR="$SCRIPT_DIR"

echo "======================================================================================================="
echo "                      STRIP NUMBERED PREFIX SCRIPT"
echo "                      Developed by : Biraj"
echo "                      GitHub       : https://github.com/Biraj2004"
echo "======================================================================================================="
echo
echo "[INFO] Working Folder   : $ROOT_DIR"
echo "[INFO] Target Extensions: .mp4, .mkv, .webm, .pdf"
echo "[INFO] Action           : Strip leading \"NUMBER-\" prefix from filenames"
echo "[INFO] Scope            : Current folder + ALL subfolders (Recursive)"
echo "[INFO] Safety           : Only files with a PURELY NUMERIC prefix before"
echo "[INFO]                    the first hyphen are touched. Everything else"
echo "[INFO]                    is left completely untouched."
echo
echo "======================================================================================================="
echo " WARNING: This will RENAME .mp4, .mkv, .webm, and .pdf files inside:"
echo "   $ROOT_DIR"
echo " ...and every SUB-FOLDER inside it."
echo "======================================================================================================="
echo
read -r -p "Type Y and press Enter to proceed, or N to cancel : " CONFIRM
CONFIRM=$(echo "$CONFIRM" | tr -d '\r')

case "$CONFIRM" in
    [Yy]|[Yy][Ee][Ss])
        ;;
    *)
        echo
        echo "[CANCELLED] No files were scanned or renamed. Exiting safely."
        exit 0
        ;;
esac

echo
echo "[PROCESSING] Scanning recursively..."
echo "-------------------------------------------------------------------------------------------------------"

ALL_FILES=()
while IFS= read -r -d '' f; do
    base="$(basename "$f")"
    if echo "$base" | grep -qE '^[0-9]+[[:space:]]*-'; then
        ALL_FILES+=("$f")
    fi
done < <(find "$ROOT_DIR" -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" -o -iname "*.pdf" \) -print0)

TOTAL=${#ALL_FILES[@]}

if [ "$TOTAL" -eq 0 ]; then
    echo "[INFO] No matching files (.mp4, .mkv, .webm, .pdf) with numeric prefixes found."
    echo
    read -n 1 -s -r -p "Press any key to exit..."
    echo
    exit 0
fi

FOLDERS=()
for f in "${ALL_FILES[@]}"; do
    d="$(dirname "$f")"
    already=0
    for existing in "${FOLDERS[@]}"; do
        if [ "$existing" == "$d" ]; then
            already=1
            break
        fi
    done
    if [ "$already" -eq 0 ]; then
        FOLDERS+=("$d")
    fi
done

IFS=$'\n' SORTED_FOLDERS=($(printf '%s\n' "${FOLDERS[@]}" | sort))
unset IFS

echo "[INFO] Found $TOTAL matching file(s) across ${#SORTED_FOLDERS[@]} folder(s)."
echo

GRAND_RENAMED=0
GRAND_SKIPPED=0
GRAND_ERRORS=0

for folder in "${SORTED_FOLDERS[@]}"; do
    FOLDER_FILES=()
    while IFS= read -r -d '' f; do
        base="$(basename "$f")"
        if echo "$base" | grep -qE '^[0-9]+[[:space:]]*-'; then
            FOLDER_FILES+=("$f")
        fi
    done < <(find "$folder" -maxdepth 1 -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" -o -iname "*.pdf" \) -print0)

    FOLDER_TOTAL=${#FOLDER_FILES[@]}
    if [ "$FOLDER_TOTAL" -eq 0 ]; then
        continue
    fi

    echo "-------------------------------------------------------------------------------------------------------"
    echo "[FOLDER]  $folder"
    echo "          $FOLDER_TOTAL file(s) with numeric prefixes"

    for filepath in "${FOLDER_FILES[@]}"; do
        base="$(basename "$filepath")"
        dirpath="$(dirname "$filepath")"

        new_name=$(printf '%s' "$base" | sed -E 's/^[0-9]+[[:space:]]*-[[:space:]]*//')

        if [ "$base" == "$new_name" ]; then
            echo "[SKIP]     $base  (prefix already absent)"
            GRAND_SKIPPED=$((GRAND_SKIPPED+1))
            continue
        fi

        if [ -e "$dirpath/$new_name" ]; then
            echo "[ERROR]    Target name already exists, skipped: $dirpath/$new_name"
            GRAND_ERRORS=$((GRAND_ERRORS+1))
            continue
        fi

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
    done
done

echo
echo "-------------------------------------------------------------------------------------------------------"
echo "[SUMMARY] Total matched : $TOTAL"
echo "[SUMMARY] Folders       : ${#SORTED_FOLDERS[@]}"
echo "[SUMMARY] Renamed       : $GRAND_RENAMED"
echo "[SUMMARY] Skipped       : $GRAND_SKIPPED"
echo "[SUMMARY] Errors        : $GRAND_ERRORS"
echo "[SUCCESS] Strip numeric prefix task complete!"
echo "======================================================================================================="
echo "[FINISHED] Script execution finished. GitHub: https://github.com/Biraj2004"
echo "======================================================================================================="
echo
read -n 1 -s -r -p "Press any key to exit..."
echo
