#!/bin/bash
## Restore script for my i3 configuration

echo "cloning backup repo"

cd ~

touch .gitignore

echo ".cfg" >> .gitignore

git clone --bare -b Linux-i3 https://github.com/josevega96/dotfiles $HOME/.cfg

echo "Setting up bare git repo"

 echo "found .bashrc writing bareconf alias"

 echo "# bare alias" >> .bashrc

 echo "alias bareconf='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'" >> .bashrc

 /usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME checkout

 /usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME config --local status.showUntrackedFiles no

echo "you can now access your home repository using \"bareconf\""

echo "requesting sudo access you only need to type tour password once"

sudo sh -c "echo 'Defaults        timestamp_timeout=-1' >> /etc/sudoers"

echo "enabling multilib repos"

sudo sed -i 's/#\[multilib]/\[multilib]/g' /etc/pacman.conf

sudo sed -i '93s|#Include = /etc/pacman.d/mirrorlist|Include = /etc/pacman.d/mirrorlist|g'  /etc/pacman.conf

echo "updating pacman database" 

sudo pacman -Sy

echo "installing all packages found in .config/pkgbabackup/pkglist.txt"

sudo pacman -S --needed - < /home/$USER/.config/pkgbackup/pkglist.txt

echo "creating user dirs"

xdg-user-dirs-update

echo "removing packages that may cause issues"

sed -i '/edopro-bin/d' .config/pkgbackup/pkglist-aur.txt 

sed -i '/packettracer/d' .config/pkgbackup/pkglist-aur.txt

echo "installing yay"

git clone https://aur.archlinux.org/yay.git ~/yay 

cd ~/yay 

makepkg -si

cd 

rm -rf yay

echo "installing all packages from the AUR"

yay -S --needed  - < /home/$USER/.config/pkgbackup/pkglist-aur.txt

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

sudo sh -c "echo '[Unit] 
Description=Pacman mirrorlist update 
Wants=network-online.target 
After=network-online.target 

[Service] 
Type=oneshot ExecStart=/usr/bin/reflector --protocol https --latest 30 --number 20 --sort rate --save /etc/pacman.d/mirrorlist

[Install] 
RequiredBy=multi-user.target' >> /etc/systemd/system/reflector.service"

touch /etc/systemd/system/reflector.timer

sudo sh -c "echo '[Unit] 
Description=Run reflector weekly 

[Timer] 
OnCalendar=Mon *-*-* 7:00:00 
RandomizedDelaySec=15h 
Persistent=true 

[Install] 
WantedBy=timers.target' >>  /etc/systemd/system/reflector.timer"


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

echo"copyinng polybar fonts"

sudo cp -r ~/.config/polybar/fonts/* /usr/share/fonts/

echo "Removing extra software"

sudo rm -rf /sbin/blocks

sudo rm -rf /sbin/fluid

sudo rm -rf /sbin/sudoku

sudo rm -rf /sbin/checkers

sudo rm -rf /sbin/lstopo


echo "ading user $USER to the video group"

sudo usermod -a -G video $USER

echo "enabling all necessary systemd services"

sudo systemctl enable ly.service 

sudo systemctl enable libvirt.service 

sudo systemctl enable reflector.timer

sudo systemctl enable mpd.service

sudo sed -i '/Defaults        timestamp_timeout=-1/d' /etc/sudoers

echo "finished installing rebooting"

sleep 3

reboot
