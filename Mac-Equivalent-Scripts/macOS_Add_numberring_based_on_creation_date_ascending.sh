#!/bin/bash
# =========================================================================================================
# GitHub      : https://github.com/Biraj2004
# Developer   : Biraj
# Description : Recursively scans this folder and ALL subfolders for
#                .mp4, .mkv, .webm, and .pdf files, sorts them by earliest
#                Created/Downloaded time (birthtime), ascending, and
#                prefixes each filename with a sequential number
#                ("01 - ", "02 - ", ...).
#                - EACH FOLDER (this folder + every subfolder) is numbered
#                  INDEPENDENTLY, starting fresh at 01 (or 001... if that
#                  specific folder has 100+ matching files).
#                - If a folder has less than 100 matched files -> 2-digit (01, 02 ...)
#                - If a folder has 100 or more matched files   -> auto-expands digits (001, 0001 ...)
#                - Original filename text is NEVER modified, only prefixed.
#                - Re-running this script is SAFE: any old "NN - " prefix is
#                  stripped first, then files are freshly re-numbered.
# =========================================================================================================

# Move into this script's own folder (mirrors double-click behaviour on Windows)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
ROOT_DIR="$SCRIPT_DIR"

echo "======================================================================================================="
echo "                      FILE AUTO-NUMBERING SCRIPT"
echo "                      Developed by : Biraj"
echo "                      GitHub       : https://github.com/Biraj2004"
echo "======================================================================================================="
echo
echo "[INFO] Working Folder   : $ROOT_DIR"
echo "[INFO] Target Extensions: .mp4, .mkv, .webm, .pdf"
echo "[INFO] Sorting Rule     : Earliest Created/Downloaded Time (birthtime), Ascending"
echo "[INFO] Numbering Format : 2-digit (01 - ) if a folder has less than 100 files"
echo "[INFO]                    3+ digit (001 - / 0001 - ...) if that folder has 100 or more files"
echo "[INFO] Scope            : Current folder + ALL subfolders (Recursive)"
echo "[INFO] Numbering Rule   : Each folder gets its OWN independent numbering, restarting at 01"
echo "[INFO] Safety           : Only the numbered-prefix is added/replaced. Titles are untouched."
echo
echo "======================================================================================================="
echo " WARNING: This will RENAME .mp4, .mkv, .webm, and .pdf files inside:"
echo "   $ROOT_DIR"
echo " ...and every SUB-FOLDER inside it."
echo "======================================================================================================="
echo
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

echo
echo "[PROCESSING] Scanning recursively..."
echo "-------------------------------------------------------------------------------------------------------"

# Collect every matching file recursively (null-delimited, handles spaces/special chars safely)
ALL_FILES=()
while IFS= read -r -d '' f; do
    ALL_FILES+=("$f")
done < <(find "$ROOT_DIR" -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" -o -iname "*.pdf" \) -print0)

TOTAL=${#ALL_FILES[@]}

if [ "$TOTAL" -eq 0 ]; then
    echo "[INFO] No matching files (.mp4, .mkv, .webm, .pdf) found."
    echo
    read -n 1 -s -r -p "Press any key to exit..."
    echo
    exit 0
fi

# Build a unique, sorted list of folders that contain matching files
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
echo "[INFO] Each folder is numbered independently, starting fresh at 01 (or 001...)."
echo

GRAND_RENAMED=0
GRAND_SKIPPED=0
GRAND_ERRORS=0

for folder in "${SORTED_FOLDERS[@]}"; do

    FOLDER_FILES=()
    while IFS= read -r -d '' f; do
        FOLDER_FILES+=("$f")
    done < <(find "$folder" -maxdepth 1 -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" -o -iname "*.pdf" \) -print0)

    FOLDER_TOTAL=${#FOLDER_FILES[@]}
    if [ "$FOLDER_TOTAL" -eq 0 ]; then
        continue
    fi

    # Pair each file with its birthtime (falls back to modified time if birthtime is unavailable)
    TIMESTAMPED=()
    for f in "${FOLDER_FILES[@]}"; do
        bt=$(stat -f "%B" "$f" 2>/dev/null)
        if [ -z "$bt" ] || [ "$bt" = "0" ]; then
            bt=$(stat -f "%m" "$f")
        fi
        TIMESTAMPED+=("$bt"$'\t'"$f")
    done

    IFS=$'\n' SORTED_TS=($(printf '%s\n' "${TIMESTAMPED[@]}" | sort -n -t $'\t' -k1,1))
    unset IFS

    if [ "$FOLDER_TOTAL" -lt 100 ]; then
        DIGITS=2
    else
        DIGITS=${#FOLDER_TOTAL}
    fi

    echo "-------------------------------------------------------------------------------------------------------"
    echo "[FOLDER]  $folder"
    echo "          $FOLDER_TOTAL file(s) -- using $DIGITS-digit numbering"

    COUNT=1
    for entry in "${SORTED_TS[@]}"; do
        filepath="${entry#*$'\t'}"
        base="$(basename "$filepath")"
        dirpath="$(dirname "$filepath")"

        prefix=$(printf "%0${DIGITS}d" "$COUNT")

        # Strip any existing "NN - " (2+ digit) numbering prefix before re-numbering
        clean_name=$(printf '%s' "$base" | sed -E 's/^[0-9]{2,}[[:space:]]*-[[:space:]]*//')

        new_name="${prefix} - ${clean_name}"

        if [ "$base" == "$new_name" ]; then
            echo "[SKIP]     $base  (already numbered correctly)"
            GRAND_SKIPPED=$((GRAND_SKIPPED+1))
            COUNT=$((COUNT+1))
            continue
        fi

        if [ -e "$dirpath/$new_name" ]; then
            echo "[ERROR]    Target name already exists, skipped: $dirpath/$new_name"
            GRAND_ERRORS=$((GRAND_ERRORS+1))
            COUNT=$((COUNT+1))
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

        COUNT=$((COUNT+1))
    done
done

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
