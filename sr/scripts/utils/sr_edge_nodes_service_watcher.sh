#!/bin/bash

LOG_FILE="/srv/sr/edge/build/nodes.log"         # change to your actual log path
SERVICE_NAME="sr_edge_nodes.service"      # change to the service you want to restart

# Tail log continuously
tail -F "$LOG_FILE" | while read -r line; do
    if [[ "$line" == *"Deleting pipeline"* ]]; then
        echo "[INFO] $(date) - Deleting pipeline detected. Restarting $SERVICE_NAME..."
        systemctl restart "$SERVICE_NAME"
        echo "[INFO] $(date) - $SERVICE_NAME restarted."
        sleep 60   # wait 1 minute before checking next line
    fi
done

