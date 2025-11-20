#!/bin/sh
#echo $@
if [ "$1" != "touchPurgeDate" ]; then
	echo "not touchPurgeDate"
	exit 1
fi
echo $2
touch --date "$2" /srv/sr/orchestrator/scripts/purge_date