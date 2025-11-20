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

# Wait for RabbitMQ
wait_for_rabbitmq

# Declare an associative array to map process names to start commands
declare -A process_commands=(
    ["web_ui"]="/srv/sr/edge/web_ui/run"
)

echo "Checking and starting processes if needed..."

for proc in "${!process_commands[@]}"
do
    if ps -ef | grep -v grep | grep -q "$proc"; then
        echo "$proc: already running"
    else
        echo "$proc: not running — starting now..."
        eval "${process_commands[$proc]}"
    fi
done

