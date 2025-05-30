#!/bin/bash

# Exit on error, but allow for error handling
set -o errexit
set -o pipefail
set -o nounset

# Initialize dry-run flag and counters
DRY_RUN=false
TOTAL_DIRS=0
SUCCESSFUL_DIRS=0
FAILED_DIRS=0
SKIPPED_DIRS=0

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
if [ ${#COPY_PATHS[@]} -eq 0 ]; then
    echo "Error: No copy paths configured in config.sh"
    exit 1
fi

echo "=================================================="
echo "       Copying Directories to Target Locations"
echo "=================================================="

# Function to validate path
validate_path() {
    local path="$1"
    # Check if path starts with / or ./ or variable
    if ! echo "$path" | grep -qE '^(/|\./|\$)'; then
        echo "Error: Path must start with /, ./ or \$: $path"
        return 1
    fi
    # Check if path contains illegal characters
    if echo "$path" | grep -q '[<>|&;]'; then
        echo "Error: Path contains illegal characters: $path"
        return 1
    fi
    return 0
}

# Function to check if filesystem is writable
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

# Function to safely create directory
safe_mkdir() {
    local dir="$1"
    
    # Don't modify root or home directory
    if [ "$dir" = "/" ] || [ "$dir" = "$HOME" ] || [ "$dir" = "/home" ]; then
        echo "Error: Refusing to modify protected directory: $dir"
        return 1
    fi

    # Don't create if parent is not writable
    if ! check_filesystem_writable "$dir"; then
        return 1
    fi

    # Create the directory
    if ! mkdir -p "$dir"; then
        echo "Error: Failed to create directory: $dir"
        return 1
    fi

    return 0
}

# Loop through the array and copy each source directory to the target location
for source_path in "${!COPY_PATHS[@]}"; do
    ((TOTAL_DIRS++))
    target_path="${COPY_PATHS[$source_path]}"
    
    # Expand any environment variables in paths
    eval "expanded_source=$source_path"
    eval "expanded_target=$target_path"

    # Validate both paths
    if ! validate_path "$source_path" || ! validate_path "$target_path"; then
        ((FAILED_DIRS++))
        continue
    fi

    echo "Processing: $expanded_source -> $expanded_target"

    # Check if source directory exists
    if [ ! -d "$expanded_source" ]; then
        echo "Source directory does not exist: $expanded_source"
        ((SKIPPED_DIRS++))
        continue
    fi

    # Check if target parent exists and is writable
    target_parent=$(dirname "$expanded_target")
    if [ ! -w "$target_parent" ] && [ "$DRY_RUN" = false ]; then
        echo "Error: No write permission in target parent directory: $target_parent"
        ((FAILED_DIRS++))
        continue
    fi

    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would create target directory: $expanded_target"
        echo "[DRY RUN] Would copy contents from $expanded_source to $expanded_target"
        ((SUCCESSFUL_DIRS++))
        continue
    fi

    # Create the target directory if it doesn't exist
    if ! safe_mkdir "$expanded_target"; then
        ((FAILED_DIRS++))
        continue
    fi

    # Copy the contents from source to target, including hidden files
    echo "Copying contents from $expanded_source to $expanded_target"
    if ! cp -r "$expanded_source"/. "$expanded_target"; then
        echo "Error: Failed to copy contents from $expanded_source to $expanded_target"
        ((FAILED_DIRS++))
        continue
    fi
    ((SUCCESSFUL_DIRS++))
done

echo "=================================================="
if [ "$DRY_RUN" = true ]; then
    echo "   [DRY RUN] Directory copy operations simulated"
else
    echo "      Directory copy operations complete"
fi
echo "=================================================="
echo "Summary:"
echo "  Total directories processed: $TOTAL_DIRS"
echo "  Successful: $SUCCESSFUL_DIRS"
echo "  Failed: $FAILED_DIRS"
echo "  Skipped (source not found): $SKIPPED_DIRS"
if [ "$FAILED_DIRS" -gt 0 ]; then
    echo "  Check the output above for error messages"
    exit 1
fi
echo "==================================================" 