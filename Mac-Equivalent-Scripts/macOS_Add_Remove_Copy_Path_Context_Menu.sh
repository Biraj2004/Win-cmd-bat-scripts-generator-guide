#!/bin/bash
# =======================================================================================================
# GitHub      : https://github.com/Biraj2004
# Developer   : Biraj
# Description : Adds or removes macOS Finder right-click Quick Action Services:
#                1. "Copy File's Path" (on files and folders)
#                2. "Copy Parent Folder's Path" (on files and folders)
#                - Zero console window flicker: runs natively via macOS Services / pbcopy.
#                - Multi-select aware: selecting multiple items copies all paths (one per line).
#                - Parent deduplication: multi-selected files in the same folder yield a clean unique parent.
#                - Clean clipboard payload: no trailing newlines, handles spaces, quotes, and special characters.
#                - Installs into ~/Library/Services as native Automator Quick Action workflows.
#                - Scope: strictly Finder items; excluded from general application background menus.
#                - Includes interactive menu and strict Yes/No Safety Confirmation Gates.
# =======================================================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

DIVIDER_HEAVY="======================================================================================================="
DIVIDER_LIGHT="-------------------------------------------------------------------------------------------------------"

echo "$DIVIDER_HEAVY"
echo "                        COPY PATH CONTEXT MENU MANAGER (ADD / REMOVE)"
echo "                                Developed by : Biraj"
echo "                                GitHub       : https://github.com/Biraj2004"
echo "$DIVIDER_HEAVY"
echo

SERVICES_DIR="$HOME/Library/Services"
WORKFLOW_FILE="$SERVICES_DIR/Copy File's Path.workflow"
WORKFLOW_PARENT="$SERVICES_DIR/Copy Parent Folder's Path.workflow"

IS_INSTALLED=false
if [ -d "$WORKFLOW_FILE" ] && [ -d "$WORKFLOW_PARENT" ]; then
    IS_INSTALLED=true
fi

echo "[INFO] Working Directory : $SCRIPT_DIR"
echo "[INFO] Services Target   : $SERVICES_DIR"
if [ "$IS_INSTALLED" = true ]; then
    echo "[INFO] Current Status    : INSTALLED (Active in Finder Quick Actions / Services)"
else
    echo "[INFO] Current Status    : NOT INSTALLED"
fi
echo "[INFO] Scope             : Finder Files and Folders (com.apple.finder / public.item)"
echo "[INFO] Architecture     : Native macOS Quick Actions (pbcopy, zero flicker, instant)"
echo "[INFO] Multi-Select      : Supported (aggregates all selected files line-by-line)"
echo "[INFO] Formatting        : Clean path string without trailing newlines"
echo

# -----------------------------------------------------------------------------
# Helper: Refresh macOS Services Cache
# -----------------------------------------------------------------------------
flush_services_cache() {
    if [ -x "/System/Library/CoreServices/pbs" ]; then
        /System/Library/CoreServices/pbs -flush 2>/dev/null || true
    fi
    touch "$SERVICES_DIR" 2>/dev/null || true
    echo "[INFO] macOS Finder services cache refreshed successfully."
}

# -----------------------------------------------------------------------------
# Helper: Create Automator Quick Action Workflow Bundle
# -----------------------------------------------------------------------------
create_workflow_bundle() {
    local workflow_path="$1"
    local menu_title="$2"
    local shell_script="$3"

    mkdir -p "$workflow_path/Contents" || return 1

    # Write Contents/Info.plist
    cat << EOF > "$workflow_path/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>NSServices</key>
	<array>
		<dict>
			<key>NSBackgroundColorName</key>
			<string>background</string>
			<key>NSBackgroundStrokeColorName</key>
			<string>line</string>
			<key>NSMenuItem</key>
			<dict>
				<key>default</key>
				<string>${menu_title}</string>
			</dict>
			<key>NSMessage</key>
			<string>runWorkflowAsService</string>
			<key>NSRequiredContext</key>
			<dict>
				<key>NSApplicationIdentifier</key>
				<string>com.apple.finder</string>
			</dict>
			<key>NSSendFileTypes</key>
			<array>
				<string>public.item</string>
			</array>
		</dict>
	</array>
</dict>
</plist>
EOF

    # Write Contents/document.wflow
    cat << EOF > "$workflow_path/Contents/document.wflow"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>AMApplicationBuild</key>
	<string>523</string>
	<key>AMApplicationVersion</key>
	<string>2.10</string>
	<key>AMDocumentVersion</key>
	<string>2</string>
	<key>actions</key>
	<array>
		<dict>
			<key>action</key>
			<dict>
				<key>AMAccepts</key>
				<dict>
					<key>Container</key>
					<string>List</string>
					<key>Optional</key>
					<true/>
					<key>Types</key>
					<array>
						<string>com.apple.cocoa.path</string>
					</array>
				</dict>
				<key>AMActionVersion</key>
				<string>2.0.3</string>
				<key>AMParameterProperties</key>
				<dict>
					<key>COMMAND_STRING</key>
					<dict/>
					<key>CheckedForUserDefaultShell</key>
					<dict/>
					<key>inputMethod</key>
					<dict/>
					<key>shell</key>
					<dict/>
					<key>source</key>
					<dict/>
				</dict>
				<key>AMProvides</key>
				<dict>
					<key>Container</key>
					<string>List</string>
					<key>Types</key>
					<array>
						<string>com.apple.cocoa.path</string>
					</array>
				</dict>
				<key>ActionBundlePath</key>
				<string>/System/Library/Automator/Run Shell Script.action</string>
				<key>ActionName</key>
				<string>Run Shell Script</string>
				<key>ActionParameters</key>
				<dict>
					<key>COMMAND_STRING</key>
					<string>${shell_script}</string>
					<key>CheckedForUserDefaultShell</key>
					<true/>
					<key>inputMethod</key>
					<integer>1</integer>
					<key>shell</key>
					<string>/bin/bash</string>
					<key>source</key>
					<string></string>
				</dict>
				<key>BundleIdentifier</key>
				<string>com.apple.RunShellScript</string>
				<key>CFBundleVersion</key>
				<string>2.0.3</string>
				<key>Class Name</key>
				<string>RunShellScriptAction</string>
				<key>InputUUID</key>
				<string>4C5B97A1-1376-4C55-9B2F-9D45E2063812</string>
				<key>Keywords</key>
				<array>
					<string>Shell</string>
					<string>Script</string>
					<string>Command</string>
					<string>Run</string>
					<string>Unix</string>
				</array>
				<key>OutputUUID</key>
				<string>8F3952D8-7248-4B2E-8902-861A7C201C74</string>
				<key>UUID</key>
				<string>E73A68F3-7C21-4F90-8C83-05B3A1C6D2E8</string>
			</dict>
		</dict>
	</array>
	<key>connectors</key>
	<dict/>
	<key>workflowMetaData</key>
	<dict>
		<key>workflowTypeIdentifier</key>
		<string>com.apple.Automator.servicesMenu</string>
	</dict>
</dict>
</plist>
EOF
}

# -----------------------------------------------------------------------------
# Action: Install Quick Actions
# -----------------------------------------------------------------------------
install_quick_actions() {
    echo "$DIVIDER_LIGHT"
    echo "                               INSTALLING QUICK ACTION SERVICES"
    echo "$DIVIDER_LIGHT"
    echo

    mkdir -p "$SERVICES_DIR"

    # Shell payload for Copy File's Path
    SCRIPT_COPY_PATH='out=""
for f in "$@"; do
    clean="${f%/}"
    [ -z "$clean" ] &amp;&amp; clean="/"
    if [ -z "$out" ]; then
        out="$clean"
    else
        out="$out
$clean"
    fi
done
printf "%s" "$out" | pbcopy'

    # Shell payload for Copy Parent Folder's Path
    SCRIPT_COPY_PARENT='out=""
for f in "$@"; do
    clean="${f%/}"
    parent="$(dirname "$clean")"
    if [ -z "$out" ]; then
        out="$parent"
    else
        if ! printf "%s\n" "$out" | grep -Fxq "$parent"; then
            out="$out
$parent"
        fi
    fi
done
printf "%s" "$out" | pbcopy'

    echo "[PROCESSING] Installing \"Copy File'\''s Path\" Quick Action..."
    create_workflow_bundle "$WORKFLOW_FILE" "Copy File's Path" "$SCRIPT_COPY_PATH"
    echo "  [SET] $WORKFLOW_FILE"

    echo
    echo "[PROCESSING] Installing \"Copy Parent Folder'\''s Path\" Quick Action..."
    create_workflow_bundle "$WORKFLOW_PARENT" "Copy Parent Folder's Path" "$SCRIPT_COPY_PARENT"
    echo "  [SET] $WORKFLOW_PARENT"

    echo
    flush_services_cache

    echo
    echo "$DIVIDER_HEAVY"
    echo "  [SUCCESS] All Copy Path Quick Actions have been successfully ADDED to macOS Finder!"
    echo "$DIVIDER_HEAVY"
    echo "  - Right-click any file or folder in Finder -> Quick Actions / Services"
    echo "  - Options available: \"Copy File's Path\" and \"Copy Parent Folder's Path\""
    echo "  - Multi-select aware: aggregates multiple selections cleanly onto separate lines"
    echo "  - Clean payload: copied directly to system clipboard via pbcopy without trailing newlines"
}

# -----------------------------------------------------------------------------
# Action: Remove Quick Actions
# -----------------------------------------------------------------------------
remove_quick_actions() {
    echo "$DIVIDER_LIGHT"
    echo "                               REMOVING QUICK ACTION SERVICES"
    echo "$DIVIDER_LIGHT"
    echo

    local removed_count=0

    if [ -d "$WORKFLOW_FILE" ]; then
        rm -rf "$WORKFLOW_FILE"
        echo "  [REMOVED] $WORKFLOW_FILE"
        removed_count=$((removed_count + 1))
    else
        echo "  [SKIP] $WORKFLOW_FILE (Not present)"
    fi

    if [ -d "$WORKFLOW_PARENT" ]; then
        rm -rf "$WORKFLOW_PARENT"
        echo "  [REMOVED] $WORKFLOW_PARENT"
        removed_count=$((removed_count + 1))
    else
        echo "  [SKIP] $WORKFLOW_PARENT (Not present)"
    fi

    echo
    flush_services_cache

    echo
    echo "$DIVIDER_HEAVY"
    echo "  [SUCCESS] All Copy Path Quick Actions have been successfully REMOVED from macOS Finder!"
    echo "$DIVIDER_HEAVY"
    echo "  Total Quick Action services removed: $removed_count"
}

# -----------------------------------------------------------------------------
# CLI Parameter Handling or Interactive Menu
# -----------------------------------------------------------------------------
SELECTED_ACTION=""
FORCE_MODE=false

for arg in "$@"; do
    clean_arg=$(echo "$arg" | tr '[:upper:]' '[:lower:]' | tr -d '-/')
    case "$clean_arg" in
        add|install|1)
            SELECTED_ACTION="1"
            ;;
        remove|uninstall|delete|2)
            SELECTED_ACTION="2"
            ;;
        y|yes|force|quiet)
            FORCE_MODE=true
            ;;
    esac
done

if [ -z "$SELECTED_ACTION" ]; then
    echo "Please select an option:"
    echo "  [1] ADD / INSTALL Copy Path Quick Actions (Finder Context Menu)"
    echo "  [2] REMOVE / UNINSTALL Copy Path Quick Actions"
    echo "  [3] Exit"
    echo

    read -r -p "Enter choice (1, 2, or 3): " RAW_CHOICE
    RAW_CHOICE=$(echo "$RAW_CHOICE" | tr -d '\r')
    case "$RAW_CHOICE" in
        1)
            SELECTED_ACTION="1"
            ;;
        2)
            SELECTED_ACTION="2"
            ;;
        *)
            echo
            echo "[INFO] Exiting without making any changes."
            exit 0
            ;;
    esac
fi

# -----------------------------------------------------------------------------
# Safety Confirmation Gate
# -----------------------------------------------------------------------------
echo
if [ "$SELECTED_ACTION" = "1" ]; then
    if [ "$FORCE_MODE" = false ]; then
        echo "$DIVIDER_HEAVY"
        echo "  CONFIRMATION GATE: You are about to ADD \"Copy Path\" Quick Actions to macOS Finder."
        echo "$DIVIDER_HEAVY"
        echo
        read -r -p "Type Y and press Enter to proceed, or N to cancel: " CONFIRM_GATE
        CONFIRM_GATE=$(echo "$CONFIRM_GATE" | tr -d '\r')
        case "$CONFIRM_GATE" in
            [Yy]|[Yy][Ee][Ss])
                ;;
            *)
                echo
                echo "[CANCELLED] Operation cancelled by user. No modifications were made. Exiting safely."
                exit 0
                ;;
        esac
    fi
    echo
    install_quick_actions
elif [ "$SELECTED_ACTION" = "2" ]; then
    if [ "$FORCE_MODE" = false ]; then
        echo "$DIVIDER_HEAVY"
        echo "  CONFIRMATION GATE: You are about to REMOVE \"Copy Path\" Quick Actions from macOS Finder."
        echo "$DIVIDER_HEAVY"
        echo
        read -r -p "Type Y and press Enter to proceed, or N to cancel: " CONFIRM_GATE
        CONFIRM_GATE=$(echo "$CONFIRM_GATE" | tr -d '\r')
        case "$CONFIRM_GATE" in
            [Yy]|[Yy][Ee][Ss])
                ;;
            *)
                echo
                echo "[CANCELLED] Operation cancelled by user. No modifications were made. Exiting safely."
                exit 0
                ;;
        esac
    fi
    echo
    remove_quick_actions
fi
