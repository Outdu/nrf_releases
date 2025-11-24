#!/bin/sh
systemctl status sr_orchestrator.service
systemctl status sr_mcureader.service
systemctl status sr_rabbitmq_docker.service
systemctl status sr_mcureset.service
systemctl status sr_subprocess_util.service
