# linux-post-install-scripts
This is a personal repo for maintaining post install scripts for my own Linux systems

## Pre Requisites
1. User should manually install any pre-requisites for the installation
2. If the user has and Nvidia graphics card in the system, s/he should manually install **Gnome Software and Updates** and then should install the Nvidia Proprietary Driver. To install **Gnome Software and Updates**, use the following command:
```shell
sudo apt install software-properties-gtk
```
3. ...

## How to Run
use `sudo -u <user-name> ./<script-file-name>` to run the installer for specific user.  
Example:
```shell
sudo -u brian ./install.sh
sudo -u brian ./uninstall.sh
```

## Installation Work Process
1. Initialize Data
   1. Determine username, home directory path, etc.
2. Perform Directory Related Operations
   1. Enable Automount for Selected Drives
   2. Create necessary symlinks
   3. Copy/Move any necessary backup files and folders
5. Add necessary repositories
6. Install Apps from Repositories
7. Install Apps from Local Storage
   1. Install Apps from tarball archives (By extracting and moving to specific dir)
      1. Flutter
      2. NodeJS
   2. Install Apps from deb archives (By using dpkg)
   3. Install Apps from shell installers (By running scripts)
   4. Schedule any necessary System Path and Environment Variables to be added later
8. Perform OS specific actions (Example given for Elementary OS)
   1. Set Suspend to "Never"
   2. Set Fixed number of Workspaces
   3. Enable SysTray Icons
9. Perform User Defined Configurations
   1. Configure iBus
   2. Update Grub Timeout
   3. Increase iNotify Limit
   4. Enable KVM
   5. Restore SSH Keys
   6. Set System Paths and Environment Variables
11. Update and Upgrade System
12. Reboot System