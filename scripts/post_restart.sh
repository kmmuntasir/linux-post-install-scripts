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
    rm -f /tmp/.post_restart_test_* 2>/dev/null
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
echo "           Running Post-Restart Operations"
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
    if ! "${cmd[@]}"; then
        echo "Error: Failed to execute: $description"
        return 1
    fi
    return 0
}

# Function to check if group exists
group_exists() {
    local group_name="$1"
    getent group "$group_name" >/dev/null 2>&1
}

# Function to check if user is in group
user_in_group() {
    local user="$1"
    local group="$2"
    groups "$user" 2>/dev/null | grep -q "\b$group\b"
}

# Function to check if service exists
service_exists() {
    local service_name="$1"
    systemctl list-unit-files "$service_name.service" >/dev/null 2>&1
}

# Configure Docker group (legacy support)
if [ "${CONFIGURE_DOCKER_GROUP:-true}" = true ] && [ "${ENABLE_POST_RESTART:-true}" = true ]; then
    echo "Configuring Docker group..."
    ((TOTAL_OPERATIONS++))
    
    local docker_group="${DOCKER_GROUP_NAME:-docker}"
    local current_user="${USER:-$(whoami)}"
    
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would create group: $docker_group"
        echo "[DRY RUN] Would add user $current_user to group: $docker_group"
        ((SUCCESSFUL_OPERATIONS++))
    else
        # Create docker group if it doesn't exist
        if ! group_exists "$docker_group"; then
            if safe_sudo "Create $docker_group group" groupadd "$docker_group"; then
                echo "Created group: $docker_group"
            else
                echo "Error: Failed to create group: $docker_group"
                ((FAILED_OPERATIONS++))
                continue
            fi
        else
            echo "Group $docker_group already exists"
        fi
        
        # Add user to docker group if not already a member
        if ! user_in_group "$current_user" "$docker_group"; then
            if safe_sudo "Add user $current_user to $docker_group group" usermod -aG "$docker_group" "$current_user"; then
                echo "Added user $current_user to group: $docker_group"
                ((SUCCESSFUL_OPERATIONS++))
            else
                echo "Error: Failed to add user to group: $docker_group"
                ((FAILED_OPERATIONS++))
            fi
        else
            echo "User $current_user is already in group: $docker_group"
            ((SUCCESSFUL_OPERATIONS++))
        fi
    fi
fi

# Add user to configured groups
if [ "${ADD_USER_TO_GROUPS:-true}" = true ] && [ "${ENABLE_POST_RESTART:-true}" = true ]; then
    if [ ${#USER_GROUPS[@]} -gt 0 ]; then
        echo "Adding user to configured groups..."
        
        local current_user="${USER:-$(whoami)}"
        
        for group_name in "${USER_GROUPS[@]}"; do
            ((TOTAL_OPERATIONS++))
            echo "Processing group: $group_name"
            
            if [ "$DRY_RUN" = true ]; then
                echo "[DRY RUN] Would create group if needed: $group_name"
                echo "[DRY RUN] Would add user $current_user to group: $group_name"
                ((SUCCESSFUL_OPERATIONS++))
                continue
            fi
            
            # Create group if it doesn't exist
            if ! group_exists "$group_name"; then
                if safe_sudo "Create group $group_name" groupadd "$group_name"; then
                    echo "Created group: $group_name"
                else
                    echo "Warning: Failed to create group: $group_name"
                    ((FAILED_OPERATIONS++))
                    continue
                fi
            fi
            
            # Add user to group if not already a member
            if ! user_in_group "$current_user" "$group_name"; then
                if safe_sudo "Add user $current_user to group $group_name" usermod -aG "$group_name" "$current_user"; then
                    echo "Added user $current_user to group: $group_name"
                    ((SUCCESSFUL_OPERATIONS++))
                else
                    echo "Error: Failed to add user to group: $group_name"
                    ((FAILED_OPERATIONS++))
                fi
            else
                echo "User $current_user is already in group: $group_name"
                ((SUCCESSFUL_OPERATIONS++))
            fi
        done
    else
        echo "No groups configured for user addition"
        ((SKIPPED_OPERATIONS++))
    fi
fi

# Enable services
if [ "${ENABLE_SERVICES:-false}" = true ] && [ "${ENABLE_POST_RESTART:-true}" = true ]; then
    if [ ${#SERVICES_TO_ENABLE[@]} -gt 0 ]; then
        echo "Enabling services..."
        
        for service_name in "${SERVICES_TO_ENABLE[@]}"; do
            ((TOTAL_OPERATIONS++))
            echo "Enabling service: $service_name"
            
            if [ "$DRY_RUN" = true ]; then
                echo "[DRY RUN] Would enable service: $service_name"
                ((SUCCESSFUL_OPERATIONS++))
                continue
            fi
            
            if service_exists "$service_name"; then
                if safe_sudo "Enable service $service_name" systemctl enable "$service_name"; then
                    echo "Enabled service: $service_name"
                    ((SUCCESSFUL_OPERATIONS++))
                else
                    echo "Error: Failed to enable service: $service_name"
                    ((FAILED_OPERATIONS++))
                fi
            else
                echo "Warning: Service not found: $service_name"
                ((SKIPPED_OPERATIONS++))
            fi
        done
    else
        echo "No services configured for enabling"
        ((SKIPPED_OPERATIONS++))
    fi
fi

# Start services
if [ "${START_SERVICES:-false}" = true ] && [ "${ENABLE_POST_RESTART:-true}" = true ]; then
    if [ ${#SERVICES_TO_START[@]} -gt 0 ]; then
        echo "Starting services..."
        
        for service_name in "${SERVICES_TO_START[@]}"; do
            ((TOTAL_OPERATIONS++))
            echo "Starting service: $service_name"
            
            if [ "$DRY_RUN" = true ]; then
                echo "[DRY RUN] Would start service: $service_name"
                ((SUCCESSFUL_OPERATIONS++))
                continue
            fi
            
            if service_exists "$service_name"; then
                if safe_sudo "Start service $service_name" systemctl start "$service_name"; then
                    echo "Started service: $service_name"
                    ((SUCCESSFUL_OPERATIONS++))
                else
                    echo "Error: Failed to start service: $service_name"
                    ((FAILED_OPERATIONS++))
                fi
            else
                echo "Warning: Service not found: $service_name"
                ((SKIPPED_OPERATIONS++))
            fi
        done
    else
        echo "No services configured for starting"
        ((SKIPPED_OPERATIONS++))
    fi
fi

# Display system information
if [ "${SHOW_SYSTEM_INFO:-true}" = true ] && [ "${ENABLE_POST_RESTART:-true}" = true ]; then
    echo "=================================================="
    echo "              System Information"
    echo "=================================================="
    
    # Show user's group membership
    if [ "${SHOW_GROUP_MEMBERSHIP:-true}" = true ]; then
        local current_user="${USER:-$(whoami)}"
        echo "User '$current_user' is member of groups:"
        if [ "$DRY_RUN" = true ]; then
            echo "[DRY RUN] Would show group membership for: $current_user"
        else
            groups "$current_user" 2>/dev/null || echo "Unable to retrieve group information"
        fi
        echo ""
    fi
    
    # Show service status
    if [ "${SHOW_SERVICE_STATUS:-false}" = true ]; then
        echo "Service status:"
        if [ "$DRY_RUN" = true ]; then
            echo "[DRY RUN] Would show service status"
        else
            # Show status of configured services
            local services_to_check=()
            if [ ${#SERVICES_TO_ENABLE[@]} -gt 0 ]; then
                services_to_check+=("${SERVICES_TO_ENABLE[@]}")
            fi
            if [ ${#SERVICES_TO_START[@]} -gt 0 ]; then
                services_to_check+=("${SERVICES_TO_START[@]}")
            fi
            
            if [ ${#services_to_check[@]} -gt 0 ]; then
                for service_name in "${services_to_check[@]}"; do
                    if service_exists "$service_name"; then
                        echo -n "  $service_name: "
                        systemctl is-active "$service_name" 2>/dev/null || echo "inactive"
                    fi
                done
            else
                echo "  No services configured for status check"
            fi
        fi
        echo ""
    fi
fi

echo "=================================================="
if [ "$DRY_RUN" = true ]; then
    echo "   [DRY RUN] Post-restart operations simulated"
else
    echo "      Post-restart operations complete"
fi
echo "=================================================="
echo "Summary:"
echo "  Total operations: $TOTAL_OPERATIONS"
echo "  Successful: $SUCCESSFUL_OPERATIONS"
echo "  Failed: $FAILED_OPERATIONS"
echo "  Skipped: $SKIPPED_OPERATIONS"

if [ "$FAILED_OPERATIONS" -gt 0 ]; then
    echo "  Check the output above for error messages"
    echo "  Note: You may need to log out and back in for group changes to take effect"
fi

if [ "$SUCCESSFUL_OPERATIONS" -gt 0 ] && [ "$DRY_RUN" = false ]; then
    echo ""
    echo "IMPORTANT: Please log out and back in (or restart) for group membership"
    echo "           changes to take effect, especially for Docker access."
fi
echo "==================================================" 