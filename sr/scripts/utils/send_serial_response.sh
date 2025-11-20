#!/bin/bash

# Script to send "S" response to serial port
# Usage: ./send_serial_response.sh <tty_device>

if [ $# -ne 1 ]; then
    echo "Usage: $0 <tty_device>"
    echo "Example: $0 /dev/ttyUSB0"
    exit 1
fi

TTY_DEVICE=$1

# Check if device exists
if [ ! -e "$TTY_DEVICE" ]; then
    echo "Error: Device $TTY_DEVICE does not exist"
    exit 1
fi

# Send "S" followed by carriage return to the serial port
echo "Sending 'S\r' to $TTY_DEVICE..."
printf "S\r" > "$TTY_DEVICE"

echo "Response sent successfully"
