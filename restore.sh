#!/bin/bash
## Restore script for my i3 configuration

echo "cloning backup repo"

cd ~

touch .gitignore

echo ".cfg" >> .gitignore

git clone --bare -b Linux-qtile https://github.com/josevega96/dotfiles $HOME/.cfg

echo "Setting up bare git repo" 

echo "found .bashrc writing bareconf alias"

echo "# bare alias" >> .bashrc

echo "alias bareconf='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'" >> .bashrc

/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME checkout

/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME config --local status.showUntrackedFiles no

echo "you can now access your home repository using \"bareconf\""

echo "requesting sudo access you only need to type your password once"

sudo sh -c "echo 'Defaults        timestamp_timeout=-1' >> /etc/sudoers"

echo "enabling multilib repos"

sudo sed -i 's/#\[multilib]/\[multilib]/g' /etc/pacman.conf

sudo sed -i '93s|#Include = /etc/pacman.d/mirrorlist|Include = /etc/pacman.d/mirrorlist|g'  /etc/pacman.conf

echo "updating pacman database" 

sudo pacman -Sy

echo "installing all packages found in .config/pkgbabackup/pkglist.txt"

sudo pacman -S --needed --noconfirm - < /home/$USER/.config/pkgbackup/pkglist.txt

echo "creating user dirs"

xdg-user-dirs-update

mkdir -p ~/.vim/undodir 

echo "removing packages that may cause issues"

sed -i '/edopro-bin/d' .config/pkgbackup/pkglist-aur.txt 

echo "installing yay"

git clone https://aur.archlinux.org/yay.git ~/yay 

cd ~/yay 

makepkg -si --noconfirm 

cd 

rm -rf yay

echo "importing gpg keys manually"

gpg --keyserver pool.sks-keyservers.net --recv-keys FCF986EA15E6E293A5644F10B4322F04D67658D8

gpg --keyserver keys.gnupg.net --recv-keys C52048C0C0748FEE227D47A2702353E0F7E48EDB

#spotify

gpg --keyserver hkp://keyserver.ubuntu.com --receive-keys 931FF8E79F0876134EDDBDCCA87FF9DF48BF1C90

gpg --keyserver hkp://keyserver.ubuntu.com --receive-keys 2EBF997C15BDA244B6EBF5D84773BD5E130D1D45

curl -sS https://download.spotify.com/debian/pubkey_0D811D58.gpg | gpg --import -

echo "installing all packages from the AUR"

yay -S --needed --noconfirm - < /home/$USER/.config/pkgbackup/pkglist-aur.txt

echo "creating pacman hook for pkgbackup"

sudo mkdir -p /etc/pacman.d/hooks

echo "[Trigger]
 Operation = Install 
Operation = Remove 
Type = Package 
Target = *

[Action] 
When = PostTransaction 
Exec = /bin/sh -c '/usr/bin/pacman -Qqen > /home/$USER/.config/pkgbackup/pkglist.txt'" | sudo tee /etc/pacman.d/hooks/pkgbackup.hook


echo "[Trigger]
 Operation = Install 
Operation = Remove 
Type = Package 
Target = *

[Action] 
When = PostTransaction 
Exec = /bin/sh -c '/usr/bin/pacman -Qqem > /home/$USER/.config/pkgbackup/pkglist-aur.txt'" | sudo tee /etc/pacman.d/hooks/pkgbackup-aur.hook

echo "setting up reflector" 

sudo sed -i 's|age|rate|g' /etc/xdg/reflector/reflector.conf 

sudo sed -i 's|5|20|g' /etc/xdg/reflector/reflector.conf

echo 'configuring btrfs-snapshot'

sudo mkdir -p /.snapshots/{root,home}

echo "[Trigger]
Operation = Install 
Operation = Upgrade
Operation = Remove 
Type = Package 
Target = *

[Action] 
When = PreTransaction 
Exec = /bin/sh -c '/sbin/btrfs-snapshot -f -c /etc/btrfs-snapshot/root.conf'" | sudo tee /etc/pacman.d/hooks/btrfs-snapshot.hook

echo '# vim: set ft=sh:
SUBVOL=/
DEST=/.snapshots/root
NKEEP=5' | sudo tee /etc/btrfs-snapshot/root.conf

echo '# vim: set ft=sh:
SUBVOL=/home
DEST=/.snapshots/home
NKEEP=5' | sudo tee /etc/btrfs-snapshot/home.conf

echo '/* Allow members of the wheel group to execute the defined actions 
 * without password authentication, similar to "sudo NOPASSWD:"
 */
polkit.addRule(function(action, subject) {
    if ((action.id == "org.libvirt.unix.manage") &&
        subject.isInGroup("wheel"))
    {
        return polkit.Result.YES;
    }
});'| sudo tee /etc/polkit-1/rules.d/49-nopasswd_limited.rules

sudo mkdir /media

echo '# UDISKS_FILESYSTEM_SHARED
# ==1: mount filesystem to a shared directory (/media/VolumeName)
# ==0: mount filesystem to a private directory (/run/media/$USER/VolumeName)
# See udisks(8)
ENV{ID_FS_USAGE}=="filesystem|other|crypto", ENV{UDISKS_FILESYSTEM_SHARED}="1"'| sudo tee /etc/udev/rules.d/99-udisks2.rules 

echo "preparing to setup bluetooth"

sudo sed -i "s|#DiscoverableTimeout\s=\s0|DiscoverableTimeout\ =\ 0\nDiscoverable\ =\ 0\n|g"  /etc/bluetooth/main.conf

sudo sed -i "\$a###Load\ Bluetooth\ Modules###\nload-module module-bluetooth-policy\nload-module module-bluetooth-discover" /etc/pulse/system.pa

sudo sed -i "\$a#automatically\ switch\ to\ newly-conected\ devices\nload-module module-switch-on-connect" /etc/pulse/default.pa

sudo sed -i "s|#bluez5.msbc-support|bluez5.msbc-support|g" /etc/pipewire/media-session.d/bluez-monitor.conf



echo "preparing to setup keyboad for x please type your keyboard layout"

read kb_lay

echo "Section \"InputClass\" 
Identifier \"system-keyboard\" 
MatchIsKeyboard \"on\" 
Option \"XkbLayout\" \"$kb_lay\" 
Option \"XkbModel\" \"pc104\" 
Option \"XkbVariant\" \",qwerty\" 
Option \"XkbOptions\" \"grp:alt_shift_toggle\" 
EndSection " | sudo tee  /etc/X11/xorg.conf.d/00-keyboard.conf

echo "setting up automatic timezone"

echo '#!/bin/sh                                 
case "$2" in
    up)
        timedatectl set-timezone "$(curl --fail https://ipapi.co/timezone)"
    ;;
esac' | sudo tee /etc/NetworkManager/dispatcher.d/09-timezone.sh

sudo chown root:root /etc/NetworkManager/dispatcher.d/09-timezone.sh

sudo chmod 755 /etc/NetworkManager/dispatcher.d/09-timezone.sh

echo  "Install oh-my-zsh and set zsh as the default shell? (y/n) "

echo

read reply

echo 

if [[ $reply =~ ^[Yy]$ ]]
then
    echo "installing oh-my-zsh"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    /usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME restore ~/.zshrc
    sudo usermod --shell $(which zsh) $USER
    
fi

echo "Removing extra software"

sudo rm -rf /sbin/blocks

sudo rm -rf /sbin/fluid

sudo rm -rf /sbin/sudoku

sudo rm -rf /sbin/checkers

sudo rm -rf /sbin/lstopo


echo "ading user $USER to the video group"

sudo usermod -a -G video,wheel $USER

echo "enabling all necessary systemd services"

sudo systemctl enable ly.service 

sudo systemctl enable libvirtd.service 

sudo systemctl enable reflector.timer

sudo systemctl enable mpd.service

sudo sed -i '/Defaults        timestamp_timeout=-1/d' /etc/sudoers

echo "finished installing rebooting"

sleep 3

reboot
