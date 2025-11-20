#!/bin/sh
if [ "$#" -eq 1 ]; then
	if [ "$1" = "copyFRRefImages" ]; then
		sh /srv/sr/orchestrator/scripts/copy_fr_ref_images.sh
	fi
fi	
if [ "$#" -ge 2 ]; then
	if [ "$1" = "genFRFiles" ]; then
		sh /srv/sr/orchestrator/scripts/gen_fr_files.sh $@
	fi
	if [ "$1" = "delFRRefImages" ]; then
		sh /srv/sr/orchestrator/scripts/del_fr_ref_images.sh $@
	fi
	if [ "$1" = "touchPurgeDate" ]; then
		sh /srv/sr/orchestrator/scripts/touch_purge_date.sh $@
	fi
fi
echo "do_task done"
exit 0
