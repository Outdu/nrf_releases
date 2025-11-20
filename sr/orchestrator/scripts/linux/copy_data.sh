#!/bin/sh
#sudo lsblk -o NAME > /srv/sr/orchestrator/scripts/usblog2.txt #using docker mount/unmount_drive scripts


#usb_media_path=$(df | grep media |  awk '{ print $6 "\t" }' | xargs)
#echo "usb_media_path="$usb_media_path
#if [ "$usb_media_path" != "" ]; then
#	echo "found usb $usb_media_path"
#else
#	echo "usb not found"
#fi

usb_media_path=/srv/sr/dfmusb
#using docker mount/unmount_drive scripts
#usb_disk=/dev/$(diff /srv/sr/orchestrator/scripts/usblog1.txt /srv/sr/orchestrator/scripts/usblog2.txt | awk '{getline; print $0;}' | awk '{print $2 "\t";}')
#if [ "$usb_disk" != "" ]; then
#	echo "found usb disk $usb_disk"
#else
#	echo "usb disk not found $usb_disk"
#	exit 1
#fi
#sudo mount $usb_disk $usb_media_path

fullVideoDir=/srv/sr/media/fromSensor/UniCamera/0/fullVideo
burstImageDir=/srv/sr/media/fromSensor/UniCamera/0/burstImage
eventLogDir=/srv/sr/eventlogs

outputFullVideoDir=$usb_media_path/outdu/fullVideo
outputBurstImageDir=$usb_media_path/outdu/burstImage
outputEventLogDir=$usb_media_path/outdu/eventLog
#echo 'sr123' | sudo -S mkdir -p $outputFullVideoDir
sudo mkdir -p $outputFullVideoDir
sudo mkdir -p $outputBurstImageDir
sudo mkdir -p $outputEventLogDir
touch --date "$1" $fullVideoDir/start
touch --date "$2" $fullVideoDir/end
find $fullVideoDir -type f -not -name "end" -newer $fullVideoDir/start -not -newer $fullVideoDir/end -exec sudo cp {} $outputFullVideoDir \;
rm $fullVideoDir/start
rm $fullVideoDir/end
touch --date "$1" $burstImageDir/start
touch --date "$2" $burstImageDir/end
#echo "find $burstImageDir -type f -not -name "end" -newer $burstImageDir/start -not -newer $burstImageDir/end -exec sudo cp {} $outputBurstImageDir \;"
find $burstImageDir -type f -not -name "end" -newer $burstImageDir/start -not -newer $burstImageDir/end -exec sudo cp {} $outputBurstImageDir \;
rm $burstImageDir/start
rm $burstImageDir/end
#echo "$outputFullVideoDir"
#echo "$outputBurstImageDir"
#echo "$outputEventLogDir"
sudo cp $eventLogDir/* $outputEventLogDir/
sudo mv $outputEventLogDir/events.log $outputEventLogDir/events.$(date +"%Y-%m-%d").log
sudo sed -i '1s/^/[/;$s/.$/]/' $outputEventLogDir/*

sleep 10s
#using docker mount/unmount_drive scripts
#sudo umount $usb_media_path
python3 /srv/sr/orchestrator/scripts/send_umount_cmd.py
exit 0

