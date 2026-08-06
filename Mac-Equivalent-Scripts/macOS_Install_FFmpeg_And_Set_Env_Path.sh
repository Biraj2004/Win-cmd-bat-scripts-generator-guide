#!/bin/bash
# =======================================================================================================
# GitHub      : https://github.com/Biraj2004
# Developer   : Biraj
# Description : Checks FFmpeg installation, version status, and PATH configuration.
#                - Minimal, tasteful color palette: Cyan header titles, White clean body text,
#                  Green status alerts, Yellow warning gates, Gray dividers.
# =======================================================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
ROOT_DIR="$SCRIPT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m' # Reset

echo -e "${GRAY}=======================================================================================================${NC}"
echo -e "${CYAN}                      FFMPEG AUTOMATED INSTALLER & VERSION MANAGER (macOS)${NC}"
echo -e "${GRAY}                      Developed by : Biraj${NC}"
echo -e "${GRAY}                      GitHub       : https://github.com/Biraj2004${NC}"
echo -e "${GRAY}=======================================================================================================${NC}"
echo
echo -e "${WHITE}[INFO] Working Folder   : $ROOT_DIR${NC}"
echo -e "${WHITE}[INFO] Scope            : Shell Environment PATH & Local Executable Binaries${NC}"
echo -e "${WHITE}[INFO] Action           : Version Check, Update Detection, Full Build Setup & PATH Configuration${NC}"
echo -e "${WHITE}[INFO] Safety           : Interactive confirmation gates protect against accidental execution.${NC}"
echo
echo -e "${YELLOW}=======================================================================================================${NC}"
echo -e "${YELLOW} WARNING: This script will check your FFmpeg installation, version status, and environment PATH.${NC}"
echo -e "${YELLOW}=======================================================================================================${NC}"
echo
read -r -p "Type Y and press Enter to proceed, or N to cancel : " CONFIRM
CONFIRM=$(echo "$CONFIRM" | tr -d '\r')

case "$CONFIRM" in
    [Yy]|[Yy][Ee][Ss])
        ;;
    *)
        echo
        echo -e "${YELLOW}[CANCELLED] Script execution cancelled. No files or environment PATH variables were modified.${NC}"
        exit 0
        ;;
esac

echo
echo -e "${WHITE}[PROCESSING] Checking FFmpeg installation and checking latest version online...${NC}"

# 1. Detect Installed Binaries
FFMPEG_PATH=$(command -v ffmpeg 2>/dev/null)
FFPROBE_PATH=$(command -v ffprobe 2>/dev/null)
FFPLAY_PATH=$(command -v ffplay 2>/dev/null)

# 2. Fetch Online Version
LATEST_VER="Unknown"
ONLINE_FETCH=$(curl -sL --connect-timeout 5 "https://www.gyan.dev/ffmpeg/builds/release-version" 2>/dev/null | tr -d '\r' | xargs)
if [ -n "$ONLINE_FETCH" ]; then
    LATEST_VER="$ONLINE_FETCH"
fi

if [ -n "$FFMPEG_PATH" ]; then
    BIN_DIR="$(dirname "$FFMPEG_PATH")"
    if [[ ":$PATH:" == *":$BIN_DIR:"* ]]; then
        PATH_STATUS="ALREADY SET in shell environment PATH ($BIN_DIR)"
    else
        PATH_STATUS="ACTIVE in current session PATH ($BIN_DIR)"
    fi

    RAW_VER=$(ffmpeg -version 2>/dev/null | head -n 1)
    INSTALLED_VER=$(echo "$RAW_VER" | grep -oE 'version [^ ]+' | awk '{print $2}')
    if [ -z "$INSTALLED_VER" ]; then
        INSTALLED_VER="$RAW_VER"
    fi

    echo -e "${GRAY}=======================================================================================================${NC}"
    echo -e "${CYAN}                                FFMPEG STATUS & VERSION REPORT                                        ${NC}"
    echo -e "${GRAY}=======================================================================================================${NC}"
    echo
    printf "${GREEN}[INFO] FFmpeg Status         : ALREADY INSTALLED${NC}\n"
    printf "${WHITE}[INFO] Current Version       : %s (%s)${NC}\n" "$INSTALLED_VER" "$RAW_VER"
    printf "${GRAY}[INFO] Latest Version        : %s${NC}\n" "$LATEST_VER"
    printf "${GREEN}[INFO] Environment PATH      : %s${NC}\n" "$PATH_STATUS"
    echo
    printf "${WHITE} [ffmpeg]  : %s${NC}\n" "$FFMPEG_PATH"
    if [ -n "$FFPROBE_PATH" ]; then printf "${WHITE} [ffprobe] : %s${NC}\n" "$FFPROBE_PATH"; else printf "${YELLOW} [ffprobe] : Not found in PATH${NC}\n"; fi
    if [ -n "$FFPLAY_PATH" ]; then printf "${WHITE} [ffplay]  : %s${NC}\n" "$FFPLAY_PATH"; else printf "${YELLOW} [ffplay]  : Not found in PATH${NC}\n"; fi
    echo

    IS_LATEST=0
    if [ "$LATEST_VER" != "Unknown" ]; then
        if [[ "$INSTALLED_VER" == *"$LATEST_VER"* ]]; then
            IS_LATEST=1
        fi
    fi

    if [ "$IS_LATEST" -eq 1 ]; then
        printf "${GREEN}[INFO] Version Check         : YOU ARE ON THE LATEST VERSION!${NC}\n"
        echo -e "${GRAY}=======================================================================================================${NC}"
        printf "${GREEN}[SUCCESS] No update needed. Exiting safely.${NC}\n"
        echo -e "${GRAY}=======================================================================================================${NC}"
        echo
        exit 0
    else
        printf "${YELLOW}[INFO] Version Check         : UPDATE AVAILABLE (v%s -> v%s)${NC}\n" "$INSTALLED_VER" "$LATEST_VER"
        echo -e "${YELLOW}=======================================================================================================${NC}"
        echo
        read -r -p "An update is available. Type Y and press Enter to UPDATE, or N to keep current version : " CONFIRM_UPDATE
        CONFIRM_UPDATE=$(echo "$CONFIRM_UPDATE" | tr -d '\r')
        case "$CONFIRM_UPDATE" in
            [Yy]|[Yy][Ee][Ss])
                ;;
            *)
                echo
                printf "${YELLOW}[INFO] Update skipped. Keeping current version (v%s). Exiting safely.${NC}\n" "$INSTALLED_VER"
                exit 0
                ;;
        esac
        echo
        printf "${WHITE}[PROCESSING] Updating FFmpeg from v%s to v%s ...${NC}\n" "$INSTALLED_VER" "$LATEST_VER"
    fi
else
    echo -e "${GRAY}=======================================================================================================${NC}"
    echo -e "${CYAN}                                FFMPEG STATUS & VERSION REPORT                                        ${NC}"
    echo -e "${GRAY}=======================================================================================================${NC}"
    echo
    printf "${YELLOW}[INFO] FFmpeg Status         : NOT INSTALLED${NC}\n"
    printf "${WHITE}[INFO] Latest Version        : %s${NC}\n" "$LATEST_VER"
    printf "${YELLOW}[INFO] Environment PATH      : NOT CONFIGURED${NC}\n"
    echo
    read -r -p "FFmpeg Full Build will be installed. Type Y to INSTALL, or N to cancel : " CONFIRM_INSTALL
    CONFIRM_INSTALL=$(echo "$CONFIRM_INSTALL" | tr -d '\r')
    case "$CONFIRM_INSTALL" in
        [Yy]|[Yy][Ee][Ss])
            ;;
        *)
            echo
            printf "${YELLOW}[CANCELLED] Installation cancelled. Exiting safely.${NC}\n"
            exit 0
            ;;
    esac
    echo
    printf "${WHITE}[PROCESSING] Installing FFmpeg Full Build (v%s) ...${NC}\n" "$LATEST_VER"
fi

BREW_CMD=$(command -v brew 2>/dev/null)

if [ -n "$BREW_CMD" ]; then
    printf "${WHITE}[PROCESSING] Found Homebrew. Running: brew install ffmpeg / brew upgrade ffmpeg ...${NC}\n"
    brew install ffmpeg 2>/dev/null || brew upgrade ffmpeg
    PATH_ACTION="ALREADY SET via Homebrew"
else
    printf "${WHITE}[PROCESSING] Downloading static FFmpeg Full Build binaries ...${NC}\n"
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
echo -e "${GREEN}=======================================================================================================${NC}"
printf "${GREEN}[SUCCESS] FFmpeg Full Build installation / update & PATH configuration complete!${NC}\n"
printf "${GREEN} [Environment PATH] : %s${NC}\n" "$PATH_ACTION"
if [ -n "$FINAL_FF" ]; then printf "${WHITE} [ffmpeg]           : %s${NC}\n" "$FINAL_FF"; fi
if [ -n "$FINAL_FP" ]; then printf "${WHITE} [ffprobe]          : %s${NC}\n" "$FINAL_FP"; fi
if [ -n "$FINAL_FY" ]; then printf "${WHITE} [ffplay]           : %s${NC}\n" "$FINAL_FY"; fi
echo -e "${GREEN}=======================================================================================================${NC}"
echo "[FINISHED] Script execution finished. GitHub: https://github.com/Biraj2004"
echo "======================================================================================================="
echo
