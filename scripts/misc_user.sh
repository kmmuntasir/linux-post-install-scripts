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
    rm -f /tmp/.misc_user_test_* 2>/dev/null
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
echo "              Configuring User Settings"
echo "=================================================="

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to safely run commands
safe_run() {
    local description="$1"
    shift
    local cmd=("$@")
    
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would run: ${cmd[*]}"
        return 0
    fi
    
    echo "Running: $description"
    if ! "${cmd[@]}"; then
        echo "Error: Failed to execute: $description"
        return 1
    fi
    return 0
}

# Function to safely source files
safe_source() {
    local file="$1"
    
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would source: $file"
        return 0
    fi
    
    if [ -f "$file" ]; then
        # shellcheck disable=SC1090
        source "$file"
        return 0
    else
        echo "Warning: File not found for sourcing: $file"
        return 1
    fi
}

# Install GNOME shell extensions
if [ "${INSTALL_GNOME_EXTENSIONS:-true}" = true ] && [ "${ENABLE_USER_MISC:-true}" = true ]; then
    echo "Installing GNOME shell extensions..."
    
    if command_exists gnome-extensions-cli; then
        # Source bashrc to ensure environment is loaded
        if safe_source "$HOME/.bashrc"; then
            echo "Sourced .bashrc successfully"
        fi
        
        for extension_id in "${GNOME_EXTENSIONS[@]}"; do
            ((TOTAL_OPERATIONS++))
            echo "Installing GNOME extension: $extension_id"
            if safe_run "Install GNOME extension $extension_id" gnome-extensions-cli install "$extension_id"; then
                echo "GNOME extension $extension_id installed successfully"
                ((SUCCESSFUL_OPERATIONS++))
            else
                echo "Error: Failed to install GNOME extension: $extension_id"
                ((FAILED_OPERATIONS++))
            fi
        done
    else
        echo "gnome-extensions-cli not available, skipping GNOME extensions"
        ((SKIPPED_OPERATIONS++))
    fi
fi

# Configure SSH
if [ "${CONFIGURE_SSH:-true}" = true ] && [ "${ENABLE_USER_MISC:-true}" = true ]; then
    echo "Configuring SSH..."
    ((TOTAL_OPERATIONS++))
    
    # Run SSH permissions script if it exists
    local ssh_script="${SSH_PERMISSIONS_SCRIPT:-./scripts/ssh_permission.sh}"
    eval "expanded_ssh_script=$ssh_script"
    
    if [ -f "$expanded_ssh_script" ]; then
        if safe_run "Set SSH permissions" "$expanded_ssh_script"; then
            echo "SSH permissions configured"
        else
            echo "Warning: Failed to run SSH permissions script"
        fi
    else
        echo "Warning: SSH permissions script not found: $expanded_ssh_script"
    fi
    
    # Start SSH agent and add keys
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would start SSH agent"
        for key in "${SSH_KEYS[@]}"; do
            eval "expanded_key=$key"
            echo "[DRY RUN] Would add SSH key: $expanded_key"
        done
        ((SUCCESSFUL_OPERATIONS++))
    else
        # Start SSH agent
        if eval "$(ssh-agent -s)"; then
            echo "SSH agent started"
            
            # Add SSH keys
            local keys_added=0
            for key in "${SSH_KEYS[@]}"; do
                eval "expanded_key=$key"
                if [ -f "$expanded_key" ]; then
                    if ssh-add "$expanded_key" 2>/dev/null; then
                        echo "Added SSH key: $expanded_key"
                        ((keys_added++))
                    else
                        echo "Warning: Failed to add SSH key: $expanded_key"
                    fi
                else
                    echo "Warning: SSH key not found: $expanded_key"
                fi
            done
            
            if [ $keys_added -gt 0 ]; then
                echo "SSH configuration completed ($keys_added keys added)"
                ((SUCCESSFUL_OPERATIONS++))
            else
                echo "Warning: No SSH keys were added"
                ((SKIPPED_OPERATIONS++))
            fi
        else
            echo "Error: Failed to start SSH agent"
            ((FAILED_OPERATIONS++))
        fi
    fi
fi

# Install NVM (Node Version Manager)
if [ "${INSTALL_NVM:-true}" = true ] && [ "${ENABLE_USER_MISC:-true}" = true ]; then
    echo "Installing NVM..."
    ((TOTAL_OPERATIONS++))
    
    local nvm_version="${NVM_VERSION:-v0.39.7}"
    local nvm_url="https://raw.githubusercontent.com/nvm-sh/nvm/$nvm_version/install.sh"
    
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would download and install NVM $nvm_version"
        if [ "${INSTALL_NODE_LTS:-true}" = true ]; then
            echo "[DRY RUN] Would install latest LTS Node.js"
        fi
        ((SUCCESSFUL_OPERATIONS++))
    else
        if command_exists wget; then
            if wget -qO- "$nvm_url" | bash; then
                echo "NVM $nvm_version installed successfully"
                
                # Source NVM script
                export NVM_DIR="$HOME/.nvm"
                if [ -s "$NVM_DIR/nvm.sh" ]; then
                    # shellcheck disable=SC1091
                    source "$NVM_DIR/nvm.sh"
                    
                    # Install latest LTS Node.js if requested
                    if [ "${INSTALL_NODE_LTS:-true}" = true ]; then
                        echo "Installing latest LTS Node.js..."
                        if nvm install --lts; then
                            echo "Latest LTS Node.js installed successfully"
                        else
                            echo "Warning: Failed to install latest LTS Node.js"
                        fi
                    fi
                    ((SUCCESSFUL_OPERATIONS++))
                else
                    echo "Warning: NVM script not found after installation"
                    ((FAILED_OPERATIONS++))
                fi
            else
                echo "Error: Failed to install NVM"
                ((FAILED_OPERATIONS++))
            fi
        else
            echo "Error: wget not available for NVM installation"
            ((FAILED_OPERATIONS++))
        fi
    fi
fi

echo "=================================================="
if [ "$DRY_RUN" = true ]; then
    echo "   [DRY RUN] User settings configuration simulated"
else
    echo "      User settings configuration complete"
fi
echo "=================================================="
echo "Summary:"
echo "  Total operations: $TOTAL_OPERATIONS"
echo "  Successful: $SUCCESSFUL_OPERATIONS"
echo "  Failed: $FAILED_OPERATIONS"
echo "  Skipped: $SKIPPED_OPERATIONS"

if [ "$FAILED_OPERATIONS" -gt 0 ]; then
    echo "  Check the output above for error messages"
    echo "  Note: Some failures may be expected (e.g., missing SSH keys)"
fi
echo "==================================================" 