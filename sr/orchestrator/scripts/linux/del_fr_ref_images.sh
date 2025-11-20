#!/bin/sh
#echo $@
if [ "$1" != "delFRRefImages" ]; then
	echo "not delFRRefImages"
	exit 1
fi
if [ -d "$2" ]; then
	sudo rm -rf "$2"
else	
	files=$(echo $2 | tr "," "\n")
	for img_file in $files
	do
		sudo rm -f "$img_file"
		fr_file=$(echo ${img_file%.*}).txt
		sudo rm -f "$fr_file"
	done
fi	
echo "success"
exit 0
