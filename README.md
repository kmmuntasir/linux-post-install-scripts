# Linux Post-Install Scripts

A collection of shell scripts to automate post-installation tasks on Ubuntu/Linux systems. These scripts help in setting up your system with proper drive mounting, directory structures, and other configurations.

## Features

- **Automatic Drive Mounting**: Configure and mount drives using UUIDs
- **Directory Structure**: Create and manage custom directory layouts
- **Directory Copying**: Copy directory structures with validation and safety checks
- **Safe Operations**: 
  - Dry-run support to preview changes
  - Automatic backup of system files
  - Validation of all inputs
  - Error handling and reporting

## Prerequisites

- Ubuntu/Linux system
- Root/sudo access for mounting operations
- `getopt` for command line parsing
- Basic knowledge of drive UUIDs and mount points

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/linux-post-install-scripts.git
   cd linux-post-install-scripts
   ```

2. Create your configuration:
   ```bash
   cp config.sh.example config.sh
   ```

3. Edit the configuration:
   ```bash
   nano config.sh  # or use your preferred editor
   ```

## Configuration

Edit `config.sh` to configure:

1. User settings:
   ```bash
   export INSTALL_USER="your_username"
   ```

2. Mount options:
   ```bash
   export MOUNT_OPTIONS="auto,nosuid,nodev,nofail,x-gvfs-show"
   ```

3. Drive configuration:
   ```bash
   declare -A MOUNT_DISKS=(
       ["$HOME/work"]="your-uuid-here"      # work drive
       ["$HOME/storage"]="your-uuid-here"    # storage drive
   )
   ```

4. Directory copy configuration:
   ```bash
   declare -A COPY_PATHS=(
       ["./sources/fonts"]="$HOME/.fonts"              # user fonts
       ["./sources/icons"]="$HOME/.icons"              # user icons
   )
   ```

To find your drive UUIDs, use:
```bash
lsblk -f
```

## Usage

### Automount Drives

1. Create mount points:
   ```bash
   ./scripts/automount.sh create
   ```

2. Mount drives:
   ```bash
   sudo ./scripts/automount.sh mount
   ```

### Copy Directories

Copy configured directories to their target locations:
```bash
./scripts/copy_dirs.sh
```

With dry-run to preview changes:
```bash
./scripts/copy_dirs.sh --dry-run
```

### Dry Run

To preview changes without applying them:
```bash
./scripts/automount.sh --dry-run create
sudo ./scripts/automount.sh --dry-run mount
./scripts/copy_dirs.sh --dry-run
```

## Mount Options

Common mount options you can use in `config.sh`:

- `auto`: Mount during boot
- `noauto`: Don't mount during boot
- `user`: Allow regular users to mount
- `nosuid`: Ignore suid and sgid bits
- `nodev`: Ignore device special files
- `nofail`: Don't report errors if device is not present
- `x-gvfs-show`: Show in file manager

For more options, see `man mount`.

## Safety Features

- Validates all UUIDs and mount paths
- Creates automatic backups of /etc/fstab
- Checks for root privileges when needed
- Validates configuration before proceeding
- Provides dry-run option for testing
- Protects critical system directories
- Verifies filesystem write permissions
- Validates source and target paths
- Provides detailed operation summaries

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Inspired by common post-installation needs on Ubuntu/Linux systems
- Built with focus on safety and configurability
