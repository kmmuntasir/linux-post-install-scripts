#!/bin/bash

# Exit on error
set -e

# Initialize dry-run flag and counters
DRY_RUN=false
VERBOSE=false
TOTAL_REPOS=0
SUCCESSFUL_REPOS=0
FAILED_REPOS=0
SKIPPED_REPOS=0

# Check for enhanced getopt availability
if ! getopt --test > /dev/null; then
    if [[ $? -ne 4 ]]; then
        echo "Error: Enhanced getopt is not available"
        echo "To install it:"
        echo "  - On Debian/Ubuntu: sudo apt-get install util-linux"
        echo "  - On macOS: brew install gnu-getopt"
        echo "  - On RHEL/CentOS: sudo yum install util-linux-ng"
        exit 1
    fi
fi

# Parse command line options
TEMP=$(getopt -o 'v' --long dry-run,verbose -n "$(basename "$0")" -- "$@") || {
    echo "Usage: $(basename "$0") [--dry-run] [-v|--verbose]"
    exit 1
}

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
        -v|--verbose)
            VERBOSE=true
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

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Source the configuration file
if [ -f "$PROJECT_ROOT/config.sh" ]; then
    source "$PROJECT_ROOT/config.sh"
else
    echo "Error: config.sh not found. Please create it from config.sh.example"
    exit 1
fi

echo "=================================================="
echo "              Adding Repositories"
echo "=================================================="

# Function to validate repository format
validate_repository_format() {
    local repo="$1"
    local value="$2"
    if [[ "$value" != *"|"*"|"* ]]; then
        echo "Error: Invalid format for repository $repo"
        echo "Expected format: 'key_url|key_path|source_entry'"
        return 1
    fi
    return 0
}

# Function to add a PPA repository
add_ppa_repository() {
    local ppa_name="$1"
    ((TOTAL_REPOS++))
    
    echo "Processing PPA: $ppa_name"
    
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would add PPA: $ppa_name"
        ((SUCCESSFUL_REPOS++))
        return 0
    fi

    # Check for add-apt-repository command
    if ! command -v add-apt-repository >/dev/null 2>&1; then
        echo "Installing software-properties-common..."
        if ! apt-get install -y software-properties-common; then
            echo "Error: Failed to install software-properties-common"
            ((FAILED_REPOS++))
            return 1
        fi
    fi

    if add-apt-repository "$ppa_name" -y; then
        echo "Successfully added PPA: $ppa_name"
        ((SUCCESSFUL_REPOS++))
        return 0
    else
        echo "Error: Failed to add PPA: $ppa_name"
        ((FAILED_REPOS++))
        return 1
    fi
}

# Function to add a repository using GPG key and source list
add_gpg_repository() {
    local name="$1"
    local key_url="$2"
    local key_path="$3"
    local source_entry="$4"
    ((TOTAL_REPOS++))
    
    echo "Processing repository: $name"
    
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would download GPG key from: $key_url"
        echo "[DRY RUN] Would store key at: $key_path"
        echo "[DRY RUN] Would add source entry: $source_entry"
        ((SUCCESSFUL_REPOS++))
        return 0
    fi
    
    # Create keyrings directory if it doesn't exist
    install -m 0755 -d /etc/apt/keyrings
    
    # Download GPG key with retry mechanism and fallback
    local max_attempts=3
    local attempt=1
    while [ $attempt -le $max_attempts ]; do
        echo "Downloading GPG key (attempt $attempt/$max_attempts)..."
        
        # Try curl first
        if command -v curl >/dev/null 2>&1; then
            if curl -fsSL "$key_url" -o "$key_path"; then
                break
            fi
            echo "curl failed, trying wget..."
        fi
        
        # Try wget as fallback
        if command -v wget >/dev/null 2>&1; then
            if wget -qO "$key_path" "$key_url"; then
                break
            fi
            echo "wget failed..."
        else
            echo "Error: Neither curl nor wget is available"
            ((FAILED_REPOS++))
            return 1
        fi
        
        # If both failed, retry after delay
        attempt=$((attempt + 1))
        [ $attempt -le $max_attempts ] && {
            echo "Retrying in 2 seconds..."
            sleep 2
        }
    done
    
    if [ $attempt -gt $max_attempts ]; then
        echo "Error: Failed to download GPG key for $name after $max_attempts attempts"
        ((FAILED_REPOS++))
        return 1
    fi
    
    # Verify GPG key
    if ! gpg --dry-run --import "$key_path" >/dev/null 2>&1; then
        echo "Error: Invalid GPG key for $name"
        ((FAILED_REPOS++))
        return 1
    fi
    
    chmod a+r "$key_path"
    
    # Add repository source
    if ! echo "$source_entry" | tee "/etc/apt/sources.list.d/$name.list" > /dev/null; then
        echo "Error: Failed to add source entry for $name"
        ((FAILED_REPOS++))
        return 1
    fi

    echo "Successfully added repository: $name"
    ((SUCCESSFUL_REPOS++))
    return 0
}

# Function to remove conflicting packages
remove_conflicting_packages() {
    local packages=("$@")
    local failed=0
    for pkg in "${packages[@]}"; do
        echo "Attempting to remove package: $pkg"
        if [ "$DRY_RUN" = true ]; then
            echo "[DRY RUN] Would remove package: $pkg"
            continue
        fi
        if apt-get remove -y "$pkg" >/dev/null 2>&1; then
            echo "Successfully removed: $pkg"
        elif [ "$VERBOSE" = true ]; then
            echo "Note: Package $pkg was not installed or could not be removed"
        fi
    done
    return $failed
}

# Check if repository arrays are declared
if [ -z "${PPA_REPOSITORIES+x}" ]; then
    declare -a PPA_REPOSITORIES=()
fi
if [ -z "${GPG_REPOSITORIES+x}" ]; then
    declare -A GPG_REPOSITORIES=()
fi
if [ -z "${CONFLICTING_PACKAGES+x}" ]; then
    declare -a CONFLICTING_PACKAGES=()
fi

# Check if any repositories are defined
if [ ${#PPA_REPOSITORIES[@]} -eq 0 ] && [ ${#GPG_REPOSITORIES[@]} -eq 0 ]; then
    echo "No repositories defined in config.sh"
    exit 0
fi

# Ensure script is run with root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run with sudo privileges"
    exit 1
fi

# Install prerequisites
echo "Installing prerequisites..."
if [ "$DRY_RUN" = true ]; then
    echo "[DRY RUN] Would update package lists"
    echo "[DRY RUN] Would install: apt-transport-https ca-certificates curl wget gnupg software-properties-common"
else
    apt-get update || {
        echo "Error: Failed to update package lists"
        exit 1
    }
    apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        wget \
        gnupg \
        software-properties-common || {
        echo "Error: Failed to install prerequisites"
        exit 1
    }
fi

# Remove conflicting packages if specified
if [ ${#CONFLICTING_PACKAGES[@]} -gt 0 ]; then
    echo "Processing conflicting packages..."
    remove_conflicting_packages "${CONFLICTING_PACKAGES[@]}"
fi

# Add PPA repositories
for ppa in "${PPA_REPOSITORIES[@]}"; do
    add_ppa_repository "$ppa" || true
done

# Add GPG key repositories
for repo in "${!GPG_REPOSITORIES[@]}"; do
    # Validate repository format
    if ! validate_repository_format "$repo" "${GPG_REPOSITORIES[$repo]}"; then
        ((SKIPPED_REPOS++))
        continue
    fi
    
    # Save current IFS
    OLDIFS="$IFS"
    # Set IFS to | for splitting
    IFS='|' read -r key_url key_path source_entry <<< "${GPG_REPOSITORIES[$repo]}"
    # Restore IFS
    IFS="$OLDIFS"
    
    add_gpg_repository "$repo" "$key_url" "$key_path" "$source_entry" || true
done

# Final update of package lists
echo "Updating package lists..."
if [ "$DRY_RUN" = true ]; then
    echo "[DRY RUN] Would update package lists"
else
    if ! apt-get update; then
        echo "Warning: Package list update partially failed"
        echo "Some repositories may not be available"
        echo "To fix this, try:"
        echo "  sudo apt-get update --fix-missing"
        echo "  sudo apt-get install -f"
        echo "Then run this script again"
    fi
fi

echo "=================================================="
if [ "$DRY_RUN" = true ]; then
    echo "   [DRY RUN] Repository operations simulated"
else
    echo "        Repository setup complete"
fi
echo "=================================================="
echo "Summary:"
echo "  Total repositories processed: $TOTAL_REPOS"
echo "  Successful: $SUCCESSFUL_REPOS"
echo "  Failed: $FAILED_REPOS"
echo "  Skipped: $SKIPPED_REPOS"
if [ "$FAILED_REPOS" -gt 0 ]; then
    echo "  Check the output above for error messages"
    exit 1
fi
echo "==================================================" 