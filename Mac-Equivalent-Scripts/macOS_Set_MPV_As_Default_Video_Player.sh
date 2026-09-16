#!/bin/bash
# =======================================================================================================
# GitHub      : https://github.com/Biraj2004
# Developer   : Biraj
# Description : Configures MPV (io.mpv) as the default application for all supported video-only formats.
#                - Automatically locates MPV across /Applications, ~/Applications, and Homebrew paths.
#                - Identifies application bundle identifier (io.mpv) for macOS LaunchServices.
#                - Configures file associations across 81 video-only extensions using duti.
#                - Safely excludes .ts to prevent hijacking TypeScript source code files.
#                - Automatically verifies if duti is installed and provides installation guidance.
#                - Re-running this script is SAFE: existing associations are verified and skipped idempotently.
# =======================================================================================================

# Move into this script's own folder (mirrors double-click behaviour on Windows)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
ROOT_DIR="$SCRIPT_DIR"

echo "======================================================================================================="
echo "                               SET MPV AS DEFAULT VIDEO PLAYER"
echo "                               Developed by : Biraj"
echo "                               GitHub       : https://github.com/Biraj2004"
echo "======================================================================================================="
echo

# -----------------------------------------------------------------------------
# 1. Locate MPV Executable or Application Bundle on macOS
# -----------------------------------------------------------------------------
MPV_APP=""
BUNDLE_ID="io.mpv"

if [ -n "$1" ]; then
    if [ -d "$1" ]; then
        MPV_APP="$1"
    elif [ -x "$1" ]; then
        MPV_APP="$1"
    fi
fi

if [ -z "$MPV_APP" ]; then
    if [ -d "/Applications/mpv.app" ]; then
        MPV_APP="/Applications/mpv.app"
    elif [ -d "$HOME/Applications/mpv.app" ]; then
        MPV_APP="$HOME/Applications/mpv.app"
    elif command -v mpv >/dev/null 2>&1; then
        MPV_APP="$(command -v mpv)"
    elif [ -x "/opt/homebrew/bin/mpv" ]; then
        MPV_APP="/opt/homebrew/bin/mpv"
    elif [ -x "/usr/local/bin/mpv" ]; then
        MPV_APP="/usr/local/bin/mpv"
    fi
fi

if [ -z "$MPV_APP" ]; then
    echo "[ERROR] MPV was NOT found on this system."
    echo
    echo "        This script requires MPV (mpv.app or mpv binary) to be installed."
    echo "        Recommended setup (via Homebrew):"
    echo "          1. Install Homebrew (if not already installed): https://brew.sh"
    echo "          2. Install MPV:"
    echo "               brew install --cask mpv"
    echo "          3. Run this script again."
    echo
    echo "        Already have mpv somewhere else? Run this script from Terminal as:"
    echo "          ./macOS_Set_MPV_As_Default_Video_Player.sh \"/path/to/mpv.app\""
    echo
    read -n 1 -s -r -p "Press any key to exit..."
    echo
    exit 1
fi

# Query bundle identifier if mpv.app is found
if [ -d "$MPV_APP" ] && [ -f "$MPV_APP/Contents/Info.plist" ]; then
    DETECTED_ID=$(defaults read "$MPV_APP/Contents/Info.plist" CFBundleIdentifier 2>/dev/null)
    if [ -n "$DETECTED_ID" ]; then
        BUNDLE_ID="$DETECTED_ID"
    fi
fi

# -----------------------------------------------------------------------------
# 2. Comprehensive List of MPV-Supported Video-Only Formats (81 Extensions)
# -----------------------------------------------------------------------------
VIDEO_EXTENSIONS=(
    # MPEG-4 & Web Video
    "mp4" "m4v" "mp4v" "mpeg4" "mpg4" "webm"
    # Matroska Video
    "mkv" "mk3d"
    # Apple QuickTime
    "mov" "qt" "hdmov"
    # AVI & DivX / XviD Codecs
    "avi" "vfw" "divx" "xvid" "3iv"
    # MPEG-1 / MPEG-2 Streams
    "mpeg" "mpg" "mpe" "mpeg1" "mpeg2" "m1v" "m2v" "mp2v" "mpv" "mpv2"
    # Transport Streams & High Definition
    "mts" "m2ts" "m2t" "tts" "tsv" "tsa" "trp" "mtv"
    # DVD & HD-DVD Media
    "vob" "vro" "evo" "evob"
    # Camcorder & DV Formats
    "mod" "tod" "dv" "hdv"
    # Flash Video
    "flv" "f4v"
    # Ogg Video
    "ogv" "ogm" "ogx"
    # Windows Media Video
    "wmv" "wm" "asf" "dvr-ms" "dvr" "wtv"
    # 3GPP Mobile Formats
    "3gp" "3gpp" "3g2" "3gp2"
    # RealMedia Formats
    "rm" "rmvb"
    # Raw Video Streams
    "h264" "264" "x264" "avc" "hevc" "h265" "265" "x265" "yuv" "y4m"
    # Broadcast & Professional
    "mxf" "gxf"
    # Specialty, Game & Animation Video Formats
    "flic" "fli" "flc" "nsv" "nut" "bik" "bk2" "amv" "dav" "roq"
)

TOTAL_EXTENSIONS=${#VIDEO_EXTENSIONS[@]}

# -----------------------------------------------------------------------------
# 3. Present [INFO] and [WARNING] Blocks
# -----------------------------------------------------------------------------
echo "[INFO] Working Folder    : $ROOT_DIR"
echo "[INFO] Target App        : MPV ($MPV_APP)"
echo "[INFO] Bundle Identifier : $BUNDLE_ID"
echo "[INFO] Target Categories : Standard Web, Matroska, QuickTime, AVI, MPEG, TS, DVD, Camcorder, Flash, Ogg, WMV, 3GP, RM, Raw"
echo "[INFO] Target Formats    : $TOTAL_EXTENSIONS Video-Only File Extensions"
echo "[INFO] Scope             : Current User LaunchServices & Default Role Handlers"
echo "[INFO] Safety            : Non-destructive association; re-running is 100% idempotent"
echo

echo "======================================================================================================="
echo " WARNING: This will configure MPV ($BUNDLE_ID) as the default handler for $TOTAL_EXTENSIONS video formats."
echo "======================================================================================================="
echo

# -----------------------------------------------------------------------------
# 4. Y/N Safety Gate
# -----------------------------------------------------------------------------
read -r -p "Type Y and press Enter to proceed, or N to cancel : " CONFIRM
CONFIRM=$(echo "$CONFIRM" | tr -d '\r')

case "$CONFIRM" in
    [Yy]|[Yy][Ee][Ss])
        ;;
    *)
        echo
        echo "[CANCELLED] Setup execution cancelled. No associations were modified. Exiting safely."
        exit 0
        ;;
esac

echo
echo "[PROCESSING] Checking prerequisite tools..."
echo "-------------------------------------------------------------------------------------------------------"

# Check for duti (the macOS standard for setting default application associations)
if ! command -v duti >/dev/null 2>&1; then
    echo "[INFO] duti was not found on your system."
    echo "       duti is the standard macOS utility for setting LaunchServices file associations."
    echo
    if command -v brew >/dev/null 2>&1; then
        read -r -p "Would you like to install duti automatically via Homebrew? (Y/N) : " INSTALL_DUTI
        INSTALL_DUTI=$(echo "$INSTALL_DUTI" | tr -d '\r')
        case "$INSTALL_DUTI" in
            [Yy]|[Yy][Ee][Ss])
                echo "[PROCESSING] Installing duti via Homebrew..."
                brew install duti
                ;;
            *)
                echo "[ERROR] duti is required to configure file associations on macOS."
                echo "        Please install it with: brew install duti"
                echo
                read -n 1 -s -r -p "Press any key to exit..."
                echo
                exit 1
                ;;
        esac
    else
        echo "[ERROR] duti is required to configure file associations on macOS."
        echo "        Install Homebrew (https://brew.sh) and run: brew install duti"
        echo
        read -n 1 -s -r -p "Press any key to exit..."
        echo
        exit 1
    fi
fi

if ! command -v duti >/dev/null 2>&1; then
    echo "[ERROR] duti is still not available. Cannot continue."
    read -n 1 -s -r -p "Press any key to exit..."
    echo
    exit 1
fi

echo
echo "[PROCESSING] Configuring video format associations with LaunchServices..."
echo "-------------------------------------------------------------------------------------------------------"

GRAND_SET=0
GRAND_SKIPPED=0
GRAND_ERRORS=0

for ext in "${VIDEO_EXTENSIONS[@]}"; do
    # Check current default handler
    CURRENT_HANDLER=$(duti -x "$ext" 2>/dev/null | head -n 1 | tr -d '\r')
    
    if [ "$CURRENT_HANDLER" = "$BUNDLE_ID" ]; then
        echo "[SKIP]     .$ext (already set to $BUNDLE_ID)"
        GRAND_SKIPPED=$((GRAND_SKIPPED + 1))
        continue
    fi

    # Apply association using duti for all roles (viewer, editor, all)
    if duti -s "$BUNDLE_ID" "$ext" all 2>/tmp/.duti_err.$$; then
        echo "[SET]      .$ext --> $BUNDLE_ID"
        GRAND_SET=$((GRAND_SET + 1))
    else
        err=$(cat /tmp/.duti_err.$$ 2>/dev/null)
        echo "[ERROR]    Could not set association for .$ext -- $err"
        GRAND_ERRORS=$((GRAND_ERRORS + 1))
    fi
    rm -f /tmp/.duti_err.$$
done

echo
echo "-------------------------------------------------------------------------------------------------------"
echo "[SUMMARY] Total Formats : $TOTAL_EXTENSIONS"
echo "[SUMMARY] Configured    : $GRAND_SET"
echo "[SUMMARY] Already OK    : $GRAND_SKIPPED"
echo "[SUMMARY] Errors        : $GRAND_ERRORS"

if [ "$GRAND_ERRORS" -eq 0 ] || [ "$GRAND_SET" -gt 0 ]; then
    echo "[SUCCESS] MPV default video player associations configured successfully!"
else
    echo "[ERROR]   Failed to configure some video format associations. See messages above."
fi

echo "======================================================================================================="
echo "[FINISHED] Script execution finished. GitHub: https://github.com/Biraj2004"
echo "======================================================================================================="
echo
read -n 1 -s -r -p "Press any key to exit..."
echo
exit 0
