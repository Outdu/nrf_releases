#!/bin/bash

# Usage validation
if [ -z "$1" ]; then
    echo "❗ Usage: $0 <hours>"
    exit 1
fi

HOURS=$1
TARGET_DIR="/srv/sr/orchestrator/media"
LOG_FILE="/srv/sr/orchestrator/logs/media_cleanup.log"

echo "[$(date)] Cleanup started in $TARGET_DIR (Older than $HOURS hours)" | tee -a "$LOG_FILE"

# Find and delete .jpg and .mp4 files older than given hours
find "$TARGET_DIR" -type f \( -name "*.jpg" -o -name "*.mp4" \) -mmin +"$((HOURS * 60))" | while read file; do
    echo "Deleting: $file" | tee -a "$LOG_FILE"
    rm -f "$file"
done

echo "[$(date)] Cleanup completed." | tee -a "$LOG_FILE"

