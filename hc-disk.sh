#!/bin/ash
# shellcheck shell=dash
# hc-disk: Container disk health check script
# Return 0 if healthy, 1 if unhealthy (usage >= 90%)

HEALTH=0
DATA_DIR="/opt/postgres"
MAX_USAGE=90

# Ensure the data directory exists
if [ ! -d "$DATA_DIR" ]; then
    echo "ERROR: $DATA_DIR does not exist." >&2
    exit 1
fi

# Get disk usage percentage for the data directory
# We use df -P for POSIX output format to ensure portability
USAGE=$(df -P "$DATA_DIR" | awk 'NR==2 {print $5}' | sed 's/%//')

if [ -z "$USAGE" ]; then
    echo "ERROR: Could not determine disk usage for $DATA_DIR" >&2
    exit 1
fi

if [ "$USAGE" -ge "$MAX_USAGE" ]; then
    echo "UNHEALTHY: Disk usage is ${USAGE}% (threshold: ${MAX_USAGE}%)" >&2
    HEALTH=1
else
    echo "HEALTHY: Disk usage is ${USAGE}%"
fi

exit "$HEALTH"
