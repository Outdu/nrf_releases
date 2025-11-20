#!/bin/sh
systemctl status sr_day_night_scheduler.service
systemctl status sr_pelcod.service
systemctl status sr_edge_nodes.service
systemctl status sr_restreamer.service
systemctl status sr_orchestrator.service
systemctl status sr_onvif_server.service
systemctl status sr_mcureader.service
systemctl status sr_rabbitmq_docker.service
systemctl status sr_mcureset.service
systemctl status sr_subprocess_util.service
