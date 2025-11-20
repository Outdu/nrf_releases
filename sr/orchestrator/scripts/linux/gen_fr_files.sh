#!/bin/sh
#echo $@
if [ "$1" != "genFRFiles" ]; then
	echo "not genFRFiles"
	exit 1
fi
echo $2
/srv/sr/sensor/unicamera/run_fr_db > /srv/sr/sensor/unicamera/fr_creation.log 2>&1
echo "success"
exit 0
