#!/bin/bash
# =======================================================================================================
# GitHub      : https://github.com/Biraj2004
# Developer   : Biraj
# Description : Recursively scans this folder and ALL subfolders for
#                .mp4, .mkv, .webm, and .pdf files, sorts them by earliest
#                Created/Downloaded time (birthtime), ascending, and
#                prefixes each filename with a sequential number
#                ("01 - ", "02 - ", ...).
#                - Video files (.mp4, .mkv, .webm) and PDF files (.pdf) are
#                  numbered INDEPENDENTLY within each folder, each starting
#                  fresh at 01 (or 001... if that category has 100+ files).
#                - EACH FOLDER (this folder + every subfolder) is numbered
#                  independently.
#                - If a category in a folder has less than 100 files -> 2-digit (01, 02 ...)
#                - If a category in a folder has 100 or more files   -> auto-expands digits (001, 0001 ...)
#                - Original filename text is NEVER modified, only prefixed.
#                - Re-running this script is SAFE: any old "NN - " prefix is
#                  stripped first, then files are freshly re-numbered.
# =======================================================================================================

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
echo "[INFO] Numbering Format : 2-digit (01 - ) if a category has less than 100 files"
echo "[INFO]                    3+ digit (001 - / 0001 - ...) if that category has 100 or more files"
echo "[INFO] Scope            : Current folder + ALL subfolders (Recursive)"
echo "[INFO] Numbering Rule   : Video files (.mp4, .mkv, .webm) and PDF files (.pdf) are numbered"
echo "[INFO]                    INDEPENDENTLY in each folder, starting fresh at 01 for each type"
echo "[INFO] Safety           : Only the numbered-prefix is added/replaced. Titles are untouched."
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
echo "[INFO] Videos (.mp4, .mkv, .webm) and PDFs (.pdf) are numbered independently in each folder, starting fresh at 01."
echo

GRAND_RENAMED=0
GRAND_SKIPPED=0
GRAND_ERRORS=0

process_category() {
    local files=("$@")
    local total=${#files[@]}
    if [ "$total" -eq 0 ]; then
        return
    fi

    if [ "$total" -lt 100 ]; then
        local digits=2
    else
        local digits=${#total}
    fi

    local timestamped=()
    for f in "${files[@]}"; do
        local bt mt min_t
        bt=$(stat -f "%B" "$f" 2>/dev/null)
        if ! [[ "$bt" =~ ^[0-9]+$ ]] || [ "$bt" -eq 0 ]; then
            bt=$(stat -c "%W" "$f" 2>/dev/null)
        fi

        mt=$(stat -f "%m" "$f" 2>/dev/null)
        if ! [[ "$mt" =~ ^[0-9]+$ ]] || [ "$mt" -eq 0 ]; then
            mt=$(stat -c "%Y" "$f" 2>/dev/null)
        fi

        min_t=0
        if [[ "$bt" =~ ^[0-9]+$ ]] && [ "$bt" -gt 0 ]; then
            min_t=$bt
        fi
        if [[ "$mt" =~ ^[0-9]+$ ]] && [ "$mt" -gt 0 ]; then
            if [ "$min_t" -eq 0 ] || [ "$mt" -lt "$min_t" ]; then
                min_t=$mt
            fi
        fi
        timestamped+=("$min_t"$'\t'"$f")
    done

    local sorted_ts
    IFS=$'\n' sorted_ts=($(printf '%s\n' "${timestamped[@]}" | sort -n -t $'\t' -k1,1))
    unset IFS

    local count=1
    for entry in "${sorted_ts[@]}"; do
        local filepath="${entry#*$'\t'}"
        local base="$(basename "$filepath")"
        local dirpath="$(dirname "$filepath")"

        local prefix
        prefix=$(printf "%0${digits}d" "$count")

        local clean_name
        clean_name=$(printf '%s' "$base" | sed -E 's/^[0-9]{2,}[[:space:]]*-[[:space:]]*//')

        local new_name="${prefix} - ${clean_name}"

        if [ "$base" == "$new_name" ]; then
            echo "[SKIP]     $base  (already numbered correctly)"
            GRAND_SKIPPED=$((GRAND_SKIPPED+1))
            count=$((count+1))
            continue
        fi

        if [ -e "$dirpath/$new_name" ]; then
            echo "[ERROR]    Target name already exists, skipped: $dirpath/$new_name"
            GRAND_ERRORS=$((GRAND_ERRORS+1))
            count=$((count+1))
            continue
        fi

        if mv "$filepath" "$dirpath/$new_name" 2>/tmp/.rename_err.$$; then
            echo "[RENAMED]  $base"
            echo "     -->   $new_name"
            GRAND_RENAMED=$((GRAND_RENAMED+1))
        else
            local err
            err=$(cat /tmp/.rename_err.$$ 2>/dev/null)
            echo "[ERROR]    Could not rename $filepath -- $err"
            GRAND_ERRORS=$((GRAND_ERRORS+1))
        fi
        rm -f /tmp/.rename_err.$$

        count=$((count+1))
    done
}

for folder in "${SORTED_FOLDERS[@]}"; do

    VIDEO_FILES=()
    while IFS= read -r -d '' f; do
        VIDEO_FILES+=("$f")
    done < <(find "$folder" -maxdepth 1 -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" \) -print0)

    PDF_FILES=()
    while IFS= read -r -d '' f; do
        PDF_FILES+=("$f")
    done < <(find "$folder" -maxdepth 1 -type f -iname "*.pdf" -print0)

    V_TOTAL=${#VIDEO_FILES[@]}
    P_TOTAL=${#PDF_FILES[@]}

    if [ "$V_TOTAL" -eq 0 ] && [ "$P_TOTAL" -eq 0 ]; then
        continue
    fi

    echo "-------------------------------------------------------------------------------------------------------"
    echo "[FOLDER]  $folder"
    info_str=""
    if [ "$V_TOTAL" -gt 0 ]; then
        if [ "$V_TOTAL" -lt 100 ]; then V_DIGITS=2; else V_DIGITS=${#V_TOTAL}; fi
        info_str="$V_TOTAL Video file(s) -- using $V_DIGITS-digit numbering"
    fi
    if [ "$P_TOTAL" -gt 0 ]; then
        if [ "$P_TOTAL" -lt 100 ]; then P_DIGITS=2; else P_DIGITS=${#P_TOTAL}; fi
        if [ -n "$info_str" ]; then
            info_str="$info_str | $P_TOTAL PDF file(s) -- using $P_DIGITS-digit numbering"
        else
            info_str="$P_TOTAL PDF file(s) -- using $P_DIGITS-digit numbering"
        fi
    fi
    echo "          $info_str"

    if [ "$V_TOTAL" -gt 0 ]; then
        process_category "${VIDEO_FILES[@]}"
    fi
    if [ "$P_TOTAL" -gt 0 ]; then
        process_category "${PDF_FILES[@]}"
    fi
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
