#!/bin/bash
wait_for_cameras() {
    echo "Waiting for cameras to be reachable..."
    cameras=("192.168.10.71" "192.168.10.73" "192.168.10.75")

    for cam in "${cameras[@]}"; do
        while true; do
            if ping -c 1 -W 1 "$cam" &> /dev/null; then
                echo "Camera $cam is reachable!"
                break
            else
                echo "Camera $cam not reachable yet. Waiting..."
                sleep 2
            fi
        done
    done
    echo "All cameras are reachable!"
}

# Wait for cameras
wait_for_cameras


# Declare an associative array to map process names to start commands
declare -A process_commands=(
    ["florence"]="/srv/sr/edge/scene/run"
    ["edge-nodes-graph"]="/srv/sr/edge/build/run_calib_run_pano"
    ["RTSPtoWeb"]="/srv/sr/edge/webrtc/run"
    ["web_ui"]="/srv/sr/edge/web_ui/run"
)

echo "Checking and starting processes if needed..."

for proc in "${!process_commands[@]}"
do
    if ps -ef | grep -v grep | grep -q "$proc"; then
        echo "$proc: already running"
    else
        echo "$proc: not running"
    fi
done
