#!/bin/bash

# Exit on error, but allow for error handling
set -o errexit
set -o pipefail
set -o nounset

# Initialize dry-run flag and counters
DRY_RUN=false
TOTAL_LINKS=0
SUCCESSFUL_LINKS=0
FAILED_LINKS=0

# Cleanup function for temporary files
cleanup() {
    local exit_code=$?
    # Remove any leftover test files
    rm -f /tmp/.write_test_* 2>/dev/null
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

# Validate config
if [ ${#SYMLINK_PATHS[@]} -eq 0 ]; then
    echo "Error: No symlink paths configured in config.sh"
    exit 1
fi

echo "=================================================="
echo "    Replacing Default Directories with Symlinks"
echo "=================================================="

# Function to validate path
validate_path() {
    local path="$1"
    # Check if path starts with / or variable
    if ! echo "$path" | grep -qE '^(/|\$)'; then
        echo "Error: Path must start with / or \$: $path"
        return 1
    fi
    # Check if path contains illegal characters
    if echo "$path" | grep -q '[<>|&;]'; then
        echo "Error: Path contains illegal characters: $path"
        return 1
    fi
    return 0
}

# Function to check if filesystem is read-only
check_filesystem_writable() {
    local path="$1"
    local test_file
    local parent_dir
    
    # Get the parent directory
    parent_dir=$(dirname "$path")
    
    # Create a temporary file to test write permissions
    test_file="/tmp/.write_test_$(date +%s)_$$"
    if ! touch "$test_file" 2>/dev/null; then
        echo "Error: Filesystem is read-only or permission denied at: $parent_dir"
        return 1
    fi
    rm -f "$test_file"
    return 0
}

# Function to safely remove a path
safe_remove() {
    local path="$1"
    
    # Don't remove root or home directory
    if [ "$path" = "/" ] || [ "$path" = "$HOME" ] || [ "$path" = "/home" ]; then
        echo "Error: Refusing to remove protected directory: $path"
        return 1
    fi

    # Don't remove if parent is not writable
    if ! check_filesystem_writable "$path"; then
        return 1
    fi

    # Check if it's a mount point
    if mountpoint -q "$path"; then
        echo "Error: Cannot remove mount point: $path"
        return 1
    fi

    # Remove the path
    if ! rm -rf "$path"; then
        echo "Error: Failed to remove $path"
        return 1
    fi

    return 0
}

# Function to create parent directory
create_parent_dir() {
    local target_path="$1"
    local parent_dir
    parent_dir=$(dirname "$target_path")
    
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would create parent directory: $parent_dir"
        return 0
    fi

    # Check filesystem writeability
    if ! check_filesystem_writable "$parent_dir"; then
        return 1
    fi

    if [ ! -d "$parent_dir" ]; then
        if ! mkdir -p "$parent_dir"; then
            echo "Error: Failed to create parent directory: $parent_dir"
            return 1
        fi
        echo "Created parent directory: $parent_dir"
    fi
    return 0
}

# Loop through the array and replace the original directories with symlinks
for original_path in "${!SYMLINK_PATHS[@]}"; do
    ((TOTAL_LINKS++))
    target_path="${SYMLINK_PATHS[$original_path]}"
    
    # Expand any environment variables in paths
    eval "expanded_original=$original_path"
    eval "expanded_target=$target_path"

    # Validate both paths
    if ! validate_path "$original_path" || ! validate_path "$target_path"; then
        ((FAILED_LINKS++))
        continue
    fi

    echo "Processing: $expanded_original -> $expanded_target"

    # Check if target parent exists and is writable
    target_parent=$(dirname "$expanded_target")
    if [ ! -w "$target_parent" ] && [ "$DRY_RUN" = false ]; then
        echo "Error: No write permission in target parent directory: $target_parent"
        ((FAILED_LINKS++))
        continue
    fi

    # Create parent directory of target if it doesn't exist
    if ! create_parent_dir "$expanded_target"; then
        ((FAILED_LINKS++))
        continue
    fi

    if [ "$DRY_RUN" = true ]; then
        # Check if original path exists
        if [ -e "$expanded_original" ]; then
            echo "[DRY RUN] Would remove: $expanded_original"
        fi
        echo "[DRY RUN] Would create symlink: $expanded_original -> $expanded_target"
        ((SUCCESSFUL_LINKS++))
        continue
    fi

    # Check if target directory exists or can be created
    if [ ! -e "$expanded_target" ]; then
        echo "Creating target directory: $expanded_target"
        if ! mkdir -p "$expanded_target"; then
            echo "Error: Failed to create target directory: $expanded_target"
            ((FAILED_LINKS++))
            continue
        fi
    elif [ ! -d "$expanded_target" ]; then
        echo "Error: Target exists but is not a directory: $expanded_target"
        ((FAILED_LINKS++))
        continue
    fi

    # Remove the original directory/file if it exists
    if [ -e "$expanded_original" ] || [ -L "$expanded_original" ]; then
        if [ -L "$expanded_original" ]; then
            echo "Removing existing symlink: $expanded_original"
        else
            echo "Removing existing path: $expanded_original"
        fi
        if ! safe_remove "$expanded_original"; then
            ((FAILED_LINKS++))
            continue
        fi
    fi

    # Create the symlink
    echo "Creating symlink: $expanded_original -> $expanded_target"
    if ! ln -s "$expanded_target" "$expanded_original"; then
        echo "Error: Failed to create symlink from $expanded_original to $expanded_target"
        ((FAILED_LINKS++))
        continue
    fi
    ((SUCCESSFUL_LINKS++))
done

echo "=================================================="
if [ "$DRY_RUN" = true ]; then
    echo "   [DRY RUN] Symlink creation simulated"
else
    echo "   Directory replacement with symlinks complete"
fi
echo "=================================================="
echo "Summary:"
echo "  Total symlinks processed: $TOTAL_LINKS"
echo "  Successful: $SUCCESSFUL_LINKS"
echo "  Failed: $FAILED_LINKS"
if [ "$FAILED_LINKS" -gt 0 ]; then
    echo "  Check the output above for error messages"
    exit 1
fi
echo "==================================================" 