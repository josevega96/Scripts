# !/bin/bash
##
#Script to update all components in a atmosphere
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

    if [ -f *.zip ];
    then
        unzip -q  ${name[$opc]} -d $3   
        rm ${name[$opc]}
    else
        mkdir $3
        mv ${name[$opc]} $3
    fi


}

links=(
    'https://github.com/CTCaer/hekate/releases'
    'https://github.com/Atmosphere-NX/Atmosphere/releases'
    'https://github.com/Atmosphere-NX/Atmosphere/releases'
    'https://github.com/ITotalJustice/patches/releases'
    'https://github.com/shchmue/Lockpick_RCM/releases'
    'https://github.com/FlagBrew/Checkpoint/releases'
    'https://github.com/mtheall/ftpd/releases'
    'https://github.com/exelix11/SwitchThemeInjector/releases'
    'https://github.com/joel16/NX-Shell/releases'
    'https://github.com/fortheusers/hb-appstore/releases'
    'https://github.com/cathery/sys-con/releases'
    'https://github.com/Huntereb/Awoo-Installer/releases'
)

names=(
    'Hekate'
    'Atmosphere'
    'fusee'
    'SigPatches'
    'Lockpick_RCM'
    'Checkpoint'
    'ftpd'
    'NXThemesInstaller'
    'NX-Shell'
    'appstore'
    'sys-con'
    'awoo-installer'

)

count2=0

echo 'setting up working directory'

mkdir -p switch_update

cd switch_update

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

echo -e 'Please Insert the directory of your sdcard: \c'

read dir

count2=0

echo 'moving hekate payload to the root of the work directory'

mv Hekate/*.bin ../switch_update/

while [[ -n ${names[$count2]} ]]
do
    if [ -f ${names[$count2]}/${names[$count2]}.nro ];
    then
        echo "Copying ${names[$count2]} to sdcard"
        cp ${names[$count2]}/*.nro $dir/switch/
    elif [ -f ${names[$count2]}/${names[$count2]}*.bin ];
    then
        echo "Copying ${names[$count2]} to sdcard"
        cp ${names[$count2]}/*.bin $dir/bootloader/payloads
    else
        echo "Copying ${names[$count2]} to sdcard"
        cp -r "${names[$count2]}"/* $dir
    fi

    let count2=count2+1
done

echo "creating hekate_ipl.ini "

echo ' 
{------ Atmosphere ------}
[Atmosphere CFW]
payload=bootloader/payloads/fusee-primary.bin
icon=bootlogo.bmp
{}
[Atmosphere FSS0 SYS]
fss0=atmosphere/fusee-secondary.bin
kip1=atmosphere/kips/*
emummc_force_disable=1
icon=bootloader/res/sys_cfw_boot.bmp
{}
{-------- Stock ---------}
["Stock" SYS]
fss0=atmosphere/fusee-secondary.bin
stock=1
emummc_force_disable=1
icon=bootloader/res/stock_boot.bmp
{}
{-----TESTING ONLY-----}
[FSS0 EmuMMC FOR TESTING ONLY]
fss0=atmosphere/fusee-secondary.bin
kip1=atmosphere/kips/*
emummcforce=1
icon=bootloader/res/emu_boot.bmp' > $dir/bootloader/hekate_ipl.ini

echo "copying done, script will stay on standby until you grab the hekate payload and save it in a safe place once youre done you can press enter to delete the working directory"

read $wait

echo "Deleting working directory"

cd ..

rm -rf switch_update

echo "The process is finished have a nice day :)"