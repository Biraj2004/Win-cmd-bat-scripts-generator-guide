#!/bin/bash
# =======================================================================================================
# GitHub      : https://github.com/Biraj2004
# Developer   : Biraj
# Description : Automates discovery, version resolution, and downloading of the complete 14-application
#                ArtCraft creative suite (PhotoCraft, VectorCraft, FilmCraft, ArtCraft Hub, etc.)
#                from https://getartcraft.com and https://github.com/storytold for macOS and Windows.
#                - Downloads latest standalone installers: macOS (.dmg) and Windows x64 (.msi).
#                - Automatically creates dedicated parent and subfolders at script execution location.
#                - Discovers true real-time latest releases dynamically without GitHub API rate limits.
#                - Mentions and displays latest version numbers, categories, and installer filenames.
#                - Gracefully handles already downloaded files (skips re-downloading up-to-date versions).
#                - Gracefully archives older superseded installer versions into _Archive_Old_Versions.
#                - Writes a comprehensive version manifest inventory file.
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
echo -e "${CYAN}                ARTCRAFT CREATIVE SUITE DOWNLOADER & VERSION MANAGER (macOS)${NC}"
echo -e "${GRAY}                Developed by : Biraj${NC}"
echo -e "${GRAY}                GitHub       : https://github.com/Biraj2004${NC}"
echo -e "${GRAY}=======================================================================================================${NC}"
echo
echo -e "${WHITE}[INFO] Working Folder   : $ROOT_DIR${NC}"
echo -e "${WHITE}[INFO] Official Source  : https://getartcraft.com/apps${NC}"
echo -e "${WHITE}[INFO] GitHub Org       : https://github.com/storytold${NC}"
echo -e "${WHITE}[INFO] Supported Targets: macOS Universal (.dmg) & Windows x64 (.msi)${NC}"
echo -e "${WHITE}[INFO] Apps Discovered  : 14 Standalone Creative Applications${NC}"
echo -e "${WHITE}[INFO] Safety & Storage : Atomic downloads (.tmp -> final), skips up-to-date, archives older versions${NC}"
echo

# --- PLATFORM SELECTION ---
echo -e "${YELLOW}=======================================================================================================${NC}"
echo -e "${YELLOW} SELECT TARGET PLATFORM TO DOWNLOAD:${NC}"
echo -e "${YELLOW}=======================================================================================================${NC}"
echo -e "${WHITE}  [1] Both macOS (Universal DMG) and Windows (x64 MSI) [Recommended]${NC}"
echo -e "${WHITE}  [2] macOS Only (macOS Universal Standalone DMG installers)${NC}"
echo -e "${WHITE}  [3] Windows Only (Win x64 Standalone MSI installers)${NC}"
echo
read -r -p "Enter choice [1, 2, or 3] (Default: 1): " PLATFORM_CHOICE
PLATFORM_CHOICE=$(echo "$PLATFORM_CHOICE" | tr -d '\r')

DOWNLOAD_MAC=true
DOWNLOAD_WIN=true
SCOPE_DESC="Both macOS (Universal DMG) and Windows (x64 MSI)"

if [ "$PLATFORM_CHOICE" = "2" ]; then
    DOWNLOAD_WIN=false
    SCOPE_DESC="macOS Universal Standalone DMG Only"
elif [ "$PLATFORM_CHOICE" = "3" ]; then
    DOWNLOAD_MAC=false
    SCOPE_DESC="Windows x64 Standalone MSI Only"
fi

PARENT_DIR="$ROOT_DIR/ArtCraft_Suite_Installers"
MACOS_DIR="$PARENT_DIR/macOS_Universal_DMG"
WINDOWS_DIR="$PARENT_DIR/Windows_x64_MSI"

echo
echo -e "${CYAN}=======================================================================================================${NC}"
echo -e "${WHITE}[PLAN] Target Parent Folder : $PARENT_DIR${NC}"
if [ "$DOWNLOAD_MAC" = true ]; then echo -e "${WHITE}[PLAN] macOS Subfolder      : $MACOS_DIR${NC}"; fi
if [ "$DOWNLOAD_WIN" = true ]; then echo -e "${WHITE}[PLAN] Windows Subfolder    : $WINDOWS_DIR${NC}"; fi
echo -e "${WHITE}[PLAN] Download Scope       : $SCOPE_DESC${NC}"
echo -e "${WHITE}[PLAN] Total Applications   : 14 Standalone Creative Tools${NC}"
echo -e "${CYAN}=======================================================================================================${NC}"
echo

# --- SAFETY CONFIRMATION GATE ---
read -r -p "Type Y and press Enter to begin checking and downloading, or N to cancel : " CONFIRM
CONFIRM=$(echo "$CONFIRM" | tr -d '\r')

case "$CONFIRM" in
    [Yy]|[Yy][Ee][Ss])
        ;;
    *)
        echo
        echo -e "${YELLOW}[CANCELLED] Operation cancelled by user. No folders were created and no files were downloaded.${NC}"
        exit 0
        ;;
esac

mkdir -p "$PARENT_DIR"
if [ "$DOWNLOAD_MAC" = true ]; then mkdir -p "$MACOS_DIR"; fi
if [ "$DOWNLOAD_WIN" = true ]; then mkdir -p "$WINDOWS_DIR"; fi

# --- APPS REGISTRY ---
# id | name | repo | category | fallback_tag | msi_regex | dmg_regex | fallback_msi | fallback_dmg
APPS=(
    "artcraft|ArtCraft Hub|artcraft|Hub & Creative Engine|artcraft-v0.41.0|ArtCraft_.*x64.*\.msi$|ArtCraft_.*\.dmg$|https://github.com/storytold/artcraft/releases/download/artcraft-v0.41.0/ArtCraft_0.41.0_x64_en-US.msi|https://github.com/storytold/artcraft/releases/download/artcraft-v0.41.0/ArtCraft_0.41.0_universal.dmg"
    "photocraft|PhotoCraft|photocraft|Photo Retouching & Editing|v0.7.0|photocraft-.*windows-x64\.msi$|photocraft-.*macos-universal\.dmg$|https://github.com/storytold/photocraft/releases/download/v0.7.0/photocraft-0.7.0-windows-x64.msi|https://github.com/storytold/photocraft/releases/download/v0.7.0/photocraft-0.7.0-macos-universal.dmg"
    "vectorcraft|VectorCraft|vectorcraft|Vector Art & Illustration|v0.9.0|vectorcraft-.*windows-x64\.msi$|vectorcraft-.*macos-universal\.dmg$|https://github.com/storytold/vectorcraft/releases/download/v0.9.0/vectorcraft-0.9.0-windows-x64.msi|https://github.com/storytold/vectorcraft/releases/download/v0.9.0/vectorcraft-0.9.0-macos-universal.dmg"
    "lightcraft|LightCraft|lightcraft|RAW & Photo Processing|v0.6.0|lightcraft-.*windows-x64\.msi$|lightcraft-.*macos-universal\.dmg$|https://github.com/storytold/lightcraft/releases/download/v0.6.0/lightcraft-0.6.0-windows-x64.msi|https://github.com/storytold/lightcraft/releases/download/v0.6.0/lightcraft-0.6.0-macos-universal.dmg"
    "filmcraft|FilmCraft|filmcraft|Nonlinear Video Editing|v0.6.0|filmcraft-.*windows-x64\.msi$|filmcraft-.*macos-universal\.dmg$|https://github.com/storytold/filmcraft/releases/download/v0.6.0/filmcraft-0.6.0-windows-x64.msi|https://github.com/storytold/filmcraft/releases/download/v0.6.0/filmcraft-0.6.0-macos-universal.dmg"
    "pdfcraft|PdfCraft|pdfcraft|PDF Reader & Editor|v0.6.0|pdfcraft-.*windows-x64\.msi$|pdfcraft-.*macos-universal\.dmg$|https://github.com/storytold/pdfcraft/releases/download/v0.6.0/pdfcraft-0.6.0-windows-x64.msi|https://github.com/storytold/pdfcraft/releases/download/v0.6.0/pdfcraft-0.6.0-macos-universal.dmg"
    "effectcraft|EffectCraft|effectcraft|Motion Graphics & VFX|v0.8.0|effectcraft-.*windows-x64\.msi$|effectcraft-.*macos-universal\.dmg$|https://github.com/storytold/effectcraft/releases/download/v0.8.0/effectcraft-0.8.0-windows-x64.msi|https://github.com/storytold/effectcraft/releases/download/v0.8.0/effectcraft-0.8.0-macos-universal.dmg"
    "designcraft|DesignCraft|designcraft|Page Layout & Publishing|v0.6.0|designcraft-.*windows-x64\.msi$|designcraft-.*macos-universal\.dmg$|https://github.com/storytold/designcraft/releases/download/v0.6.0/designcraft-0.6.0-windows-x64.msi|https://github.com/storytold/designcraft/releases/download/v0.6.0/designcraft-0.6.0-macos-universal.dmg"
    "wordcraft|WordCraft|wordcraft|Document & Word Processing|v0.5.0|wordcraft-.*windows-x64\.msi$|wordcraft-.*macos-universal\.dmg$|https://github.com/storytold/wordcraft/releases/download/v0.5.0/wordcraft-0.5.0-windows-x64.msi|https://github.com/storytold/wordcraft/releases/download/v0.5.0/wordcraft-0.5.0-macos-universal.dmg"
    "gridcraft|GridCraft|gridcraft|Spreadsheet & Modeling|v0.5.0|gridcraft-.*windows-x64\.msi$|gridcraft-.*macos-universal\.dmg$|https://github.com/storytold/gridcraft/releases/download/v0.5.0/gridcraft-0.5.0-windows-x64.msi|https://github.com/storytold/gridcraft/releases/download/v0.5.0/gridcraft-0.5.0-macos-universal.dmg"
    "cadcraft|CADCraft|cadcraft|2D/3D CAD & Drafting|v0.5.0|cadcraft-.*windows-x64\.msi$|cadcraft-.*macos-universal\.dmg$|https://github.com/storytold/cadcraft/releases/download/v0.5.0/cadcraft-0.5.0-windows-x64.msi|https://github.com/storytold/cadcraft/releases/download/v0.5.0/cadcraft-0.5.0-macos-universal.dmg"
    "deckcraft|DeckCraft|deckcraft|Presentations & Slides|v0.5.0|deckcraft-.*windows-x64\.msi$|deckcraft-.*macos-universal\.dmg$|https://github.com/storytold/deckcraft/releases/download/v0.5.0/deckcraft-0.5.0-windows-x64.msi|https://github.com/storytold/deckcraft/releases/download/v0.5.0/deckcraft-0.5.0-macos-universal.dmg"
    "soundcraft|SoundCraft|soundcraft|Audio Editing & DAW|v0.5.0|soundcraft-.*windows-x64\.msi$|soundcraft-.*macos-universal\.dmg$|https://github.com/storytold/soundcraft/releases/download/v0.5.0/soundcraft-0.5.0-windows-x64.msi|https://github.com/storytold/soundcraft/releases/download/v0.5.0/soundcraft-0.5.0-macos-universal.dmg"
    "craft-launcher|ArtCraft Launcher|craft-launcher|App Hub & Version Manager|v0.2.1|artcraft-launcher-.*windows-x64\.msi$|artcraft-launcher-.*macos-universal\.dmg$|https://github.com/storytold/craft-launcher/releases/download/v0.2.1/artcraft-launcher-0.2.1-windows-x64.msi|https://github.com/storytold/craft-launcher/releases/download/v0.2.1/artcraft-launcher-0.2.1-macos-universal.dmg"
)

echo -e "${GRAY}=======================================================================================================${NC}"
echo -e "${CYAN}  DISCOVERING LATEST VERSIONS ACROSS ALL 14 ARTCRAFT APPS${NC}"
echo -e "${GRAY}=======================================================================================================${NC}"
echo -e "${WHITE}[PROCESSING] Querying upstream GitHub releases in real time...${NC}"
echo

# Helper download function
download_asset() {
    local platform="$1"
    local target_dir="$2"
    local app_name="$3"
    local tag="$4"
    local url="$5"
    local file_name="$6"
    local match_regex="$7"

    local final_path="$target_dir/$file_name"
    local archive_dir="$target_dir/_Archive_Old_Versions"
    local temp_path="$final_path.downloading.tmp"

    # Step 1: Detect and archive older versions
    for old_file in "$target_dir"/*; do
        if [ -f "$old_file" ]; then
            base_old="$(basename "$old_file")"
            if [[ "$base_old" =~ $match_regex ]] && [ "$base_old" != "$file_name" ] && [[ "$base_old" != *.downloading.tmp ]]; then
                mkdir -p "$archive_dir"
                mv -f "$old_file" "$archive_dir/$base_old"
                echo -e "  ${YELLOW}[SUPERSEDED] Archived older version: $base_old -> _Archive_Old_Versions/${NC}"
            fi
        fi
    done

    # Step 2: Check if exact target version is already downloaded
    if [ -f "$final_path" ]; then
        local size
        size=$(stat -f%z "$final_path" 2>/dev/null || stat -c%s "$final_path" 2>/dev/null || echo 0)
        if [ "$size" -gt 1048576 ]; then
            local size_mb=$((size / 1048576))
            echo -e "  ${GREEN}[UP-TO-DATE] $file_name (~${size_mb} MB) is already present and latest. Skipping.${NC}"
            return 2 # Up to date code
        fi
    fi

    # Step 3: Atomic Download
    rm -f "$temp_path"
    echo -e "  ${WHITE}[DOWNLOADING] $file_name from upstream GitHub...${NC}"

    if curl -fL --progress-bar --create-dirs -o "$temp_path" "$url"; then
        local downloaded_size
        downloaded_size=$(stat -f%z "$temp_path" 2>/dev/null || stat -c%s "$temp_path" 2>/dev/null || echo 0)
        if [ "$downloaded_size" -gt 1048576 ]; then
            mv -f "$temp_path" "$final_path"
            local mb=$((downloaded_size / 1048576))
            echo -e "  ${GREEN}[SUCCESS] Downloaded: $file_name (~${mb} MB)${NC}"
            return 0
        fi
    fi

    rm -f "$temp_path"
    echo -e "  ${RED}[ERROR] Failed to download $file_name from $url${NC}"
    return 1
}

TOTAL_ATTEMPTED=0
NEW_DOWNLOADS=0
ALREADY_UP_TO_DATE=0
FAILURES=0

MANIFEST_PATH="$PARENT_DIR/ArtCraft_Suite_Manifest.txt"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

cat <<EOF > "$MANIFEST_PATH"
=======================================================================================================
ARTCRAFT CREATIVE SUITE - INSTALLER INVENTORY & VERSION MANIFEST (macOS)
Generated on : $TIMESTAMP
Managed by   : macOS_Download_ArtCraft_Suite_Apps.sh (Biraj2004)
Official Hub : https://getartcraft.com/apps
GitHub Org   : https://github.com/storytold
=======================================================================================================

-------------------------------------------------------------------------------------------------------
PLATFORM          | APP NAME            | VERSION TAG     | INSTALLER FILENAME                     | STATUS
-------------------------------------------------------------------------------------------------------
EOF

idx=1
for entry in "${APPS[@]}"; do
    IFS='|' read -r id name repo category fallback_tag msi_regex dmg_regex fallback_msi fallback_dmg <<< "$entry"

    # Query redirect
    location=$(curl -sI "https://github.com/storytold/$repo/releases/latest" 2>/dev/null | grep -i '^location:' | head -n 1 | tr -d '\r')
    resolved_tag=""
    if [[ "$location" =~ releases/tag/(.+)$ ]]; then
        resolved_tag="${BASH_REMATCH[1]}"
    fi

    if [ -z "$resolved_tag" ]; then
        resolved_tag="$fallback_tag"
    fi

    # Scrape assets
    msi_url=""
    dmg_url=""
    assets_html=$(curl -sL "https://github.com/storytold/$repo/releases/expanded_assets/$resolved_tag" 2>/dev/null)
    if [ -n "$assets_html" ]; then
        msi_path=$(echo "$assets_html" | grep -oE "/storytold/$repo/releases/download/[^\"]+" | grep -E '\.msi$' | grep -E 'x64' | head -n 1)
        dmg_path=$(echo "$assets_html" | grep -oE "/storytold/$repo/releases/download/[^\"]+" | grep -E '\.dmg$' | head -n 1)
        if [ -n "$msi_path" ]; then msi_url="https://github.com$msi_path"; fi
        if [ -n "$dmg_path" ]; then dmg_url="https://github.com$dmg_path"; fi
    fi

    if [ -z "$msi_url" ]; then msi_url="$fallback_msi"; fi
    if [ -z "$dmg_url" ]; then dmg_url="$fallback_dmg"; fi

    msi_file="$(basename "$msi_url")"
    dmg_file="$(basename "$dmg_url")"

    echo
    echo -e "${GRAY}=======================================================================================================${NC}"
    echo -e "${CYAN}  [$idx / 14] $(echo "$name" | tr '[:lower:]' '[:upper:]') ($resolved_tag) - $category${NC}"
    echo -e "${GRAY}=======================================================================================================${NC}"

    if [ "$DOWNLOAD_MAC" = true ]; then
        TOTAL_ATTEMPTED=$((TOTAL_ATTEMPTED + 1))
        echo -e "${CYAN}[macOS UNIVERSAL DMG] Checking: $dmg_file${NC}"
        download_asset "macOS" "$MACOS_DIR" "$name" "$resolved_tag" "$dmg_url" "$dmg_file" "$dmg_regex"
        res_code=$?
        if [ $res_code -eq 0 ]; then
            NEW_DOWNLOADS=$((NEW_DOWNLOADS + 1))
            status_str="DOWNLOADED"
        elif [ $res_code -eq 2 ]; then
            ALREADY_UP_TO_DATE=$((ALREADY_UP_TO_DATE + 1))
            status_str="UP_TO_DATE"
        else
            FAILURES=$((FAILURES + 1))
            status_str="FAILED"
        fi
        printf "%-17s | %-19s | %-15s | %-38s | %s\n" "macOS Universal" "$name" "$resolved_tag" "$dmg_file" "$status_str" >> "$MANIFEST_PATH"
    fi

    if [ "$DOWNLOAD_WIN" = true ]; then
        TOTAL_ATTEMPTED=$((TOTAL_ATTEMPTED + 1))
        echo -e "${CYAN}[WINDOWS x64 MSI] Checking: $msi_file${NC}"
        download_asset "Windows" "$WINDOWS_DIR" "$name" "$resolved_tag" "$msi_url" "$msi_file" "$msi_regex"
        res_code=$?
        if [ $res_code -eq 0 ]; then
            NEW_DOWNLOADS=$((NEW_DOWNLOADS + 1))
            status_str="DOWNLOADED"
        elif [ $res_code -eq 2 ]; then
            ALREADY_UP_TO_DATE=$((ALREADY_UP_TO_DATE + 1))
            status_str="UP_TO_DATE"
        else
            FAILURES=$((FAILURES + 1))
            status_str="FAILED"
        fi
        printf "%-17s | %-19s | %-15s | %-38s | %s\n" "Windows x64" "$name" "$resolved_tag" "$msi_file" "$status_str" >> "$MANIFEST_PATH"
    fi

    idx=$((idx + 1))
done

cat <<EOF >> "$MANIFEST_PATH"

=======================================================================================================
DIRECTORY LOCATIONS:
Parent Folder  : $PARENT_DIR
Windows MSI    : $WINDOWS_DIR
macOS DMG      : $MACOS_DIR
Archive Folder : _Archive_Old_Versions (Inside respective platform folders when older files are replaced)
=======================================================================================================
EOF

echo
echo -e "${GRAY}=======================================================================================================${NC}"
echo -e "${CYAN}  EXECUTION SUMMARY & INVENTORY REPORT${NC}"
echo -e "${GRAY}=======================================================================================================${NC}"
echo -e "${WHITE}[SUMMARY] Target Folder        : $PARENT_DIR${NC}"
echo -e "${WHITE}[SUMMARY] Total Files Handled  : $TOTAL_ATTEMPTED${NC}"
echo -e "${GREEN}[SUMMARY] Newly Downloaded     : $NEW_DOWNLOADS${NC}"
echo -e "${CYAN}[SUMMARY] Already Up To Date   : $ALREADY_UP_TO_DATE${NC}"
echo -e "${YELLOW}[SUMMARY] Version Manifest Log : $MANIFEST_PATH${NC}"
echo
if [ "$FAILURES" -eq 0 ]; then
    echo -e "${GREEN}=======================================================================================================${NC}"
    echo -e "${GREEN}[SUCCESS] All ArtCraft apps verified and up-to-date in their dedicated folders!${NC}"
    echo -e "${GREEN}=======================================================================================================${NC}"
else
    echo -e "${YELLOW}=======================================================================================================${NC}"
    echo -e "${YELLOW}[NOTE] Completed with $FAILURES error(s). Please verify network connection and retry.${NC}"
    echo -e "${YELLOW}=======================================================================================================${NC}"
fi
echo
exit 0
