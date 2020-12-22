# !/bin/bash
##
#Script to update all components in a OC based efi
##


get_tag(){
    
    curl -s  $1 | grep tag-list | head -1 | cut -f2 -d "&" | cut -f2 -d "="

}

menu(){
    count=0
    name=()
    name[0]='hello'
    echo 'Please select the Release Candidate you want to download'
    while [[ -n ${name[$count]} ]]
    do 
         let count=count+1
         name[$count]=$(curl -s $1 | grep download | grep $2 | cut -f2 -d '"'|cut -f7 -d '/' | sed -n "$count,$count p")
         if [[ -n ${name[$count]} ]];
         then
            echo -e "$count \c"
            echo ${name[$count]}
         fi
    done

    read opc

}

git_down(){

    wget -q --show-progress --progress=bar:force $1/download/$2/${name[$opc]} 

    unzip -q  ${name[$opc]} -d $3 

    rm ${name[$opc]}


}

links=(
    'https://github.com/acidanthera/OpenCorePkg/releases'
    'https://github.com/OpenIntelWireless/itlwm/releases'
    'https://github.com/CloverHackyColor/FakeSMC3_with_plugins/releases'
    'https://github.com/OpenIntelWireless/IntelBluetoothFirmware/releases'
    'https://github.com/OpenIntelWireless/IntelBluetoothFirmware/releases'
    'https://github.com/acidanthera/IntelMausi/releases'
    'https://github.com/acidanthera/Lilu/releases'
    'https://github.com/Sniki/OS-X-USB-Inject-All/releases'
    'https://github.com/acidanthera/WhateverGreen/releases')

names=(
    'OpenCore'
    'AirportItlwm'
    'FakeSMC'
    'IntelBluetoothFirmware'
    'IntelBluetoothInjector'
    'IntelMausi'
    'Lilu'
    'USBInjectAll'
    'WhateverGreen'
)

drivers=(
    'OpenRuntime.efi'
    'Ps2KeyboardDxe.efi'
    'Ps2MouseDxe.efi'

)

count2=0

echo 'setting up working directory'

mkdir -p oc_update

cd oc_update

while [[ -n ${links[$count2]} ]]
do
    echo "Fetching latest ${names[$count2]} release from git"
    tag=$(get_tag ${links[$count2]})
    echo "detected latest version $tag searching for candidates"
    menu ${links[$count2]} $tag
    echo "Downloading ${name[$opc]}"
    git_down ${links[$count2]} $tag ${names[$count2]}
    let count2=count2+1
done

echo -e 'Please Insert the directory of your efi: \c'

read dir

echo "Copying OpenCore files to efi directory"

cp -ri OpenCore/X64/EFI/BOOT/BOOTx64.efi $dir/EFI/BOOT

cp -ri OpenCore/X64/EFI/OC/OpenCore.efi $dir/EFI/OC/



count2=0

while [[ -n ${drivers[$count2]} ]]
do
    echo "Copying ${drivers[$count2]} to efi"
    cp -ri OpenCore/X64/EFI/OC/Drivers/${drivers[count2]} $dir/EFI/OC/Drivers/
    let count2=count2+1
done


count2=1

while [[ -n ${names[$count2]} ]]
do
    echo "Copying ${names[$count2]} to efi"
    kdir=""${names[$count2]}"/"${names[$count2]}".kext"
    if [ -d  $kdir ];
    then
        cp -r ${names[count2]}/${names[count2]}.kext $dir/EFI/OC/Kexts/
        let count2=count2+1
    else
        cd ${names[$count2]}
        subd=$(grep -ril .kext| head -1 | cut -f1 -d "/")
        cd ..
        cp -r ${names[count2]}/"$subd"/${names[count2]}*.kext $dir/EFI/OC/Kexts/
        let count2=count2+1
    fi
done

echo "copying done, script will stay on standby until you finish upating your sample.plist once youre done you can press enter to delete the working directory"

read $wait

echo "Deleting working directory"

cd ..

rm -rf oc_update

echo "The process is finished have a nice day :)"