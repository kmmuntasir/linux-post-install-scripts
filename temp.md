# Actions after installing a fresh copy of Ubuntu 24.04.02

1. `sudo find ./ -type f -name "*.sh" -exec chmod +x {} \;` - Make all scripts executable
2. Automount Drives  
```bash
    #!/bin/bash

echo "=================================================="
echo "                 Automount Drives"
echo "=================================================="

# Array of objects with directory names and UUIDs
declare -A disks=(
  ["$HOME/work"]="7B55B5A8561E3172"
  ["$HOME/storage"]="0CFDA14220BB57D7"
)

# Check for input argument
if [ -z "$1" ]; then
  echo "Error: No parameter provided. Use 'create' to create directories or 'mount' to mount them."
  exit 1
fi

# Create directories based on parameter
if [ "$1" == "create" ]; then
  for dir in "${!disks[@]}"; do
    # Create directory if it doesn't exist
    mkdir -p "$dir"
    echo "Created directory: $dir"
  done
  echo "=================================================="
  echo "               Directories created"
  echo "=================================================="

elif [ "$1" == "mount" ]; then
  for dir in "${!disks[@]}"; do
    # Prepare the fstab entry
    UUID="${disks[$dir]}"
    FSTAB_ENTRY="/dev/disk/by-uuid/$UUID $dir auto nosuid,nodev,nofail,x-gvfs-show 0 0"

    # Add entry to /etc/fstab if it's not already present
    if ! grep -qs "$UUID" /etc/fstab; then
      echo "Adding $dir to /etc/fstab"
      sudo sed -i "\$ a $FSTAB_ENTRY" /etc/fstab
    else
      echo "$dir is already in /etc/fstab"
    fi
    # Mount the directory
    if mount | grep "$dir" > /dev/null; then
      echo "$dir is already mounted"
    else
      echo "Mounting $dir"
      sudo mount "$dir"
    fi
  done
  systemctl daemon-reload
  echo "=================================================="
  echo "               Directories mounted"
  echo "=================================================="

else
  echo "Error: Invalid parameter. Use 'create' to create directories or 'mount' to mount them."
  exit 1
fi

```
3. Create Symlinks
```bash
#!/bin/bash

echo "=================================================="
echo "    Replacing Default Directories with Symlinks"
echo "=================================================="

# Array of objects with full paths of original directories and their replacement paths
declare -A directories=(
  ["$HOME/Desktop"]="$HOME/storage/system/Desktop"
  ["$HOME/Documents"]="$HOME/storage/system/Documents"
  ["$HOME/Downloads"]="$HOME/storage/system/Downloads"
  ["$HOME/dev"]="$HOME/work/dev"
)

# Loop through the array and replace the original directories with symlinks
for original_dir in "${!directories[@]}"; do
  replacement_dir="${directories[$original_dir]}"

  # Remove the original directory if it exists
  if [ -d "$original_dir" ]; then
    echo "Removing $original_dir"
    rm -rf "$original_dir"
  fi

  # Create the symlink
  echo "Creating symlink for $original_dir -> $replacement_dir"
  ln -s "$replacement_dir" "$original_dir"
done

echo "=================================================="
echo "   Directory replacement with symlinks complete"
echo "=================================================="
```
4. Copy Directories
```bash
#!/bin/bash

echo "=================================================="
echo "       Copying Directories to Target Locations"
echo "=================================================="

# Array of directories to copy (source -> target)
declare -A directories=(
  ["./sources/fonts"]="$HOME/.fonts"
  ["./sources/icons"]="$HOME/.icons"
  ["./sources/launchers"]="$HOME/.local/share/applications/"
  ["./sources/home"]="$HOME/"
)

# Loop through the array and copy each source directory to the target location
for source_dir in "${!directories[@]}"; do
  target_dir="${directories[$source_dir]}"

  # Check if the source directory exists
  if [ -d "$source_dir" ]; then
    echo "Copying $source_dir to $target_dir"

    # Create the target directory if it doesn't exist
    mkdir -p "$target_dir"

    # Copy the contents from source to target, including hidden files
    cp -r "$source_dir"/. "$target_dir"
  else
    echo "Source directory $source_dir does not exist, skipping."
  fi
done

echo "=================================================="
echo "      Directory copy operation complete"
echo "=================================================="
```
5. `sudo -u ${INSTALL_USER} ./add_repositories.sh` - Add Repositories
```bash
#!/bin/bash

echo "=================================================="
echo "              Adding Repositories"
echo "=================================================="

# List of PPAs
repositories=(
  "ppa:touchegg/stable"                      # Touchegg for touchpad gestures
  "ppa:flatpak/stable"                       # Flatpak
)

# Loop through the list and add each PPA
for ppa in "${repositories[@]}"; do
  echo "Adding $ppa"
  sudo add-apt-repository "$ppa" -y
done

echo "=================================================="
echo "        Repository setup complete"
echo "=================================================="


#!/bin/bash

echo "=================================================="
echo "              Adding Custom Repositories"
echo "=================================================="

# Installing python3-pip for other packages
sudo apt install pipx -y

# Repo for Sublime Text
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
sudo apt-get install apt-transport-https -y
echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list

# Repo for Brave Browser
sudo apt install curl -y
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list

# Repo for Spotify
curl -sS https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list

# Repo Prepare for Docker

## Uninstall conflicting packages
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

## Setup docker's apt repo
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl -y
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

### If you use an Ubuntu derivative distro, such as Linux Mint, you may need to use UBUNTU_CODENAME instead of VERSION_CODENAME.

# Update package list after adding all repositories
sudo apt update

echo "=================================================="
echo "        Custom Repository setup complete"
echo "=================================================="
```
6. `sudo -u ${INSTALL_USER} ./install_apps.sh` - Install Apps
```bash
#!/bin/bash

sudo apt install flatpak -y

flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

flatpak update

flatpak install flathub com.mattjakeman.ExtensionManager io.missioncenter.MissionCenter io.podman_desktop.PodmanDesktop io.github.dweymouth.supersonic -y

# Installing Gnome Extensions Cli
pipx install gnome-extensions-cli --system-site-packages


# Remove unnecessary apps
sudo apt autoremove thunderbird thunderbird* transmission-* -y
sudo snap remove thunderbird && sudo snap remove transmission

# Read the list of apps from the file
declare -a apps=(
  "audacious"
  "audacity"
  "bashtop"
  "brave-browser"
  "celluloid"
  "clementine"
  "codeblocks"
  "curl"
  "docker-ce"
  "docker-ce-cli"
  "containerd.io"
  "docker-buildx-plugin"
  "docker-compose-plugin"
  "fceux"
  "filezilla"
  "gedit"
  "gimp"
  "git"
  "gitk"
  "gnome-tweaks"
  "gparted"
  "hardinfo"
  "htop"
  "kamoso"
  "kodi"
  "make"
  "mousepad"
  "net-tools"
  "obs-studio"
  "p7zip-full"
  "p7zip-rar"
  "psensor"
  "qemu-kvm"
  "qbittorrent"
  "qpdfview"
  "skanlite"
  "smplayer"
  "spotify-client"
  "sublime-text"
  "synapse"
  "synaptic"
  "touchegg"
  "ubuntu-restricted-extras"
  "unrar"
  "variety"
  "vlc"
  "wine-stable"
)

# Install Deb Packages
# sudo apt update
# sudo dpkg -i ./debs/*.deb
# sudo apt install -f -y

# Install all apps
sudo apt install -y "${apps[@]}"

# Install Zed
# curl -f https://zed.dev/install.sh | sh
# echo 'export PATH=$HOME/.local/bin:$PATH' >> $HOME/.bashrc

# Install Spotify
# sudo snap install spotify

# Update and Upgrade system
./update.sh
```
7. `sudo -u ${INSTALL_USER} ./misc.sh` - Run Miscellaneous Settings
```bash
#!/bin/bash

echo "=================================================="
echo "              Update Grub Timeout"
echo "=================================================="
sudo sed -i -e 's/^GRUB_TIMEOUT=[0-9]\+/GRUB_TIMEOUT=1/' /etc/default/grub
sudo update-grub

# Copy update.sh file to $HOME directory
cp ./update.sh $HOME
sudo chmod +x $HOME/update.sh

# Ignoring Lid Switch

# Function to update logind.conf
update_logind_conf() {
    local conf_file="/etc/systemd/logind.conf"
    
    # Check if the file exists
    if [[ ! -f $conf_file ]]; then
        echo "Logind configuration file not found!"
        exit 1
    fi

    # Use sed to update the file
    sudo sed -i.bak '/^HandleLidSwitch=/c\HandleLidSwitch=lock' "$conf_file"
    sudo sed -i.bak '/^HandleLidSwitchExternalPower=/c\HandleLidSwitchExternalPower=lock' "$conf_file"

    # Uncomment if previously commented
    sudo sed -i.bak 's/#HandleLidSwitch=/HandleLidSwitch=/g' "$conf_file"
    sudo sed -i.bak 's/#HandleLidSwitchExternalPower=/HandleLidSwitchExternalPower=/g' "$conf_file"

    echo "Updated $conf_file to lock the screen on lid switch actions."
}

# Execute the functions
update_logind_conf
```
8. Run non-root misc operations
```bash
#!/bin/bash

# Install gnome shell extensions
source $HOME/.bashrc
gnome-extensions-cli install 3193 # Blur My Shell
gnome-extensions-cli install 4033 # X11 Gestures
gnome-extensions-cli install 4167 # Custom Hot Corners

# Set SSH Permissions
./ssh_permission.sh
eval "$(ssh-agent -s)"                              # run SSH agent in background
ssh-add ~/.ssh/key_personal                         # add key to agent
ssh-add ~/.ssh/key_work                             # add key to agent

# Install nvm
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# Source nvm script directly instead of the bashrc file
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

# Now install the latest LTS version of Node.js
nvm install --lts
```
9. `sudo -u ${INSTALL_USER} ./update.sh` - Update System
```bash
#!/bin/bash
sudo apt update
sudo dpkg --configure -a
sudo apt install -f -y
sudo apt upgrade -y
sudo apt dist-upgrade -y
sudo apt autoremove -y
sudo apt autoclean -y
sudo snap refresh
sudo flatpak update -y
sudo update-grub
```
10. Run Post-Restarted operations
```bash
#!/bin/bash

# Adding user to docker group
sudo groupadd docker
sudo usermod -aG docker $USER
```
11. asdf