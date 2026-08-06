#!/bin/bash
# =======================================================================================================
# GitHub      : https://github.com/Biraj2004
# Developer   : Biraj
# Description : Checks if FFmpeg Full Build (ffmpeg, ffprobe, ffplay) is installed and in PATH.
#                - If ALREADY installed: Displays status, shows BOTH environment PATH status
#                  and full executable locations for ffmpeg, ffprobe, ffplay + version info.
#                - If NOT installed: Installs FFmpeg via Homebrew (or direct static build),
#                  configures the environment PATH persistently (~/.zshrc / ~/.bash_profile),
#                  and confirms full executable paths.
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
echo "                      FFMPEG FULL BUILD AUTOMATED INSTALLER & PATH CONFIGURATOR (macOS)"
echo "                      Developed by : Biraj"
echo "                      GitHub       : https://github.com/Biraj2004"
echo "======================================================================================================="
echo

# Check if FFmpeg binaries are already installed
FFMPEG_PATH=$(command -v ffmpeg 2>/dev/null)
FFPROBE_PATH=$(command -v ffprobe 2>/dev/null)
FFPLAY_PATH=$(command -v ffplay 2>/dev/null)

if [ -n "$FFMPEG_PATH" ]; then
    BIN_DIR="$(dirname "$FFMPEG_PATH")"
    if [[ ":$PATH:" == *":$BIN_DIR:"* ]]; then
        PATH_STATUS="ALREADY SET in shell environment PATH ($BIN_DIR)"
    else
        PATH_STATUS="ACTIVE in current session PATH ($BIN_DIR)"
    fi

    printf "${GREEN}[INFO] FFmpeg status         : ALREADY INSTALLED${NC}\n"
    printf "${GREEN}[INFO] Environment PATH      : %s${NC}\n" "$PATH_STATUS"
    echo
    printf "${CYAN} [ffmpeg]  : %s${NC}\n" "$FFMPEG_PATH"
    if [ -n "$FFPROBE_PATH" ]; then printf "${CYAN} [ffprobe] : %s${NC}\n" "$FFPROBE_PATH"; else printf "${YELLOW} [ffprobe] : Not found in PATH${NC}\n"; fi
    if [ -n "$FFPLAY_PATH" ]; then printf "${CYAN} [ffplay]  : %s${NC}\n" "$FFPLAY_PATH"; else printf "${YELLOW} [ffplay]  : Not found in PATH${NC}\n"; fi
    
    echo
    FFVER=$(ffmpeg -version 2>/dev/null | head -n 1)
    printf "${GRAY} [Version] : %s${NC}\n" "$FFVER"
    echo
    echo "======================================================================================================="
    printf "${GREEN}[SUCCESS] No further installation needed. Exiting safely.${NC}\n"
    echo "======================================================================================================="
    echo
    read -n 1 -s -r -p "Press any key to exit..." 2>/dev/null || read -r
    echo
    exit 0
fi

echo "[INFO] Working Folder   : $ROOT_DIR"
echo "[INFO] Status           : FFmpeg is currently NOT found in system PATH."
echo "[INFO] Environment PATH : NOT CONFIGURED"
echo "[INFO] Action           : Download latest FFmpeg Full Build (ffmpeg, ffprobe, ffplay) & set User PATH."
echo
echo "======================================================================================================="
echo " WARNING: This will install FFmpeg Full Build and update shell environment PATH config."
echo "======================================================================================================="
echo
read -r -p "Type Y and press Enter to proceed with installation, or N to cancel : " CONFIRM
CONFIRM=$(echo "$CONFIRM" | tr -d '\r')

case "$CONFIRM" in
    [Yy]|[Yy][Ee][Ss])
        ;;
    *)
        echo
        echo "[CANCELLED] Installation cancelled. No files were downloaded or modified."
        exit 0
        ;;
esac

echo
echo "[PROCESSING] Installing FFmpeg Full Build..."

BREW_CMD=$(command -v brew 2>/dev/null)

if [ -n "$BREW_CMD" ]; then
    printf "${CYAN}[PROCESSING] Found Homebrew. Running: brew install ffmpeg ...${NC}\n"
    brew install ffmpeg
    PATH_ACTION="ALREADY SET via Homebrew"
else
    printf "${CYAN}[PROCESSING] Homebrew not found. Downloading static FFmpeg binaries ...${NC}\n"
    INSTALL_DIR="$HOME/.local/bin"
    mkdir -p "$INSTALL_DIR"
    
    for TOOL in ffmpeg ffprobe ffplay; do
        TEMP_ZIP="/tmp/${TOOL}_macos.zip"
        curl -sL "https://evermeet.cx/ffmpeg/getrelease/${TOOL}/zip" -o "$TEMP_ZIP" 2>/dev/null
        if [ -s "$TEMP_ZIP" ]; then
            unzip -o "$TEMP_ZIP" -d "$INSTALL_DIR" 2>/dev/null
            rm -f "$TEMP_ZIP"
            chmod +x "$INSTALL_DIR/$TOOL" 2>/dev/null
        fi
    done

    # Add to shell profile if not present
    for PROFILE in "$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.profile"; do
        if [ -f "$PROFILE" ]; then
            if ! grep -q "$INSTALL_DIR" "$PROFILE"; then
                echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$PROFILE"
            fi
        fi
    done
    export PATH="$INSTALL_DIR:$PATH"
    PATH_ACTION="UPDATED & CONFIGURED PERMANENTLY in shell profile ($INSTALL_DIR)"
fi

FINAL_FF=$(command -v ffmpeg 2>/dev/null)
FINAL_FP=$(command -v ffprobe 2>/dev/null)
FINAL_FY=$(command -v ffplay 2>/dev/null)

echo
echo "======================================================================================================="
printf "${GREEN}[SUCCESS] FFmpeg Full Build installation & PATH configuration complete!${NC}\n"
printf "${GREEN} [Environment PATH] : %s${NC}\n" "$PATH_ACTION"
if [ -n "$FINAL_FF" ]; then printf "${CYAN} [ffmpeg]           : %s${NC}\n" "$FINAL_FF"; fi
if [ -n "$FINAL_FP" ]; then printf "${CYAN} [ffprobe]          : %s${NC}\n" "$FINAL_FP"; fi
if [ -n "$FINAL_FY" ]; then printf "${CYAN} [ffplay]           : %s${NC}\n" "$FINAL_FY"; fi
echo "======================================================================================================="
echo "[FINISHED] Script execution finished. GitHub: https://github.com/Biraj2004"
echo "======================================================================================================="
echo
read -n 1 -s -r -p "Press any key to exit..." 2>/dev/null || read -r
echo
