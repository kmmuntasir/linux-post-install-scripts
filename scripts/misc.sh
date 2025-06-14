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
    rm -f /tmp/.misc_test_* 2>/dev/null
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
echo "              Configuring System Settings"
echo "=================================================="

# Function to safely run commands with sudo
safe_sudo() {
    local description="$1"
    shift
    local cmd=("$@")
    
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would run: sudo ${cmd[*]}"
        return 0
    fi
    
    echo "Running: $description"
    if ! sudo "${cmd[@]}"; then
        echo "Error: Failed to execute: $description"
        return 1
    fi
    return 0
}

# Function to safely modify files
safe_file_modify() {
    local description="$1"
    local file="$2"
    local backup_suffix="$3"
    shift 3
    local cmd=("$@")
    
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would modify $file: $description"
        return 0
    fi
    
    # Check if file exists
    if [ ! -f "$file" ]; then
        echo "Error: File not found: $file"
        return 1
    fi
    
    # Create backup
    local backup_file="${file}.${backup_suffix}.$(date +%Y%m%d_%H%M%S)"
    if ! sudo cp "$file" "$backup_file"; then
        echo "Error: Failed to create backup of $file"
        return 1
    fi
    echo "Created backup: $backup_file"
    
    # Execute modification
    echo "Modifying: $description"
    if ! sudo "${cmd[@]}"; then
        echo "Error: Failed to modify $file"
        # Restore backup
        sudo cp "$backup_file" "$file"
        echo "Restored backup due to error"
        return 1
    fi
    return 0
}

# Update GRUB timeout
if [ "${UPDATE_GRUB_TIMEOUT:-true}" = true ] && [ "${ENABLE_SYSTEM_MISC:-true}" = true ]; then
    echo "Updating GRUB timeout..."
    ((TOTAL_OPERATIONS++))
    
    if safe_file_modify "Update GRUB timeout to ${GRUB_TIMEOUT:-5}" "/etc/default/grub" "grub_backup" \
        sed -i -e "s/^GRUB_TIMEOUT=[0-9]\\+/GRUB_TIMEOUT=${GRUB_TIMEOUT:-5}/" "/etc/default/grub"; then
        
        # Update GRUB configuration
        if safe_sudo "Update GRUB configuration" update-grub; then
            echo "GRUB timeout updated successfully"
            ((SUCCESSFUL_OPERATIONS++))
        else
            echo "Error: Failed to update GRUB configuration"
            ((FAILED_OPERATIONS++))
        fi
    else
        echo "Error: Failed to update GRUB timeout"
        ((FAILED_OPERATIONS++))
    fi
fi

# Configure lid switch behavior
if [ "${CONFIGURE_LID_SWITCH:-true}" = true ] && [ "${ENABLE_SYSTEM_MISC:-true}" = true ]; then
    echo "Configuring lid switch behavior..."
    ((TOTAL_OPERATIONS++))
    
    local logind_conf="/etc/systemd/logind.conf"
    local lid_action="${LID_SWITCH_ACTION:-lock}"
    local lid_external_action="${LID_SWITCH_EXTERNAL_POWER_ACTION:-lock}"
    
    # Validate lid switch actions
    case "$lid_action" in
        lock|suspend|ignore|poweroff|hibernate) ;;
        *) echo "Warning: Invalid lid switch action '$lid_action', using 'lock'"; lid_action="lock" ;;
    esac
    
    case "$lid_external_action" in
        lock|suspend|ignore|poweroff|hibernate) ;;
        *) echo "Warning: Invalid external power lid action '$lid_external_action', using 'lock'"; lid_external_action="lock" ;;
    esac
    
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would configure lid switch: $lid_action (battery), $lid_external_action (external power)"
        ((SUCCESSFUL_OPERATIONS++))
    else
        # Create backup
        local backup_file="${logind_conf}.lid_backup.$(date +%Y%m%d_%H%M%S)"
        if sudo cp "$logind_conf" "$backup_file"; then
            echo "Created backup: $backup_file"
            
            # Update lid switch settings
            if sudo sed -i.tmp \
                -e "/^HandleLidSwitch=/c\\HandleLidSwitch=$lid_action" \
                -e "/^HandleLidSwitchExternalPower=/c\\HandleLidSwitchExternalPower=$lid_external_action" \
                -e 's/#HandleLidSwitch=/HandleLidSwitch=/g' \
                -e 's/#HandleLidSwitchExternalPower=/HandleLidSwitchExternalPower=/g' \
                "$logind_conf"; then
                
                echo "Lid switch configured: $lid_action (battery), $lid_external_action (external power)"
                ((SUCCESSFUL_OPERATIONS++))
            else
                echo "Error: Failed to configure lid switch"
                ((FAILED_OPERATIONS++))
            fi
        else
            echo "Error: Failed to create backup of $logind_conf"
            ((FAILED_OPERATIONS++))
        fi
    fi
fi

# Copy update script to home directory
if [ "${COPY_UPDATE_SCRIPT:-true}" = true ] && [ "${ENABLE_SYSTEM_MISC:-true}" = true ]; then
    echo "Copying update script to home directory..."
    ((TOTAL_OPERATIONS++))
    
    local source_script="${UPDATE_SCRIPT_SOURCE:-./scripts/update.sh}"
    local target_script="$HOME/update.sh"
    
    # Expand source path
    eval "expanded_source=$source_script"
    
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would copy $expanded_source to $target_script"
        echo "[DRY RUN] Would make $target_script executable"
        ((SUCCESSFUL_OPERATIONS++))
    else
        if [ -f "$expanded_source" ]; then
            if cp "$expanded_source" "$target_script" && chmod +x "$target_script"; then
                echo "Update script copied to $target_script"
                ((SUCCESSFUL_OPERATIONS++))
            else
                echo "Error: Failed to copy or make executable: $target_script"
                ((FAILED_OPERATIONS++))
            fi
        else
            echo "Warning: Source update script not found: $expanded_source"
            ((SKIPPED_OPERATIONS++))
        fi
    fi
fi

echo "=================================================="
if [ "$DRY_RUN" = true ]; then
    echo "   [DRY RUN] System settings configuration simulated"
else
    echo "      System settings configuration complete"
fi
echo "=================================================="
echo "Summary:"
echo "  Total operations: $TOTAL_OPERATIONS"
echo "  Successful: $SUCCESSFUL_OPERATIONS"
echo "  Failed: $FAILED_OPERATIONS"
echo "  Skipped: $SKIPPED_OPERATIONS"

if [ "$FAILED_OPERATIONS" -gt 0 ]; then
    echo "  Check the output above for error messages"
    exit 1
fi
echo "==================================================" 