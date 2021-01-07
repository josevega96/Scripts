# !/bin/bash
##
#script to change through different kernels
##

echo "detecting current kernel"

current=$(uname -r)
kernels=()
count=0

if [[ $current == *"arch"* ]]
then
	echo "stock kernel detected"
	original='linux-arch'
fi

if [[ $current == *"lts"* ]]
then
	echo "lts kernel detected"
	original='linux-lts'
fi

if [[ $current == *"zen"* ]]
then
	echo "zen kernel detected"
	original='linux-zen'
fi

if [[ $current == *"clear"* ]]
then
	echo "clear kernel detected"
	original='linux-clear'
	count=$((count+=1))
fi

echo 'detecting other installed kernels'

if [ -f "/boot/vmlinuz-linux-arch" ]
then
	echo 'stock kernel is installed'
	kernels[count]="linux-arch"
	count=$((count+1))
fi

if [ -f "/boot/vmlinuz-linux-lts" ]
then
	echo 'lts kernel is installed'
	kernels[count]="linux-lts"
	count=$((count+1))
fi

if [ -f "/boot/vmlinuz-linux-zen" ]
then
	echo 'zen kernel is installed'
	kernels[count]="linux-zen"
	count=$((count+1))
fi

if [ -f "/boot/vmlinuz-linux-clear" ]
then
	echo 'clear kernel is installed'
	kernels[count]="linux-clear"
	count=$((count+1))
fi



echo 'to which kernel do you want to change'

count2=0

while [ $count2 -lt $count ]; do
    if [[ -n ${kernels[$count2]} ]];
    then
	    echo -e "$count2 \c"
	    echo ${kernels[$count2]}
    fi
	let count2=count2+1
done

read sel

change=${kernels[$sel]}

echo "$change selected"

echo "changing kernel"

sudo sed -i "s|$original|$change|g" /boot/EFI/CLOVER/config.plist
