#! /bin/bash
## script for building android kernel using CLANG

if [ -d "$1" ];
then
    echo "found a valid directory continuing"

cd $1 

else
    echo "directory doesnt exist please check if it exists"
    exit 1
fi

echo "getting kernel version"

ver=$(make kernelversion | cut -c1-3)

echo "$ver version found "


echo "looking if clang toolchain exists"

if [ -d $HOME/Android/toolchains/clang ];
then
    echo "Clang directory found continuing"
else
    echo "clang directory not found fetching version for android 10"
    mkdir -p $HOME/Android/toolchains/clang
    cd $HOME/Android/toolchains/clang 
    wget https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/android-10.0.0_r3/clang-r353983c.tar.gz
    tar -xvzf clang-r353983c.tar.gz 
    rm clang-r353983c.tar.gz 

fi 

echo "looking if arm64 gcc toolchain exists"

if [ -d $HOME/Android/toolchains/gcc-linux-arm64-4.9 ];
then
    echo "gcc found pulling lastest version"
    cd $HOME/Android/toolchains/gcc-linux-arm64-4.9
    git pull
else 
    echo "gcc directory not found, cloning lastest arm64 version from google"
    git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/ $HOME/Android/toolchains/gcc-linux-arm64-4.9
fi 

echo "looking if arm gcc toolchain exists"

if [ -d $HOME/Android/toolchains/gcc-linux-arm-4.9 ];
then
    echo "gcc found pulling lastest version"
    cd $HOME/Android/toolchains/gcc-linux-arm-4.9
    git pull 
else 
    echo "cloning lastest armeabi version from google"
    git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/  $HOME/Android/toolchains/gcc-linux-arm-4.9 
fi

cd $1 

echo "creating output directory"

mkdir -p out

echo "input the name of the defconfig to build"

read defconfig

make O=out ARCH=arm64 $defconfig

PATH="$HOME/Android/toolchains/clang/bin:$HOME/Android/toolchains/gcc-linux-arm64-4.9/bin:$HOME/Android/toolchains/gcc-linux-arm-4.9/bin:${PATH}" \
make -j$(nproc --all) O=out \
                      ARCH=arm64 \
                      CC=clang \
                      CLANG_TRIPLE=aarch64-linux-gnu- \
                      CROSS_COMPILE=aarch64-linux-android- \
                      CROSS_COMPILE_ARM32=arm-linux-androideabi-

notify-send 'kernbuild' 'kernel compilation finished'

echo "creating zip with anykernel and deleting build directory"

cp $1/out/arch/arm64/boot/Image.gz-dtb $HOME/Android/tools/anykernel/

rm -rf out

cd $HOME/Android/tools/anykernel/

zip -r9 kernel.zip * -x .git README.md 

echo "pushing generated zip to devices /sdcard root, please verify that your device is conected"

sleep 3 

adb push kernel.zip /sdcard

echo "zip has been pushed, build irectory will clean itself, press any key to cancel"

read -n 1 -t 3

if [ $? == 0  ];
then
    exit
fi

rm kernel.zip Image.gz-dtb
