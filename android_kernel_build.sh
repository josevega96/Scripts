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

if [ -d $HOME/android/toolchains/clang ];
then
    echo "clang found pulling lastest version"
    cd $HOME/android/toolchains/clang 
    git pull
else 
    echo "clang directory not found, cloning lastest version from google"
    git clone https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/ $HOME/android/toolchains/clang 
fi 

echo "looking if gcc toolchain exists"

if [ -d $HOME/android/toolchains/gcc-linux-arm64-4.9 ];
then
    echo "gcc found pulling lastest version"
    cd $HOME/android/toolchains/gcc-linux-arm64-4.9
    git pull
    cd $HOME/android/toolchains/gcc-linux-arm-4.9
    git pull
    cd $1 
else 
    echo "gcc directory not found, cloning lastest arm64 version from google"
    git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/ $HOME/android/toolchains/gcc-linux-arm64-4.9
    echo "cloning lastest armeabi version from google"
    git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/  $HOME/android/toolchains/gcc-linux-arm-4.9 
fi 

echo "creating output directory"

mkdir -p out

echo "input the name of the defconfig to build"

read defconfig

make O=out ARCH=arm64 $defconfig

PATH="$HOME/android/toolchains/clang/bin:$HOME/android/toolchains/gcc-linux-arm64-4.9/bin:$HOME/android/toolchains/gcc-linux-arm-4.9/bin:${PATH}" \
make -j$(nproc --all) O=out \
                      ARCH=arm64 \
                      CC=clang \
                      CLANG_TRIPLE=aarch64-linux-gnu- \
                      CROSS_COMPILE=aarch64-linux-android- \
                      CROSS_COMPILE_ARM32=arm-linux-androideabi-

notify-send 'kernbuild' 'kernel compilation finished'

echo "creating zip with anykernel and deleting build directory"

cp $1/out/arch/arm64/boot/Image.gz-dtb $HOME/android/tools/anykernel/

rm -rf out

cd $HOME/android/tools/anykernel/

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
