#!/bin/bash
#
# =====================================================================
# Elementary system reset script for Munna
# =====================================================================
#
# sudo -u munna ./test.sh

# Resetting Grub
# sudo sed -i -e 's/GRUB_TIMEOUT=1/GRUB_TIMEOUT=10/g' /etc/default/grub

echo "=================================================="
echo "             Removing Backup Files"
echo "=================================================="

sudo rm "$HOME/Desktop"
sudo rm "$HOME/Documents"
sudo rm "$HOME/Downloads"
sudo rm "$HOME/Music"
sudo rm "$HOME/Pictures"
sudo rm "$HOME/Videos"
sudo rm "$HOME/localhost"
sudo rm -rf "$HOME/launchers"
sudo rm "$HOME/Templates/*"

mkdir "$HOME/Documents"
mkdir "$HOME/Downloads"
mkdir "$HOME/Music"
mkdir "$HOME/Pictures"
mkdir "$HOME/Videos"

sudo rm "$HOME/*.txt"
sudo rm "$HOME/*.sh"
sudo rm "$HOME/.gitconfig"
sudo rm "$HOME/.git-credentials"

sudo rm -rf "$HOME/.config/qBittorrent"
sudo rm -rf "$HOME/.fonts"
sudo rm -rf "$HOME/.local/share/data/qBittorrent"
sudo rm -rf "$HOME/.ssh"

echo "=================================================="
echo "             Disabling Automount of Drives"
echo "=================================================="

sudo sed -i -e "s/\/dev\/disk\/by-uuid\/36DD7F4070464003 \/home\/munna\/speedo auto nosuid,nodev,nofail,x-gvfs-show 0 0//g" /etc/fstab
sudo sed -i -e "s/\/dev\/disk\/by-uuid\/0A5FC36165C5497D \/home\/munna\/coder auto nosuid,nodev,nofail,x-gvfs-show 0 0//g" /etc/fstab
sudo sed -i -e "s/\/dev\/disk\/by-uuid\/5DD6F7AC23306F1C \/home\/munna\/storage auto nosuid,nodev,nofail,x-gvfs-show 0 0//g" /etc/fstab

echo "=================================================="
echo "                Unmounting Drives"
echo "=================================================="
sudo umount "$HOME/speedo"
sudo umount "$HOME/coder"
sudo umount "$HOME/storage"

sudo rm -rf "$HOME/speedo"
sudo rm -rf "$HOME/coder"
sudo rm -rf "$HOME/storage"

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
sudo apt autoremove brave-browser -y
sudo apt-get autoremove chromium-browser -y
sudo apt-get autoremove clementine -y
sudo apt-get autoremove codeblocks -y
sudo apt-get autoremove baobab -y
sudo apt-get autoremove dingtalk -y
sudo apt-get autoremove elementary-tweaks-y
sudo apt-get autoremove fceux -y
sudo snap remove figma-linux
sudo apt-get autoremove filezilla -y
sudo apt-get autoremove firefox -y
sudo apt-get autoremove gedit -y
sudo apt-get autoremove gnome-clocks -y
sudo apt-get autoremove gnome-disk-utility -y  
sudo apt-get autoremove gnome-mpv -y
sudo apt-get autoremove gnome-system-monitor -y
sudo apt-get autoremove gimp -y
sudo apt-get autoremove git -y
sudo apt autoremove gitk -y
sudo apt-get autoremove gparted -y
sudo apt-get autoremove hardinfo -y
sudo apt-get autoremove htop -y
sudo apt-get autoremove ibus-m17n ibus-gtk -y
sudo apt-get autoremove indicator-application wingpanel-indicator-ayatana -y
sudo apt-get autoremove kate -y
sudo apt autoremove kodi -y
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
sudo apt-get autoremove mpv -y
sudo apt-get autoremove mupdf -y
sudo apt-get autoremove nautilus -y
sudo apt-get autoremove obs-studio -y
sudo apt-get autoremove p7zip-full p7zip-rar -y
sudo apt-get autoremove psensor -y
sudo apt-get autoremove pulseaudio-module-bluetooth net-tools -y
sudo apt-get autoremove pulseeffects -y
sudo apt-get autoremove qbittorrent -y
sudo apt-get autoremove qemu-kvm libvirt-bin ubuntu-vm-builder bridge-utils -y
sudo apt-get autoremove qpdfview -y
sudo apt autoremove selene -y
sudo apt-get autoremove skanlite -y
sudo snap remove skype
sudo snap remove slack
sudo apt-get autoremove smplayer -y
sudo apt-get autoremove snap snapd -y
sudo apt-get autoremove stoken -y
sudo apt-get autoremove sublime-text -y
sudo apt-get autoremove synapse -y
sudo apt-get autoremove synaptic -y
sudo apt-get autoremove tlp tlp-rdw -y
sudo apt-get autoremove ubuntu-restricted-extras -y
sudo apt-get autoremove vlc -y
sudo snap remove whatsdesk
sudo apt-get autoremove wine-stable -y
sudo apt-get autoremove xed -y

echo "=================================================="
echo "             Removing Flutter, NodeJS"
echo "=================================================="

sudo rm -rf "$HOME/bin"
sudo sed -i -e "s/export PATH=\$PATH:\/home\/munna\/bin\/flutter\/bin\/cache\/dart-sdk\/bin//g" "$HOME/.bashrc"
sudo sed -i -e "s/export PATH=\$PATH:\/home\/munna\/bin\/flutter\/bin//g" "$HOME/.bashrc"
sudo sed -i -e "s/export PATH=\$PATH:\/home\/munna\/.pub-cache\/bin//g" "$HOME/.bashrc"
sudo sed -i -e "s/export PATH=\$PATH:\/home\/munna\/bin\/nodejs\/bin//g" "$HOME/.bashrc"
sudo sed -i -e "s/export SDK_REGISTRY_TOKEN='sk.eyJ1Ijoic2hhYmJpcmtsbiIsImEiOiJja3BjNmFubGcxYXp5Mm5wN2hxaDk1bHkyIn0.XdjIaL3TD0NvNpeIPcH4nA'//g" "$HOME/.bashrc"


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

