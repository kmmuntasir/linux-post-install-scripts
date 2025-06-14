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
    rm -f /tmp/.app_install_test_* 2>/dev/null
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
echo "              Installing Applications"
echo "=================================================="

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to safely run apt commands
safe_apt() {
    local operation="$1"
    shift
    local packages=("$@")
    
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would run: apt $operation ${packages[*]}"
        return 0
    fi
    
    if ! apt "$operation" "${packages[@]}"; then
        echo "Error: Failed to $operation packages: ${packages[*]}"
        return 1
    fi
    return 0
}

# Function to safely run snap commands
safe_snap() {
    local operation="$1"
    local package="$2"
    
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would run: snap $operation $package"
        return 0
    fi
    
    if ! snap "$operation" "$package" 2>/dev/null; then
        echo "Warning: Failed to $operation snap package: $package (may not exist)"
        return 1
    fi
    return 0
}

# Function to safely run flatpak commands
safe_flatpak() {
    local operation="$1"
    shift
    local args=("$@")
    
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would run: flatpak $operation ${args[*]}"
        return 0
    fi
    
    if ! flatpak "$operation" "${args[@]}"; then
        echo "Error: Failed to run flatpak $operation ${args[*]}"
        return 1
    fi
    return 0
}

# Function to safely run pipx commands
safe_pipx() {
    local operation="$1"
    shift
    local args=("$@")
    
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would run: pipx $operation ${args[*]}"
        return 0
    fi
    
    if ! pipx "$operation" "${args[@]}"; then
        echo "Error: Failed to run pipx $operation ${args[*]}"
        return 1
    fi
    return 0
}

# Update package lists
echo "Updating package lists..."
((TOTAL_OPERATIONS++))
if [ "$DRY_RUN" = true ]; then
    echo "[DRY RUN] Would update package lists"
    ((SUCCESSFUL_OPERATIONS++))
else
    if apt update; then
        echo "Package lists updated successfully"
        ((SUCCESSFUL_OPERATIONS++))
    else
        echo "Error: Failed to update package lists"
        ((FAILED_OPERATIONS++))
    fi
fi

# Remove unwanted applications
if [ "${REMOVE_UNWANTED_APPS:-true}" = true ]; then
    echo "Removing unwanted applications..."
    
    # Remove APT packages
    if [ ${#REMOVE_PACKAGES[@]} -gt 0 ]; then
        ((TOTAL_OPERATIONS++))
        echo "Removing APT packages: ${REMOVE_PACKAGES[*]}"
        if safe_apt "autoremove" "-y" "${REMOVE_PACKAGES[@]}"; then
            ((SUCCESSFUL_OPERATIONS++))
        else
            ((FAILED_OPERATIONS++))
        fi
    fi
    
    # Remove snap packages
    if [ ${#REMOVE_SNAPS[@]} -gt 0 ]; then
        for snap_pkg in "${REMOVE_SNAPS[@]}"; do
            ((TOTAL_OPERATIONS++))
            echo "Removing snap package: $snap_pkg"
            if safe_snap "remove" "$snap_pkg"; then
                ((SUCCESSFUL_OPERATIONS++))
            else
                ((FAILED_OPERATIONS++))
            fi
        done
    fi
fi

# Setup Flatpak repository
if [ "${SETUP_FLATPAK_REPO:-true}" = true ]; then
    echo "Setting up Flatpak repository..."
    ((TOTAL_OPERATIONS++))
    
    if command_exists flatpak; then
        if safe_flatpak "remote-add" "--if-not-exists" "flathub" "https://flathub.org/repo/flathub.flatpakrepo"; then
            echo "Flatpak repository setup completed"
            ((SUCCESSFUL_OPERATIONS++))
            
            # Update Flatpak
            ((TOTAL_OPERATIONS++))
            if safe_flatpak "update" "-y"; then
                echo "Flatpak updated successfully"
                ((SUCCESSFUL_OPERATIONS++))
            else
                echo "Warning: Failed to update Flatpak"
                ((FAILED_OPERATIONS++))
            fi
        else
            echo "Error: Failed to setup Flatpak repository"
            ((FAILED_OPERATIONS++))
        fi
    else
        echo "Flatpak not available, skipping repository setup"
        ((SKIPPED_OPERATIONS++))
    fi
fi

# Install APT packages
if [ ${#APT_PACKAGES[@]} -gt 0 ]; then
    echo "Installing APT packages..."
    ((TOTAL_OPERATIONS++))
    
    # Filter out packages that might not be available
    available_packages=()
    for pkg in "${APT_PACKAGES[@]}"; do
        if [ "$DRY_RUN" = true ]; then
            available_packages+=("$pkg")
        else
            if apt-cache show "$pkg" >/dev/null 2>&1; then
                available_packages+=("$pkg")
            else
                echo "Warning: Package $pkg not available in repositories"
            fi
        fi
    done
    
    if [ ${#available_packages[@]} -gt 0 ]; then
        echo "Installing packages: ${available_packages[*]}"
        if safe_apt "install" "-y" "${available_packages[@]}"; then
            echo "APT packages installed successfully"
            ((SUCCESSFUL_OPERATIONS++))
        else
            echo "Error: Failed to install some APT packages"
            ((FAILED_OPERATIONS++))
        fi
    else
        echo "No APT packages available to install"
        ((SKIPPED_OPERATIONS++))
    fi
fi

# Install Flatpak applications
if [ "${INSTALL_FLATPAK_APPS:-true}" = true ] && [ ${#FLATPAK_PACKAGES[@]} -gt 0 ]; then
    echo "Installing Flatpak applications..."
    
    if command_exists flatpak; then
        for flatpak_app in "${FLATPAK_PACKAGES[@]}"; do
            ((TOTAL_OPERATIONS++))
            echo "Installing Flatpak app: $flatpak_app"
            if safe_flatpak "install" "flathub" "$flatpak_app" "-y"; then
                echo "Flatpak app $flatpak_app installed successfully"
                ((SUCCESSFUL_OPERATIONS++))
            else
                echo "Error: Failed to install Flatpak app: $flatpak_app"
                ((FAILED_OPERATIONS++))
            fi
        done
    else
        echo "Flatpak not available, skipping Flatpak applications"
        ((SKIPPED_OPERATIONS++))
    fi
fi

# Install Python packages via pipx
if [ "${INSTALL_PIPX_PACKAGES:-true}" = true ] && [ ${#PIPX_PACKAGES[@]} -gt 0 ]; then
    echo "Installing Python packages via pipx..."
    
    if command_exists pipx; then
        for pipx_pkg in "${PIPX_PACKAGES[@]}"; do
            ((TOTAL_OPERATIONS++))
            echo "Installing pipx package: $pipx_pkg"
            # Split package and arguments
            if safe_pipx "install" $pipx_pkg; then
                echo "Pipx package $pipx_pkg installed successfully"
                ((SUCCESSFUL_OPERATIONS++))
            else
                echo "Error: Failed to install pipx package: $pipx_pkg"
                ((FAILED_OPERATIONS++))
            fi
        done
    else
        echo "Pipx not available, skipping Python packages"
        ((SKIPPED_OPERATIONS++))
    fi
fi

# Install DEB files
if [ "${INSTALL_DEB_FILES:-false}" = true ] && [ -n "${DEB_FILES_DIR:-}" ]; then
    echo "Installing DEB files..."
    ((TOTAL_OPERATIONS++))
    
    # Expand the DEB_FILES_DIR path
    eval "expanded_deb_dir=$DEB_FILES_DIR"
    
    if [ -d "$expanded_deb_dir" ] && [ "$(ls -A "$expanded_deb_dir"/*.deb 2>/dev/null)" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "[DRY RUN] Would install DEB files from: $expanded_deb_dir"
            ((SUCCESSFUL_OPERATIONS++))
        else
            echo "Installing DEB files from: $expanded_deb_dir"
            if dpkg -i "$expanded_deb_dir"/*.deb && apt install -f -y; then
                echo "DEB files installed successfully"
                ((SUCCESSFUL_OPERATIONS++))
            else
                echo "Error: Failed to install DEB files"
                ((FAILED_OPERATIONS++))
            fi
        fi
    else
        echo "No DEB files found in $expanded_deb_dir, skipping"
        ((SKIPPED_OPERATIONS++))
    fi
fi

echo "=================================================="
if [ "$DRY_RUN" = true ]; then
    echo "   [DRY RUN] Application installation simulated"
else
    echo "      Application installation complete"
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