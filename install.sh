#!/bin/bash
#
# =====================================================================
# Elementary system setup script
# =====================================================================
# sudo apt-get install software-properties-gtk
# sudo -u munna ./test.sh
#

echo "=================================================="
echo "                 Automount Drives"
echo "=================================================="

mkdir "$HOME/speedo"
mkdir "$HOME/coder"
mkdir "$HOME/storage"

SPEEDO_DISK="/dev/disk/by-uuid/36DD7F4070464003 $HOME/speedo auto nosuid,nodev,nofail,x-gvfs-show 0 0"
CODER_DISK="/dev/disk/by-uuid/0A5FC36165C5497D $HOME/coder auto nosuid,nodev,nofail,x-gvfs-show 0 0"
STORAGE_DISK="/dev/disk/by-uuid/5DD6F7AC23306F1C $HOME/storage auto nosuid,nodev,nofail,x-gvfs-show 0 0"

sudo sed -i "\$ a $SPEEDO_DISK" /etc/fstab
sudo sed -i "\$ a $CODER_DISK" /etc/fstab
sudo sed -i "\$ a $STORAGE_DISK" /etc/fstab

sudo mount "$HOME/speedo/"
sudo mount "$HOME/coder/"
sudo mount "$HOME/storage/"

echo "=================================================="
echo "               Creating Symlinks"
echo "=================================================="

sudo rm -rf "$HOME/Documents"
sudo rm -rf "$HOME/Downloads"
sudo rm -rf "$HOME/Music"
sudo rm -rf "$HOME/Pictures"
sudo rm -rf "$HOME/Videos"

ln -s "$HOME/coder/system/Desktop" "Desktop"
ln -s "$HOME/coder/system/Documents" "Documents"
ln -s "$HOME/coder/system/Downloads" "Downloads"
ln -s "$HOME/storage/music" "Music"
ln -s "$HOME/storage/movies" "Videos"
ln -s "$HOME/coder/apps/win_apps/others/Wallpaper" "Pictures"
ln -s "$HOME/speedo/localhost" "localhost"

echo "=================================================="
echo "               Moving backup files"
echo "=================================================="

# tar xf homeBackup.tar.gz -C $HOME/
cp -rf "homeBackup/*" "$HOME/"               # Normal Files/Folders
cp -rf "homeBackup/.[^.]*" "$HOME/"          # Hidden Files/Folders

echo "=================================================="
echo "               Adding Repositories"
echo "=================================================="

sudo add-apt-repository ppa:yunnxx/elementary -y 					                                       # Wingpanel for SysTray
sudo add-apt-repository ppa:embrosyn/xapps -y						                                                 # Xapps for Xed
sudo add-apt-repository ppa:philip.scott/elementary-tweaks -y		                                     # Elementary Tweaks
sudo add-apt-repository ppa:mikhailnov/pulseeffects -y				                                            # Pulseeffects

# Repo for Sublime Text
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
sudo apt-get install apt-transport-https -y
echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list

# Repo for Brave Browser
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list

sudo apt update

echo "=================================================="
echo "            Installing Apps from Repo"
echo "=================================================="

sudo apt install snap snapd -y

sudo apt install audacious -y
sudo apt install audacity -y
sudo apt install blueman -y
sudo apt install brave-browser -y
sudo apt install chromium-browser -y
sudo apt install clementine -y
sudo apt install codeblocks -y
sudo apt install baobab -y
sudo apt install elementary-tweaks -y
sudo apt install fceux -y
sudo snap install figma-linux
sudo apt install filezilla -y
sudo apt install firefox -y
sudo apt install gedit -y
sudo apt install gnome-clocks -y
sudo apt install gnome-disk-utility -y
sudo apt install gnome-mpv -y
sudo apt install gnome-system-monitor -y
sudo apt install gimp -y
sudo apt install git -y
sudo apt install gitk -y
sudo apt install gparted -y
sudo apt install hardinfo -y
sudo apt install htop -y
sudo apt install ibus-m17n ibus-gtk -y
sudo apt install indicator-application wingpanel-indicator-ayatana -y
sudo apt install kate -y
sudo apt install kodi -y
sudo apt install libreoffice -y
sudo apt install mpv -y
sudo apt install nautilus -y
sudo apt install obs-studio -y
sudo apt install psensor -y
sudo apt install pulseaudio-module-bluetooth net-tools -y
sudo apt install pulseeffects -y
sudo apt install qbittorrent -y
sudo apt install qemu-kvm libvirt-bin ubuntu-vm-builder bridge-utils -y
sudo apt install qpdfview -y
sudo apt install selene -y
sudo apt install skanlite -y
sudo snap install skype
sudo snap install slack --classic
sudo apt install smplayer -y
sudo apt install stoken -y
sudo apt install sublime-text -y
sudo apt install synapse -y
sudo apt install synaptic -y
sudo apt install ubuntu-restricted-extras -y
sudo apt install vlc -y
sudo snap install whatsdesk
sudo apt install wine-stable -y
sudo apt install xed -y


echo "=================================================="
echo "           Installing Apps from TarBall"
echo "=================================================="

mkdir "$HOME/bin"

echo "------------------- Flutter ----------------------"
tar xf "tarApps/node*.tar.xz" -C "$HOME/bin"
tar xf "tarApps/flutter*.tar.xz" -C "$HOME/bin"

echo "------------------- NodeJS -----------------------"
mv "$HOME/bin/node*" "$HOME/bin/nodejs"
mv "$HOME/bin/flutter*" "$HOME/bin/flutter"

echo "=================================================="
echo "               Install .deb archives"
echo "=================================================="
sudo dpkg -i deb/*.deb
sudo apt install -f -y

echo "=================================================="
echo "               Run Shell Installers"
echo "=================================================="
sudo ./shInstallers/installXDM.sh

# ---------------------------------------------------------------------
# Set Suspend to “Never”
# ---------------------------------------------------------------------
# sudo su
# su - -s /bin/bash lightdm
# dbus-launch gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type nothing
# dbus-launch gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0

# ---------------------------------------------------------------------
# Set Fixed Number of Workspaces
# ---------------------------------------------------------------------
# gsettings set org.pantheon.desktop.gala.behavior dynamic-workspaces false && gsettings set org.gnome.desktop.wm.preferences num-workspaces 12

echo "=================================================="
echo "               Enable SysTray Icons"
echo "=================================================="
sudo sed -i -e 's/OnlyShowIn=Unity;GNOME;/OnlyShowIn=Unity;GNOME;Pantheon;/g' /etc/xdg/autostart/indicator-application.desktop

echo "=================================================="
echo "               Configure iBus"
echo "=================================================="
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('ibus', 'Unikey')]"

echo "=================================================="
echo "              Update Grub Timeout"
echo "=================================================="
sudo sed -i -e 's/GRUB_TIMEOUT=10/GRUB_TIMEOUT=1/g' /etc/default/grub

echo "=================================================="
echo "                 Increasing iNotify Limits"
echo "=================================================="

sudo sed -i "\$ a fs.inotify.max_user_watches = 1048576" /etc/sysctl.conf
sudo sysctl -p --system

echo "=================================================="
echo "               Enable KVM"
echo "=================================================="
sudo adduser munna kvm
sudo adduser munna libvirt

echo "=================================================="
echo "               Restore SSH Keys"
echo "=================================================="

sudo chmod 755 ~/.ssh
sudo chmod 644 ~/.ssh/known_hosts
sudo chmod 600 ~/.ssh/id_rsa
sudo chmod 600 ~/.ssh/id_rsa.pub
sudo chmod 600 ~/.ssh/*.pem
sudo chmod 600 ~/.ssh/config

eval "$(ssh-agent -s)"                              # run SSH agent in background
ssh-add ~/.ssh/id_rsa                               # add key to agent

echo "=================================================="
echo "  Setting System Paths and Environment Variables"
echo "=================================================="

DART_PATH="export PATH=\$PATH:$HOME/bin/flutter/bin/cache/dart-sdk/bin"
FLUTTER_PATH="export PATH=\$PATH:$HOME/bin/flutter/bin"
PUB_CACHE_PATH="export PATH=\$PATH:$HOME/.pub-cache/bin"
NODEJS_PATH="export PATH=\$PATH:$HOME/bin/nodejs/bin"

sudo sed -i "\$ a $FLUTTER_PATH" "$HOME/.bashrc"
sudo sed -i "\$ a $DART_PATH" "$HOME/.bashrc"
sudo sed -i "\$ a $PUB_CACHE_PATH" "$HOME/.bashrc"
sudo sed -i "\$ a $NODEJS_PATH" "$HOME/.bashrc"
pub global activate fvm

sudo sed -i "\$ a export SDK_REGISTRY_TOKEN='sk.eyJ1Ijoic2hhYmJpcmtsbiIsImEiOiJja3BjNmFubGcxYXp5Mm5wN2hxaDk1bHkyIn0.XdjIaL3TD0NvNpeIPcH4nA'" "$HOME/.bashrc"

echo "=================================================="
echo "             Update and Upgrade System"
echo "=================================================="

sudo apt update
sudo dpkg --configure -a
sudo apt install -f -y
sudo apt upgrade -y
sudo apt dist-upgrade -y
sudo apt autoremove -y
sudo apt autoclean -y
sudo update-grub

echo "=================================================="
echo "                   REBOOT System"
echo "=================================================="

sudo reboot

# ---------------------------------------------------------------------
# END of Script
# ---------------------------------------------------------------------

