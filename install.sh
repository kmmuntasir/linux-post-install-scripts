#!/bin/bash
#
# =====================================================================
# Elementary system setup script for Munna
# =====================================================================
# sudo apt-get install software-properties-gtk
# sudo -u munna ./test.sh
#
USER_NAME=$USER
# USER_NAME="munna"
# ---------------------------------------------------------------------
# Edit grub configuration and set wait time to 1 second
# ---------------------------------------------------------------------
sudo sed -i -e 's/GRUB_TIMEOUT=10/GRUB_TIMEOUT=1/g' /etc/default/grub

echo "=================================================="
echo "                 Increasing iNotify Limits"
echo "=================================================="

sudo sed -i "\$ a fs.inotify.max_user_watches = 1048576" /etc/sysctl.conf

sudo sysctl -p --system

echo "=================================================="
echo "                 Automount Drives"
echo "=================================================="

mkdir /home/$USER_NAME/speedo
mkdir /home/$USER_NAME/coder
mkdir /home/$USER_NAME/storage

SPEEDO_DISK="/dev/disk/by-uuid/36DD7F4070464003 /home/$USER_NAME/speedo auto nosuid,nodev,nofail,x-gvfs-show 0 0"
CODER_DISK="/dev/disk/by-uuid/0A5FC36165C5497D /home/$USER_NAME/coder auto nosuid,nodev,nofail,x-gvfs-show 0 0"
STORAGE_DISK="/dev/disk/by-uuid/5DD6F7AC23306F1C /home/$USER_NAME/storage auto nosuid,nodev,nofail,x-gvfs-show 0 0"

sudo sed -i "\$ a $SPEEDO_DISK" /etc/fstab
sudo sed -i "\$ a $CODER_DISK" /etc/fstab
sudo sed -i "\$ a $STORAGE_DISK" /etc/fstab

sudo mount /home/$USER_NAME/speedo/
sudo mount /home/$USER_NAME/coder/
sudo mount /home/$USER_NAME/storage/


echo "=================================================="
echo "               Moving backup files"
echo "=================================================="

sudo rm -rf /home/$USER_NAME/Documents
sudo rm -rf /home/$USER_NAME/Downloads
sudo rm -rf /home/$USER_NAME/Music
sudo rm -rf /home/$USER_NAME/Pictures
sudo rm -rf /home/$USER_NAME/Videos

# tar xf homeBackup.tar.gz -C /home/$USER_NAME/
cp -rf homeBackup/* /home/$USER_NAME/               # Normal Files/Folders
cp -rf homeBackup/.[^.]* /home/$USER_NAME/          # Hidden Files/Folders


echo "=================================================="
echo "               Adding Repositories"
echo "=================================================="

sudo add-apt-repository ppa:yunnxx/elementary -y 					                    # Wingpanel for SysTray
sudo add-apt-repository ppa:embrosyn/xapps -y						                    # Xapps for Xed
sudo add-apt-repository ppa:philip.scott/elementary-tweaks -y		                    # Elementary Tweaks
sudo add-apt-repository ppa:mikhailnov/pulseeffects -y				                    # Pulseeffects

wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add - 	# Sublime Text
sudo apt-get install apt-transport-https -y						                    # Sublime Text
echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list	# Sublime Text
sudo apt update

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
echo "               Restore SSH Keys"
echo "=================================================="

sudo chmod 755 ~/.ssh
sudo chmod 644 ~/.ssh/known_hosts
sudo chmod 600 ~/.ssh/id_rsa
sudo chmod 600 ~/.ssh/id_rsa.pub

eval "$(ssh-agent -s)"                              # run SSH agent in background
ssh-add ~/.ssh/id_rsa                               # add key to agent


echo "=================================================="
echo "               Installing Software"
echo "=================================================="

sudo apt-get install audacious -y
sudo apt-get install audacity -y
sudo apt-get install blueman -y
sudo apt-get install chromium-browser -y
sudo apt-get install clementine -y
sudo apt-get install codeblocks -y
sudo apt-get install baobab -y
sudo apt-get install elementary-tweaks -y
sudo apt-get install fceux -y
sudo apt-get install filezilla -y
sudo apt-get install firefox -y
sudo apt-get install gedit -y
sudo apt-get install gnome-clocks -y
sudo apt-get install gnome-disk-utility -y
sudo apt-get install gnome-mpv -y
sudo apt-get install gnome-system-monitor -y
sudo apt-get install gimp -y
sudo apt-get install git -y
sudo apt-get install gparted -y
sudo apt-get install hardinfo -y
sudo apt-get install htop -y
sudo apt-get install ibus-m17n ibus-gtk -y
sudo apt-get install indicator-application wingpanel-indicator-ayatana -y
sudo apt-get install kate -y
sudo apt-get install kylin-video -y
sudo apt-get install libreoffice -y
sudo apt-get install mplayer -y
sudo apt-get install mpv -y
sudo apt-get install mupdf -y
sudo apt-get install nautilus -y
sudo apt-get install neverball -y
sudo apt-get install obs-studio -y
sudo apt-get install p7zip-full p7zip-rar -y
sudo apt-get install parole -y
sudo apt-get install psensor -y
sudo apt-get install pulseaudio-module-bluetooth net-tools -y
sudo apt-get install pulseeffects -y
sudo apt-get install qbittorrent -y
sudo apt-get install qemu-kvm libvirt-bin ubuntu-vm-builder bridge-utils -y
sudo apt-get install qpdfview -y
sudo apt-get install simple-scan -y
sudo apt-get install skanlite -y
sudo apt-get install smplayer -y
sudo apt-get install snap snapd -y
sudo apt-get install stoken -y
sudo apt-get install sublime-text -y
sudo apt-get install synapse -y
sudo apt-get install synaptic -y
sudo apt-get install tlp tlp-rdw -y
sudo apt-get install ubuntu-restricted-extras -y
sudo apt-get install unrar -y
sudo apt-get install vlc -y
sudo apt-get install wine-stable -y
sudo apt-get install xed -y


echo "=================================================="
echo "               Enable SysTray Icons"
echo "=================================================="
sudo sed -i -e 's/OnlyShowIn=Unity;GNOME;/OnlyShowIn=Unity;GNOME;Pantheon;/g' /etc/xdg/autostart/indicator-application.desktop


echo "=================================================="
echo "               Enable KVM"
echo "=================================================="
sudo adduser $USER_NAME kvm
sudo adduser $USER_NAME libvirt

echo "=================================================="
echo "               Configure iBus"
echo "=================================================="
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('ibus', 'Unikey')]"


echo "=================================================="
echo "               Install Flutter, NodeJS"
echo "=================================================="
mkdir /home/$USER_NAME/bin

tar xf tarApps/node*.tar.xz -C /home/$USER_NAME/bin
tar xf tarApps/flutter*.tar.xz -C /home/$USER_NAME/bin

mv /home/$USER_NAME/bin/node* /home/$USER_NAME/bin/nodejs
mv /home/$USER_NAME/bin/flutter* /home/$USER_NAME/bin/flutter


DART_PATH="export PATH=\$PATH:/home/munna/bin/flutter/bin/cache/dart-sdk/bin"
FLUTTER_PATH="export PATH=\$PATH:/home/$USER_NAME/bin/flutter/bin"
PUB_CACHE_PATH="export PATH=\$PATH:/home/$USER_NAME/.pub-cache/bin"
NODEJS_PATH="export PATH=\$PATH:/home/$USER_NAME/bin/nodejs/bin"

sudo sed -i "\$ a $FLUTTER_PATH" /home/$USER_NAME/.bashrc
sudo sed -i "\$ a $DART_PATH" /home/$USER_NAME/.bashrc
sudo sed -i "\$ a $PUB_CACHE_PATH" /home/$USER_NAME/.bashrc
sudo sed -i "\$ a $NODEJS_PATH" /home/$USER_NAME/.bashrc


echo "=================================================="
echo "               Install .deb archives"
echo "=================================================="
sudo dpkg -i deb/*.deb
sudo apt install -f -y


echo "=================================================="
echo "               Run Shell Installers"
echo "=================================================="
sudo ./shInstallers/installXDM.sh


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

