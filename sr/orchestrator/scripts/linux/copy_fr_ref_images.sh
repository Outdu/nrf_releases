#!/bin/sh
#using docker mount/unmount_drive script
#sudo lsblk -o NAME > /srv/sr/orchestrator/scripts/usblog2.txt



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

frRefImagesDir=/srv/sr/media/frRefImages
mkdir $frRefImagesDir
frRefImagesSrcDir=$usb_media_path/outdu/frRefImages

sudo cp -r $frRefImagesSrcDir/* $frRefImagesDir/

sleep 10s
#using docker mount/unmount_drive scripts
#sudo umount $usb_media_path
python3 /srv/sr/orchestrator/scripts/send_umount_cmd.py
exit 0

