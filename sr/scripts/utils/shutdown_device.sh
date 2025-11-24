#!/bin/sh
systemctl stop sr_mcureader.service
echo "mcu reader stopped"
systemctl stop sr_orchestrator.service
echo "orchestrator stopped"
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
