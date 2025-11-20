#!/bin/sh
systemctl stop sr_mcureader.service
echo "mcu reader stopped"
systemctl stop sr_day_night_scheduler.timer
echo "day_night_scheduler stopped"
systemctl stop sr_pelcod.service
echo "pelcod stopped"
systemctl stop sr_edge_nodes_service_watcher.service
systemctl stop sr_edge_nodes.service
echo "edge nodes stopped"
systemctl stop sr_restreamer.service
echo "restreamer stopped"
systemctl stop sr_orchestrator.service
echo "orchestrator stopped"
pid=$(pgrep -f multionvifserver) && kill -9 $pid
echo "multionvif stopped"
systemctl stop sr_onvif_server.service
echo "onvif stopped"
sleep 1s
systemctl start sr_mcureset.service
echo "mcu reset triggered"
sleep 1s
systemctl start sr_shutdown.timer
echo "shutdown after 10 sec"
systemctl stop sr_rabbitmq_docker.service
echo "rabbitmq stopped"
#systemctl stop sr_subprocess_util.service
#echo "subprocess stoped"
echo "$(date) all services stopped"
