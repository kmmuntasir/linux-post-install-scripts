#!/bin/bash

# Exit on error, but allow for error handling
set -o errexit
set -o pipefail
set -o nounset

# Initialize dry-run flag
DRY_RUN=false

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

# Validate config
if [ ${#MOUNT_DISKS[@]} -eq 0 ]; then
    echo "Error: No mount disks configured in config.sh"
    exit 1
fi

# Validate mount options
if [ -z "${MOUNT_OPTIONS:-}" ]; then
    echo "Warning: MOUNT_OPTIONS not set in config.sh, using default: auto,nosuid,nodev,nofail,x-gvfs-show"
    MOUNT_OPTIONS="auto,nosuid,nodev,nofail,x-gvfs-show"
fi

echo "=================================================="
echo "                 Automount Drives"
echo "=================================================="

# Check for input argument
if [ -z "$1" ]; then
    echo "Usage: $0 [--dry-run] <create|mount>"
    echo "Options:"
    echo "  --dry-run    Show what would happen without making changes"
    exit 1
fi

# Function to validate UUID
validate_uuid() {
    local uuid="$1"
    # Check UUID format (8-4-4-4-12 hexadecimal digits)
    if ! echo "$uuid" | grep -qiE '^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$'; then
        # If not in standard format, check if it's a valid 16-character hex string
        if ! echo "$uuid" | grep -qiE '^[0-9a-f]{16}$'; then
            echo "Error: Invalid UUID format: $uuid"
            echo "UUID should be either 16 hex characters or in format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
            return 1
        fi
    fi
    # Check if UUID exists in system
    if ! ls -l /dev/disk/by-uuid/"$uuid" >/dev/null 2>&1; then
        echo "Error: UUID not found in system: $uuid"
        return 1
    fi
    return 0
}

# Function to validate mount path
validate_mount_path() {
    local path="$1"
    # Check if path starts with / and contains valid characters
    if ! echo "$path" | grep -qE '^/[^/]+'; then
        echo "Error: Invalid mount path format: $path"
        echo "Path must start with / and contain at least one component"
        return 1
    fi
    # Check if path contains illegal characters
    if echo "$path" | grep -q '[<>|&;]'; then
        echo "Error: Mount path contains illegal characters: $path"
        return 1
    fi
    return 0
}

# Create directories based on parameter
if [ "$1" == "create" ]; then
    for mount_path in "${!MOUNT_DISKS[@]}"; do
        # Validate mount path
        if ! validate_mount_path "$mount_path"; then
            continue
        fi
        
        # Check write permission for parent directory
        parent_dir=$(dirname "$mount_path")
        if [ ! -w "$parent_dir" ] && [ "$DRY_RUN" = false ]; then
            echo "Error: No write permission in parent directory: $parent_dir"
            continue
        fi

        # Create directory if it doesn't exist
        if [ "$DRY_RUN" = true ]; then
            echo "[DRY RUN] Would create directory: $mount_path"
        else
            if ! mkdir -p "$mount_path"; then
                echo "Error: Failed to create directory: $mount_path"
                continue
            fi
            echo "Created directory: $mount_path"
        fi
    done
    echo "=================================================="
    if [ "$DRY_RUN" = true ]; then
        echo "          [DRY RUN] Directory creation simulated"
    else
        echo "               Directories created"
    fi
    echo "=================================================="

elif [ "$1" == "mount" ]; then
    # Check if running as root
    if [ "$EUID" -ne 0 ] && [ "$DRY_RUN" = false ]; then
        echo "Error: Mount operation requires root privileges"
        exit 1
    fi

    # Check if fstab is writable
    if [ ! -w "/etc/fstab" ] && [ "$DRY_RUN" = false ]; then
        echo "Error: Cannot write to /etc/fstab"
        exit 1
    fi

    # Create backup of fstab
    BACKUP_FILE="/etc/fstab.backup.$(date +%Y%m%d_%H%M%S)"
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would create fstab backup: $BACKUP_FILE"
    else
        if ! cp /etc/fstab "$BACKUP_FILE"; then
            echo "Error: Failed to create fstab backup"
            exit 1
        fi
        echo "Created fstab backup: $BACKUP_FILE"
    fi

    for mount_path in "${!MOUNT_DISKS[@]}"; do
        # Validate mount path
        if ! validate_mount_path "$mount_path"; then
            continue
        fi

        uuid="${MOUNT_DISKS[$mount_path]}"

        # Validate UUID
        if ! validate_uuid "$uuid"; then
            continue
        fi

        # Prepare the fstab entry
        FSTAB_ENTRY="/dev/disk/by-uuid/$uuid $mount_path ${MOUNT_OPTIONS} 0 0"

        # Add entry to /etc/fstab if it's not already present
        if ! grep -qs "$uuid" /etc/fstab; then
            if [ "$DRY_RUN" = true ]; then
                echo "[DRY RUN] Would add to /etc/fstab: $FSTAB_ENTRY"
            else
                echo "Adding $mount_path to /etc/fstab"
                if ! sed -i "\$ a $FSTAB_ENTRY" /etc/fstab; then
                    echo "Error: Failed to modify fstab"
                    continue
                fi
            fi
        else
            echo "$mount_path is already in /etc/fstab"
        fi

        # Mount the directory
        if mount | grep -q "on $mount_path type"; then
            echo "$mount_path is already mounted"
        else
            if [ "$DRY_RUN" = true ]; then
                echo "[DRY RUN] Would mount: $mount_path"
            else
                echo "Mounting $mount_path"
                if ! mount "$mount_path"; then
                    echo "Error: Failed to mount $mount_path"
                    continue
                fi
            fi
        fi
    done
    
    # Reload systemd
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would reload systemd daemon"
    else
        if ! systemctl daemon-reload; then
            echo "Warning: Failed to reload systemd"
        fi
    fi
    
    echo "=================================================="
    if [ "$DRY_RUN" = true ]; then
        echo "          [DRY RUN] Mount operations simulated"
    else
        echo "               Directories mounted"
    fi
    echo "=================================================="

else
    echo "Error: Invalid parameter. Use 'create' to create directories or 'mount' to mount them."
    echo "Usage: $0 [--dry-run] <create|mount>"
    echo "Options:"
    echo "  --dry-run    Show what would happen without making changes"
    exit 1
fi 