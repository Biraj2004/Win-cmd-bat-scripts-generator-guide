#!/bin/bash
# =======================================================================================================
# GitHub      : https://github.com/Biraj2004
# Developer   : Biraj
# Description : Recursively scans this folder and ALL subfolders for
#                ANY file whose name contains the "@hamaracollege" /
#                "@hmaracollege" watermark tag (in common case
#                variations), and strips ONLY that tag out of the
#                filename.
#                - Works on ALL file types (mp4, srt, vtt, pdf, etc.)
#                  since Udemy course downloads mix file types.
#                - Nothing else in the filename is touched.
#                - Re-running this script is SAFE: files without the
#                  watermark tag are skipped automatically.
# =======================================================================================================

# Move into this script's own folder (mirrors double-click behaviour on Windows)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
ROOT_DIR="$SCRIPT_DIR"

echo "======================================================================================================="
echo "                      REMOVE \"@HAMARACOLLEGE\" WATERMARK SCRIPT"
echo "                      Developed by : Biraj"
echo "                      GitHub       : https://github.com/Biraj2004"
echo "======================================================================================================="
echo
echo "[INFO] Working Folder   : $ROOT_DIR"
echo "[INFO] Target Files     : ALL files (any extension)"
echo "[INFO] Text Removed     : \"@hamaracollege\" / \"@hmaracollege\" (common case variants)"
echo "[INFO] Scope            : Current folder + ALL subfolders (Recursive)"
echo "[INFO] Safety           : Only the matched tag text is stripped out."
echo "[INFO]                    The rest of each filename is left untouched."
echo
echo "======================================================================================================="
echo " WARNING: This will RENAME files containing \"@hamaracollege\" inside:"
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
    if echo "$base" | grep -iqE '@h[a]?maracollege'; then
        ALL_FILES+=("$f")
    fi
done < <(find "$ROOT_DIR" -type f -print0)

TOTAL=${#ALL_FILES[@]}

if [ "$TOTAL" -eq 0 ]; then
    echo "[INFO] No matching files containing watermark tag found."
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
        if echo "$base" | grep -iqE '@h[a]?maracollege'; then
            FOLDER_FILES+=("$f")
        fi
    done < <(find "$folder" -maxdepth 1 -type f -print0)

    FOLDER_TOTAL=${#FOLDER_FILES[@]}
    if [ "$FOLDER_TOTAL" -eq 0 ]; then
        continue
    fi

    echo "-------------------------------------------------------------------------------------------------------"
    echo "[FOLDER]  $folder"
    echo "          $FOLDER_TOTAL file(s) matching watermark"

    for filepath in "${FOLDER_FILES[@]}"; do
        base="$(basename "$filepath")"
        dirpath="$(dirname "$filepath")"

        new_name=$(echo "$base" | sed -E 's/@[hH][aA]?[mM][aA][rR][aA][cC][oO][lL][lL][eE][gG][eE]//g')

        if [ "$base" == "$new_name" ]; then
            echo "[SKIP]     $base  (watermark tag already absent)"
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
echo "[SUCCESS] Watermark removal task complete!"
echo "======================================================================================================="
echo "[FINISHED] Script execution finished. GitHub: https://github.com/Biraj2004"
echo "======================================================================================================="
echo
read -n 1 -s -r -p "Press any key to exit..."
echo
