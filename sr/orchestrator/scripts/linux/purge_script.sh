#!/bin/bash
#purge_date=$(date +%Y-%m-%d -d "5 days ago")
#echo $purge_date
#touch --date "$purge_date" /srv/sr/orchestrator/scripts/purge_date
purge_dir=/srv/sr/media/fromSensor
#find $purge_dir -type f -not -newer /srv/sr/orchestrator/scripts/purge_date -exec ls -lrt {} \;
find $purge_dir -type f -not -newer /srv/sr/orchestrator/scripts/purge_date -exec rm -f {} \;
rm /srv/sr/orchestrator/scripts/purge_date
