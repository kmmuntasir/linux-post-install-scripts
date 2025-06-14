# Linux Post-Install Scripts

A comprehensive collection of shell scripts to automate post-installation tasks on Ubuntu/Linux systems. These scripts help set up your system with proper drive mounting, directory structures, application installation, system configuration, and more.

## 🚀 Features

- **🔧 Modular Design**: Each component can be run independently or as part of a complete setup
- **🛡️ Safety First**: Dry-run support, automatic backups, and comprehensive validation
- **⚙️ Highly Configurable**: All settings managed through a single configuration file
- **📊 Detailed Reporting**: Progress tracking and comprehensive summaries
- **🔄 Error Resilience**: Graceful error handling with configurable policies
- **🎯 Modern Best Practices**: Following shell scripting best practices with proper error handling

### Core Components

- **🗂️ Automatic Drive Mounting**: Configure and mount drives using UUIDs with safety checks
- **🔗 Symlink Management**: Replace default directories with symlinks to custom locations
- **📁 Directory Operations**: Copy directory structures with validation and safety checks
- **📦 Repository Management**: Add PPAs and custom repositories with GPG key handling
- **🚀 Application Installation**: Install APT, Flatpak, and pipx packages with dependency management
- **⚙️ System Configuration**: GRUB settings, lid switch behavior, and system tweaks
- **👤 User Configuration**: GNOME extensions, SSH setup, and development environment
- **🔄 System Updates**: Comprehensive update management for all package managers
- **🔧 Post-Restart Setup**: Group management and service configuration

## 📋 Prerequisites

- Ubuntu/Linux system (tested on Ubuntu 24.04)
- Root/sudo access for system-level operations
- `getopt` for command line parsing (usually pre-installed)
- Basic knowledge of drive UUIDs and mount points

## 🛠️ Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/linux-post-install-scripts.git
   cd linux-post-install-scripts
   ```

2. **Create your configuration:**
   ```bash
   cp config.sh.example config.sh
   ```

3. **Edit the configuration:**
   ```bash
   nano config.sh  # or use your preferred editor
   ```

4. **Make scripts executable (optional - done automatically):**
   ```bash
   make prepare
   ```

## ⚙️ Configuration

The `config.sh` file contains all configuration options. Key sections include:

### 👤 User Settings
```bash
export INSTALL_USER="your_username"
```

### 💾 Drive Configuration
```bash
declare -A MOUNT_DISKS=(
    ["$HOME/work"]="your-work-drive-uuid"
    ["$HOME/storage"]="your-storage-drive-uuid"
)
```

### 🔗 Symlink Configuration
```bash
declare -A SYMLINK_PATHS=(
    ["$HOME/Desktop"]="$HOME/storage/system/Desktop"
    ["$HOME/Documents"]="$HOME/storage/system/Documents"
    ["$HOME/Downloads"]="$HOME/storage/system/Downloads"
)
```

### 📁 Directory Copy Configuration
```bash
declare -A COPY_PATHS=(
    ["./sources/fonts"]="$HOME/.fonts"
    ["./sources/icons"]="$HOME/.icons"
    ["./sources/launchers"]="$HOME/.local/share/applications"
)
```

### 📦 Application Installation
```bash
declare -a APT_PACKAGES=(
    "git" "curl" "htop" "vim"
    # Add your packages here
)

declare -a FLATPAK_PACKAGES=(
    "org.example.Application"
    # Add your Flatpak apps here
)
```

### 🔧 System Settings
```bash
export GRUB_TIMEOUT=5
export LID_SWITCH_ACTION="suspend"
export INSTALL_GNOME_EXTENSIONS=true
```

**💡 Tip:** See `config.sh.example` for all available options with detailed comments.

## 🎯 Usage

### Quick Start - Complete Setup
```bash
# Preview all operations (recommended first run)
make all --dry-run

# Run complete setup
make all
```

### Individual Components

#### 🗂️ Drive Management
```bash
# Preview drive operations
./scripts/automount.sh --dry-run create
sudo ./scripts/automount.sh --dry-run mount

# Create mount points and mount drives
make automount
```

#### 🔗 Symlink Creation
```bash
# Preview symlink operations
./scripts/create_symlinks.sh --dry-run

# Create symlinks
make symlinks
```

#### 📁 Directory Copying
```bash
# Preview copy operations
./scripts/copy_dirs.sh --dry-run

# Copy directories
make copy_dirs
```

#### 📦 Repository & Application Setup
```bash
# Add repositories
make repos

# Install applications
make apps
```

#### ⚙️ System Configuration
```bash
# Configure system and user settings
make misc
```

#### 🔄 System Updates
```bash
# Preview update operations
./scripts/update.sh --dry-run

# Update system
make update
```

#### 🔧 Post-Restart Operations
```bash
# Configure groups and services (run after restart)
make post_restart
```

### 🧪 Dry-Run Mode

All scripts support `--dry-run` for safe testing:

```bash
# Test individual scripts
./scripts/automount.sh --dry-run create
./scripts/install_apps.sh --dry-run
./scripts/misc.sh --dry-run

# Test via make (add to individual commands)
./scripts/update.sh --dry-run && echo "Update preview complete"
```

## 📂 Directory Structure

```
linux-post-install-scripts/
├── config.sh                    # Your configuration
├── config.sh.example           # Configuration template
├── Makefile                     # Task runner
├── README.md                    # This file
├── debs/                        # Local DEB files for installation
├── sources/                     # Source files to copy
│   ├── fonts/                   # Custom fonts
│   ├── icons/                   # Custom icons
│   ├── launchers/               # Application launchers
│   └── home/                    # Home directory files
└── scripts/                     # All executable scripts
    ├── automount.sh             # Drive mounting
    ├── create_symlinks.sh       # Symlink management
    ├── copy_dirs.sh             # Directory copying
    ├── add_repositories.sh      # Repository management
    ├── install_apps.sh          # Application installation
    ├── misc.sh                  # System configuration
    ├── misc_user.sh             # User configuration
    ├── update.sh                # System updates
    └── post_restart.sh          # Post-restart setup
```

## 🔧 Advanced Usage

### Custom Package Lists

Add your packages to the appropriate arrays in `config.sh`:

```bash
# APT packages
declare -a APT_PACKAGES=(
    "git" "curl" "htop" "neovim"
    "docker-ce" "nodejs" "python3-pip"
)

# Flatpak applications
declare -a FLATPAK_PACKAGES=(
    "com.visualstudio.code"
    "org.mozilla.firefox"
)
```

### Service Management

Configure services in `config.sh`:

```bash
# Enable services at boot
declare -a SERVICES_TO_ENABLE=(
    "docker"
    "ssh"
)

# Start services immediately
declare -a SERVICES_TO_START=(
    "docker"
)

export ENABLE_SERVICES=true
export START_SERVICES=true
```

### Custom Repositories

Add repositories with GPG keys:

```bash
declare -A GPG_REPOSITORIES=(
    ["docker"]="https://download.docker.com/linux/ubuntu/gpg|/etc/apt/keyrings/docker.asc|deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable"
)
```

### Error Handling

Configure error behavior:

```bash
export SKIP_UPDATE_ON_ERROR=true    # Continue despite errors
export UPDATE_VERBOSE=true          # Detailed output
```

## 🛡️ Safety Features

- **🔍 Dry-Run Mode**: Preview all operations before execution
- **💾 Automatic Backups**: System files backed up before modification
- **✅ Validation**: UUIDs, paths, and permissions validated
- **🔒 Protected Directories**: Prevents modification of critical system paths
- **📊 Operation Tracking**: Detailed success/failure reporting
- **🔄 Rollback Support**: Automatic restoration on failure

## 🐛 Troubleshooting

### Common Issues

1. **Permission Denied**
   ```bash
   # Make scripts executable
   make prepare
   ```

2. **Config File Not Found**
   ```bash
   # Create config from template
   cp config.sh.example config.sh
   ```

3. **Drive UUID Not Found**
   ```bash
   # Find your drive UUIDs
   lsblk -f
   sudo blkid
   ```

4. **Group Changes Not Applied**
   ```bash
   # Log out and back in, or restart
   # Check group membership
   groups $USER
   ```

### Debug Mode

Enable verbose output for troubleshooting:

```bash
# In config.sh
export UPDATE_VERBOSE=true

# Or temporarily
UPDATE_VERBOSE=true ./scripts/update.sh
```

### Log Files

Check system logs for detailed error information:

```bash
# System logs
journalctl -xe

# APT logs
cat /var/log/apt/history.log
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by common post-installation needs on Ubuntu/Linux systems
- Built with focus on safety, configurability, and modern best practices
- Community feedback and contributions

## 📞 Support

- 📖 Check this README for comprehensive documentation
- 🐛 Report issues on GitHub Issues
- 💡 Request features via GitHub Discussions
- 🔧 Use `--dry-run` mode to test before applying changes

---

**⚠️ Important Notes:**
- Always run `--dry-run` first to preview changes
- Some operations require logout/restart to take effect
- Keep backups of important data before running system modifications
- Review configuration carefully before execution
