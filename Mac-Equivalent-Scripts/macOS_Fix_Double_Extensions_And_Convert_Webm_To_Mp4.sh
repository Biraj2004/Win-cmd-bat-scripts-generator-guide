#!/bin/bash
# =======================================================================================================
# GitHub      : https://github.com/Biraj2004
# Developer   : Biraj
# Description : Recursively scans this folder and ALL subfolders to:
#                1. Identify files with double video extensions (e.g. ".mp4.mkv", ".mp4.webm",
#                   ".mp4.mp4", ".mp4.avi") and rename them to just ".mp4".
#                2. Convert any standalone ".webm" video files into ".mp4" using FFmpeg,
#                   maintaining the exact same base filename and replacing ".webm" with ".mp4".
#                - Preserves all file metadata and creation/modification timestamps.
#                - Re-running this script is SAFE: already converted/renamed files are skipped.
# =======================================================================================================

# Move into this script's own folder
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
ROOT_DIR="$SCRIPT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

echo "======================================================================================================="
echo "                      DOUBLE EXTENSION FIXER & WEBM TO MP4 CONVERTER (macOS)"
echo "                      Developed by : Biraj"
echo "                      GitHub       : https://github.com/Biraj2004"
echo "======================================================================================================="
echo
echo "[INFO] Working Folder   : $ROOT_DIR"
echo "[INFO] Scope            : Current folder + ALL subfolders (Recursive)"
echo "[INFO] Phase 1 Action   : Identify & rename double extensions (.mp4.webm, .mp4.mkv, etc. -> .mp4)"
echo "[INFO] Phase 2 Action   : Convert standalone .webm video files to .mp4 via FFmpeg"
echo "[INFO] Safety           : File timestamps (Created/Modified) and stream metadata are 100% preserved."
echo
echo "======================================================================================================="
echo " WARNING: This will rename double-extension files and convert .webm videos to .mp4 inside:"
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
        echo "[CANCELLED] No files were scanned, renamed, or converted. Exiting safely."
        exit 0
        ;;
esac

echo
echo "[PROCESSING] Scanning folder recursively: $ROOT_DIR"
echo

GRAND_DOUBLE_RENAMED=0
GRAND_WEBM_CONVERTED=0
GRAND_SKIPPED=0
GRAND_ERRORS=0

FFMPEG_CMD=$(command -v ffmpeg 2>/dev/null)

# =======================================================================================================
# PHASE 1: FIX DOUBLE EXTENSIONS
# =======================================================================================================
echo "======================================================================================================="
echo "                                PHASE 1: FIX DOUBLE EXTENSIONS                                       "
echo "======================================================================================================="
echo

DOUBLE_EXT_FILES=()
while IFS= read -r -d '' f; do
    base="$(basename "$f")"
    if echo "$base" | grep -qiE '\.(mp4)\.(webm|mkv|avi|mov|flv|ts|wmv|mp4)$'; then
        DOUBLE_EXT_FILES+=("$f")
    fi
done < <(find "$ROOT_DIR" -type f -print0)

TOTAL_DOUBLE=${#DOUBLE_EXT_FILES[@]}

if [ "$TOTAL_DOUBLE" -gt 0 ]; then
    echo "[INFO] Found $TOTAL_DOUBLE file(s) with double extensions."
    for filepath in "${DOUBLE_EXT_FILES[@]}"; do
        base="$(basename "$filepath")"
        dirpath="$(dirname "$filepath")"
        new_name=$(echo "$base" | sed -E 's/\.(webm|mkv|avi|mov|flv|ts|wmv|mp4)$//i')
        target_path="$dirpath/$new_name"

        if [ -e "$target_path" ]; then
            printf "${YELLOW}[SKIP] Cannot rename '%s' -> '%s' (Target file already exists).${NC}\n" "$base" "$new_name"
            GRAND_SKIPPED=$((GRAND_SKIPPED+1))
            continue
        fi

        if mv "$filepath" "$target_path" 2>/dev/null; then
            printf "${GREEN}[RENAMED] %s${NC}\n" "$base"
            printf "${CYAN}       -> %s (Metadata & timestamps intact)${NC}\n" "$new_name"
            GRAND_DOUBLE_RENAMED=$((GRAND_DOUBLE_RENAMED+1))
        else
            printf "${RED}[ERROR] Failed to rename '%s'${NC}\n" "$filepath"
            GRAND_ERRORS=$((GRAND_ERRORS+1))
        fi
    done
else
    printf "${YELLOW}[INFO] No double-extension files (e.g. .mp4.webm, .mp4.mkv) found.${NC}\n"
fi

echo

# =======================================================================================================
# PHASE 2: CONVERT .WEBM TO .MP4
# =======================================================================================================
echo "======================================================================================================="
echo "                                PHASE 2: CONVERT .WEBM TO .MP4                                        "
echo "======================================================================================================="
echo

if [ -n "$FFMPEG_CMD" ]; then
    WEBM_FILES=()
    while IFS= read -r -d '' f; do
        WEBM_FILES+=("$f")
    done < <(find "$ROOT_DIR" -type f -iname "*.webm" -print0)

    TOTAL_WEBM=${#WEBM_FILES[@]}

    if [ "$TOTAL_WEBM" -gt 0 ]; then
        echo "[INFO] Found $TOTAL_WEBM standalone .webm video(s) to convert."
        for filepath in "${WEBM_FILES[@]}"; do
            base="$(basename "$filepath")"
            dirpath="$(dirname "$filepath")"
            base_no_ext="${base%.*}"
            target_mp4_name="${base_no_ext}.mp4"
            target_mp4_path="$dirpath/$target_mp4_name"
            temp_mp4_path="$dirpath/${base_no_ext}._temp_converting_.mp4"

            if [ -e "$target_mp4_path" ]; then
                printf "${YELLOW}[SKIP] Cannot convert '%s' -> '%s' (Target .mp4 already exists).${NC}\n" "$base" "$target_mp4_name"
                GRAND_SKIPPED=$((GRAND_SKIPPED+1))
                continue
            fi

            rm -f "$temp_mp4_path" 2>/dev/null

            if "$FFMPEG_CMD" -hide_banner -loglevel error -i "$filepath" -map_metadata 0 -c:v libx264 -preset fast -crf 22 -c:a aac -b:a 192k "$temp_mp4_path" 2>/dev/null; then
                if [ -s "$temp_mp4_path" ]; then
                    # Preserve exact timestamp from original .webm file
                    touch -r "$filepath" "$temp_mp4_path" 2>/dev/null
                    mv "$temp_mp4_path" "$target_mp4_path" 2>/dev/null
                    rm -f "$filepath" 2>/dev/null

                    printf "${GREEN}[CONVERTED] %s${NC}\n" "$base"
                    printf "${CYAN}         -> %s (Metadata & timestamps intact)${NC}\n" "$target_mp4_name"
                    GRAND_WEBM_CONVERTED=$((GRAND_WEBM_CONVERTED+1))
                else
                    printf "${RED}[ERROR] FFmpeg produced empty output for '%s'${NC}\n" "$filepath"
                    rm -f "$temp_mp4_path" 2>/dev/null
                    GRAND_ERRORS=$((GRAND_ERRORS+1))
                fi
            else
                printf "${RED}[ERROR] FFmpeg conversion failed for '%s'${NC}\n" "$filepath"
                rm -f "$temp_mp4_path" 2>/dev/null
                GRAND_ERRORS=$((GRAND_ERRORS+1))
            fi
        done
    else
        printf "${YELLOW}[INFO] No standalone .webm video files found.${NC}\n"
    fi
else
    printf "${YELLOW}[SKIP] WebM conversion skipped because FFmpeg is not installed.${NC}\n"
fi

echo
echo "-------------------------------------------------------------------------------------------------------"
printf "${GREEN}[SUMMARY] Double Extension Files Renamed : %d${NC}\n" "$GRAND_DOUBLE_RENAMED"
printf "${GREEN}[SUMMARY] WebM Videos Converted to MP4  : %d${NC}\n" "$GRAND_WEBM_CONVERTED"
printf "${GREEN}[SUMMARY] Files Skipped                 : %d${NC}\n" "$GRAND_SKIPPED"
printf "${GREEN}[SUMMARY] Errors Encountered            : %d${NC}\n" "$GRAND_ERRORS"
printf "${GREEN}[SUCCESS] Task completed!${NC}\n"
echo "======================================================================================================="
echo "[FINISHED] Script execution finished. GitHub: https://github.com/Biraj2004"
echo "======================================================================================================="
echo
read -n 1 -s -r -p "Press any key to exit..." 2>/dev/null || read -r
echo
