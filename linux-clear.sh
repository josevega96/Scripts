# !/bin/bash
## script to automate the linux-clear building process


echo 'disabling sudo timeout'

sudo sh -c "echo 'Defaults        timestamp_timeout=-1' >> /etc/sudoers"

echo 'Fetching lastest linux-clear release from the aur' 

git clone https://aur.archlinux.org/linux-clear.git linux-clear

cd linux-clear

echo 'choose the sub arch you want to use'

sed -n 16,48p PKGBUILD

read sel 

sed -i "s|_subarch=33|_subarch=$sel|g" PKGBUILD

echo 'building kernel'

makepkg -sir --noconfirm

echo 'installation finished, deleting build directory and reenabling sudo timeout'

cd ..

rm -rf linux-clear 

sudo sed -i '/Defaults        timestamp_timeout=-1/d' /etc/sudoers
