#!/bin/bash

# Exit on error, but allow for error handling
set -o errexit
set -o pipefail
set -o nounset

# Initialize dry-run flag and counters
DRY_RUN=false
TOTAL_OPERATIONS=0
SUCCESSFUL_OPERATIONS=0
FAILED_OPERATIONS=0
SKIPPED_OPERATIONS=0

# Cleanup function for temporary files
cleanup() {
    local exit_code=$?
    # Remove any leftover test files
    rm -f /tmp/.update_test_* 2>/dev/null
    exit $exit_code
}

# Register cleanup function
trap cleanup EXIT INT TERM

# Parse command line options
TEMP=$(getopt -o '' --long dry-run -n "$(basename "$0")" -- "$@")

if [ $? -ne 0 ]; then
    echo "Error: Invalid option"
    exit 1
fi

# Note the quotes around "$TEMP": they are essential!
eval set -- "$TEMP"

# Parse options
while true; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            echo "[DRY RUN] This is a dry run. No changes will be made."
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Internal error!"
            exit 1
            ;;
    esac
done

# Source the configuration file
CONFIG_FILE="$(dirname "$(dirname "$0")")/config.sh"
if [ ! -f "$CONFIG_FILE" ] || [ ! -r "$CONFIG_FILE" ]; then
    echo "Error: Config file not found or not readable at $CONFIG_FILE"
    exit 1
fi
source "$CONFIG_FILE"

echo "=================================================="
echo "              Updating System"
echo "=================================================="

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to safely run commands with sudo
safe_sudo() {
    local description="$1"
    shift
    local cmd=("$@")
    
    # Build command with flags
    local full_cmd=()
    if [ "${UPDATE_ASSUME_YES:-true}" = true ]; then
        # Add -y flag for apt commands
        if [[ "${cmd[0]}" == "apt"* ]]; then
            full_cmd=("${cmd[@]}" "-y")
        else
            full_cmd=("${cmd[@]}")
        fi
    else
        full_cmd=("${cmd[@]}")
    fi
    
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would run: sudo ${full_cmd[*]}"
        return 0
    fi
    
    echo "Running: $description"
    if [ "${UPDATE_VERBOSE:-false}" = true ]; then
        echo "Command: sudo ${full_cmd[*]}"
    fi
    
    if ! sudo "${full_cmd[@]}"; then
        echo "Error: Failed to execute: $description"
        return 1
    fi
    return 0
}

# Function to safely run commands without sudo
safe_run() {
    local description="$1"
    shift
    local cmd=("$@")
    
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would run: ${cmd[*]}"
        return 0
    fi
    
    echo "Running: $description"
    if [ "${UPDATE_VERBOSE:-false}" = true ]; then
        echo "Command: ${cmd[*]}"
    fi
    
    if ! "${cmd[@]}"; then
        echo "Error: Failed to execute: $description"
        return 1
    fi
    return 0
}

# Function to handle operation with error policy
run_operation() {
    local operation_name="$1"
    local operation_func="$2"
    
    ((TOTAL_OPERATIONS++))
    echo "Starting: $operation_name"
    
    if $operation_func; then
        echo "Completed: $operation_name"
        ((SUCCESSFUL_OPERATIONS++))
        return 0
    else
        echo "Failed: $operation_name"
        ((FAILED_OPERATIONS++))
        
        if [ "${SKIP_UPDATE_ON_ERROR:-false}" = false ]; then
            echo "Stopping due to error in: $operation_name"
            return 1
        else
            echo "Continuing despite error in: $operation_name"
            return 0
        fi
    fi
}

# APT Update Operations
apt_update() {
    if [ "${APT_UPDATE:-true}" = true ]; then
        safe_sudo "Update package lists" apt update
    else
        echo "APT update skipped (disabled in config)"
        return 0
    fi
}

apt_configure_pending() {
    if [ "${APT_CONFIGURE_PENDING:-true}" = true ]; then
        safe_sudo "Configure pending packages" dpkg --configure -a
    else
        echo "Configure pending packages skipped (disabled in config)"
        return 0
    fi
}

apt_fix_broken() {
    if [ "${APT_FIX_BROKEN:-true}" = true ]; then
        safe_sudo "Fix broken dependencies" apt install -f
    else
        echo "Fix broken dependencies skipped (disabled in config)"
        return 0
    fi
}

apt_upgrade() {
    if [ "${APT_UPGRADE:-true}" = true ]; then
        safe_sudo "Upgrade packages" apt upgrade
    else
        echo "APT upgrade skipped (disabled in config)"
        return 0
    fi
}

apt_dist_upgrade() {
    if [ "${APT_DIST_UPGRADE:-true}" = true ]; then
        safe_sudo "Distribution upgrade" apt dist-upgrade
    else
        echo "Distribution upgrade skipped (disabled in config)"
        return 0
    fi
}

apt_autoremove() {
    if [ "${APT_AUTOREMOVE:-true}" = true ]; then
        safe_sudo "Remove unused packages" apt autoremove
    else
        echo "Autoremove skipped (disabled in config)"
        return 0
    fi
}

apt_autoclean() {
    if [ "${APT_AUTOCLEAN:-true}" = true ]; then
        safe_sudo "Clean package cache" apt autoclean
    else
        echo "Autoclean skipped (disabled in config)"
        return 0
    fi
}

# Snap Update Operations
snap_update() {
    if [ "${UPDATE_SNAP_PACKAGES:-true}" = true ]; then
        if command_exists snap; then
            safe_sudo "Update Snap packages" snap refresh
        else
            echo "Snap not available, skipping Snap updates"
            return 0
        fi
    else
        echo "Snap updates skipped (disabled in config)"
        return 0
    fi
}

# Flatpak Update Operations
flatpak_update() {
    if [ "${UPDATE_FLATPAK_PACKAGES:-true}" = true ]; then
        if command_exists flatpak; then
            safe_run "Update Flatpak packages" flatpak update -y
        else
            echo "Flatpak not available, skipping Flatpak updates"
            return 0
        fi
    else
        echo "Flatpak updates skipped (disabled in config)"
        return 0
    fi
}

# GRUB Update Operations
grub_update() {
    if [ "${UPDATE_GRUB_CONFIG:-true}" = true ]; then
        if command_exists update-grub; then
            safe_sudo "Update GRUB configuration" update-grub
        else
            echo "update-grub not available, skipping GRUB update"
            return 0
        fi
    else
        echo "GRUB update skipped (disabled in config)"
        return 0
    fi
}

# Execute APT operations
if [ "${UPDATE_APT_PACKAGES:-true}" = true ]; then
    echo "Performing APT operations..."
    
    run_operation "APT Update" apt_update || exit 1
    run_operation "Configure Pending Packages" apt_configure_pending || exit 1
    run_operation "Fix Broken Dependencies" apt_fix_broken || exit 1
    run_operation "APT Upgrade" apt_upgrade || exit 1
    run_operation "Distribution Upgrade" apt_dist_upgrade || exit 1
    run_operation "Remove Unused Packages" apt_autoremove || exit 1
    run_operation "Clean Package Cache" apt_autoclean || exit 1
else
    echo "APT operations skipped (disabled in config)"
    ((SKIPPED_OPERATIONS++))
fi

# Execute Snap operations
if [ "${UPDATE_SNAP_PACKAGES:-true}" = true ]; then
    echo "Performing Snap operations..."
    run_operation "Snap Update" snap_update || exit 1
else
    echo "Snap operations skipped (disabled in config)"
    ((SKIPPED_OPERATIONS++))
fi

# Execute Flatpak operations
if [ "${UPDATE_FLATPAK_PACKAGES:-true}" = true ]; then
    echo "Performing Flatpak operations..."
    run_operation "Flatpak Update" flatpak_update || exit 1
else
    echo "Flatpak operations skipped (disabled in config)"
    ((SKIPPED_OPERATIONS++))
fi

# Execute GRUB operations
if [ "${UPDATE_GRUB_CONFIG:-true}" = true ]; then
    echo "Performing GRUB operations..."
    run_operation "GRUB Update" grub_update || exit 1
else
    echo "GRUB operations skipped (disabled in config)"
    ((SKIPPED_OPERATIONS++))
fi

echo "=================================================="
if [ "$DRY_RUN" = true ]; then
    echo "   [DRY RUN] System update operations simulated"
else
    echo "      System update operations complete"
fi
echo "=================================================="
echo "Summary:"
echo "  Total operations: $TOTAL_OPERATIONS"
echo "  Successful: $SUCCESSFUL_OPERATIONS"
echo "  Failed: $FAILED_OPERATIONS"
echo "  Skipped: $SKIPPED_OPERATIONS"

if [ "$FAILED_OPERATIONS" -gt 0 ]; then
    echo "  Check the output above for error messages"
    if [ "${SKIP_UPDATE_ON_ERROR:-false}" = false ]; then
        echo "  Some operations may have been stopped due to errors"
        exit 1
    else
        echo "  Operations continued despite errors (SKIP_UPDATE_ON_ERROR=true)"
    fi
fi
echo "==================================================" 