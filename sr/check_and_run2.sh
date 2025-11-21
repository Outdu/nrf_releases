#!/bin/bash
# Function to wait for RabbitMQ Docker container to be running
wait_for_rabbitmq() {
    echo "Waiting for RabbitMQ Docker container to start..."
    while true; do
        # Check if a running container matches rabbitmq
        if docker ps --filter "name=rabbitmq" --filter "status=running" | grep -q rabbitmq; then
            echo "RabbitMQ is running!"
            break
        else
            echo "RabbitMQ not running yet. Waiting..."
            sleep 2
        fi
    done
}

# Function to wait for cameras to be reachable
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

# Wait for RabbitMQ
wait_for_rabbitmq


# Wait for cameras
wait_for_cameras


# Declare an associative array to map process names to start commands
declare -A process_commands=(
    ["florence"]="/srv/sr/edge/florence/run"
    ["edge-nodes-graph"]="/srv/sr/edge/build/run"
    ["RTSPtoWeb"]="/srv/sr/edge/webrtc/run"
)

echo "Checking and starting processes if needed..."

for proc in "${!process_commands[@]}"
do
    if ps -ef | grep -v grep | grep -q "$proc"; then
        echo "$proc: already running"
    else
        echo "$proc: not running — starting now..."
    fi
done
sleep 2s
for proc in "${!process_commands[@]}"
do
    if ps -ef | grep -v grep | grep -q "$proc"; then
        echo "$proc: already running"
    else
        echo "$proc: not running — starting now..."
        eval "${process_commands[$proc]}"
	sleep 3s
    fi
done
