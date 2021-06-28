# !/bin/bash 
###
## Create and import whatsapp stickers 
###

count=0
mkdir -pv $1/out && cd $1/out
for f in $1/*mp4
do
    count=$((count+=1))
    ffmpeg -i $f  -s 512x512  outp$count.webp
    name=$(adb shell ls -t '/sdcard/android/media/com.whatsapp/WhatsApp/Media/WhatsApp\ Stickers' | sed -n "$count"p)
    adb push outp$count.webp /sdcard/android/media/com.whatsapp/WhatsApp/Media/WhatsApp\ Stickers/$name
done
cd ..
rm -rf out
adb shell su -c "rm -rf /data/data/com.whatsapp/cache/*"
adb shell am force-stop com.whatsapp