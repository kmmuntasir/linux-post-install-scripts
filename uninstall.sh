#!/bin/bash
#
# =====================================================================
# Elementary system reset script for Munna
# =====================================================================
#
# sudo -u munna ./test.sh

USER_NAME=$USER
# USER_NAME="munna"


# Resetting Grub
# sudo sed -i -e 's/GRUB_TIMEOUT=1/GRUB_TIMEOUT=10/g' /etc/default/grub

echo "=================================================="
echo "             Removing Backup Files"
echo "=================================================="

sudo rm /home/$USER_NAME/Desktop
sudo rm /home/$USER_NAME/Documents
sudo rm /home/$USER_NAME/Downloads
sudo rm /home/$USER_NAME/Music
sudo rm /home/$USER_NAME/Pictures
sudo rm /home/$USER_NAME/Videos
sudo rm /home/$USER_NAME/localhost
sudo rm /home/$USER_NAME/Templates/*

mkdir /home/$USER_NAME/Documents
mkdir /home/$USER_NAME/Downloads
mkdir /home/$USER_NAME/Music
mkdir /home/$USER_NAME/Pictures
mkdir /home/$USER_NAME/Videos

sudo rm -rf /home/$USER_NAME/launchers

sudo rm /home/$USER_NAME/*.txt
sudo rm /home/$USER_NAME/*.sh
sudo rm /home/$USER_NAME/.gitconfig
sudo rm /home/$USER_NAME/.git-credentials

sudo rm -rf /home/$USER_NAME/.config/chromium
sudo rm -rf /home/$USER_NAME/.config/google-chrome
sudo rm -rf /home/$USER_NAME/.config/qBittorrent
sudo rm -rf /home/$USER_NAME/.fonts
sudo rm -rf /home/$USER_NAME/.icons
sudo rm -rf /home/$USER_NAME/.local/share/data/qBittorrent
sudo rm -rf /home/$USER_NAME/.mozilla
sudo rm -rf /home/$USER_NAME/.ssh

echo "=================================================="
echo "             Disabling Automount of Drives"
echo "=================================================="

sudo sed -i -e "s/\/dev\/disk\/by-uuid\/36DD7F4070464003 \/home\/$USER_NAME\/speedo auto nosuid,nodev,nofail,x-gvfs-show 0 0//g" /etc/fstab
sudo sed -i -e "s/\/dev\/disk\/by-uuid\/0A5FC36165C5497D \/home\/$USER_NAME\/coder auto nosuid,nodev,nofail,x-gvfs-show 0 0//g" /etc/fstab
sudo sed -i -e "s/\/dev\/disk\/by-uuid\/5DD6F7AC23306F1C \/home\/$USER_NAME\/storage auto nosuid,nodev,nofail,x-gvfs-show 0 0//g" /etc/fstab

echo "=================================================="
echo "                Unmounting Drives"
echo "=================================================="
sudo umount /home/$USER_NAME/speedo
sudo umount /home/$USER_NAME/coder
sudo umount /home/$USER_NAME/storage

sudo rm -rf /home/$USER_NAME/speedo
sudo rm -rf /home/$USER_NAME/coder
sudo rm -rf /home/$USER_NAME/storage

echo "=================================================="
echo "               Removing Repositories"
echo "=================================================="
sudo add-apt-repository --remove ppa:yunnxx/elementary -y
sudo add-apt-repository --remove ppa:embrosyn/xapps -y
sudo add-apt-repository --remove ppa:philip.scott/elementary-tweaks -y
sudo add-apt-repository --remove ppa:mikhailnov/pulseeffects -y


# Disable SysTray Icons
# sudo sed -i -e 's/OnlyShowIn=Unity;GNOME;Pantheon;/OnlyShowIn=Unity;GNOME;/g' /etc/xdg/autostart/indicator-application.desktop

echo "=================================================="
echo "               Uninstalling Software"
echo "=================================================="

sudo apt-get autoremove audacious -y
sudo apt-get autoremove audacity -y
sudo apt-get autoremove blueman -y
sudo apt-get autoremove chromium-browser -y
sudo apt-get autoremove clementine -y
sudo apt-get autoremove codeblocks -y
sudo apt-get autoremove baobab -y
sudo apt-get autoremove elementary-tweaks-y  
sudo apt-get autoremove fceux -y
sudo apt-get autoremove filezilla -y
sudo apt-get autoremove firefox -y
sudo apt-get autoremove gedit -y
sudo apt-get autoremove gnome-clocks -y
sudo apt-get autoremove gnome-disk-utility -y  
sudo apt-get autoremove gnome-mpv -y
sudo apt-get autoremove gnome-system-monitor -y
sudo apt-get autoremove gimp -y
sudo apt-get autoremove git -y
sudo apt-get autoremove gparted -y
sudo apt-get autoremove hardinfo -y
sudo apt-get autoremove htop -y
sudo apt-get autoremove ibus-m17n ibus-gtk -y
sudo apt-get autoremove indicator-application wingpanel-indicator-ayatana -y
sudo apt-get autoremove kate -y
sudo apt-get autoremove kylin-video -y
sudo apt-get autoremove libreoffice -y
sudo apt-get autoremove libreoffice-base -y
sudo apt-get autoremove libreoffice-core -y
sudo apt-get autoremove libreoffice-report-builder-bin -y
sudo apt-get autoremove libreoffice-style-tango -y
sudo apt-get autoremove libreoffice-base-core -y
sudo apt-get autoremove libreoffice-java-common -y
sudo apt-get autoremove libreoffice-sdbc-hsqldb -y
sudo apt-get autoremove libreoffice-writer -y
sudo apt-get autoremove libreoffice-base-drivers -y
sudo apt-get autoremove libreoffice-math -y
sudo apt-get autoremove libreoffice-sdbc-postgresql -y
sudo apt-get autoremove libreoffice-common -y
sudo apt-get autoremove libreoffice-report-builder -y
sudo apt-get autoremove libreoffice-style-galaxy -y
sudo apt-get autoremove mplayer -y
sudo apt-get autoremove mpv -y
sudo apt-get autoremove mupdf -y
sudo apt-get autoremove nautilus -y
sudo apt-get autoremove neverball -y
sudo apt-get autoremove obs-studio -y
sudo apt-get autoremove p7zip-full p7zip-rar -y
sudo apt-get autoremove parole -y
sudo apt-get autoremove psensor -y
sudo apt-get autoremove pulseaudio-module-bluetooth net-tools -y
sudo apt-get autoremove pulseeffects -y
sudo apt-get autoremove qbittorrent -y
sudo apt-get autoremove qemu-kvm libvirt-bin ubuntu-vm-builder bridge-utils -y
sudo apt-get autoremove qpdfview -y
sudo apt-get autoremove simple-scan -y
sudo apt-get autoremove skanlite -y
sudo apt-get autoremove smplayer -y
sudo apt-get autoremove snap snapd -y
sudo apt-get autoremove stoken -y
sudo apt-get autoremove sublime-text -y
sudo apt-get autoremove synapse -y
sudo apt-get autoremove synaptic -y
sudo apt-get autoremove tlp tlp-rdw -y
sudo apt-get autoremove ubuntu-restricted-extras -y
sudo apt-get autoremove unrar -y
sudo apt-get autoremove vlc -y
sudo apt-get autoremove wine-stable -y
sudo apt-get autoremove xed -y

echo "=================================================="
echo "             Removing Flutter, NodeJS"
echo "=================================================="

sudo rm -rf /home/$USER_NAME/bin
sudo sed -i -e "s/export PATH=\$PATH:\/home\/$USER_NAME\/bin\/flutter\/bin\/cache\/dart-sdk\/bin//g" /home/$USER_NAME/.bashrc
sudo sed -i -e "s/export PATH=\$PATH:\/home\/$USER_NAME\/bin\/flutter\/bin//g" /home/$USER_NAME/.bashrc
sudo sed -i -e "s/export PATH=\$PATH:\/home\/$USER_NAME\/.pub-cache\/bin//g" /home/$USER_NAME/.bashrc
sudo sed -i -e "s/export PATH=\$PATH:\/home\/$USER_NAME\/bin\/nodejs\/bin//g" /home/$USER_NAME/.bashrc


echo "=================================================="
echo "             Uninstalling deb archives"
echo "=================================================="
sudo apt-get autoremove code -y
sudo apt-get autoremove dropbox -y
sudo apt-get autoremove figma-linux -y
sudo apt-get autoremove google-chrome-stable -y
sudo apt-get autoremove skypeforlinux -y
sudo apt-get autoremove slack-desktop -y
sudo apt-get autoremove teamviewer -y
sudo apt-get autoremove whatsapp-webapp -y
sudo apt-get autoremove wps-office -y
sudo apt-get autoremove zoom -y

echo "=================================================="
echo "                Uninstalling XDman"
echo "=================================================="
sudo rm /usr/bin/xdman
sudo rm /usr/share/applications/xdman.desktop
sudo rm -r /opt/xdman

echo "=================================================="
echo "             Update and Upgrade System"
echo "=================================================="

sudo apt update
sudo dpkg --configure -a
sudo apt install -f -y
sudo apt upgrade -y
sudo apt dist-upgrade -y
sudo apt autoremove -y
sudo update-grub


echo "=================================================="
echo "                   REBOOT System"
echo "=================================================="

# sudo reboot

# ---------------------------------------------------------------------
# END of Script
# ---------------------------------------------------------------------

