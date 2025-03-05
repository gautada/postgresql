#!/bin/sh

# Default health is zero which equals healthy
HEALTH=0

# Check - Disk Usage - Under 90% is helathy
USAGE="$(df -h '/opt/postgres' | grep -E -o '[0-9]+%')"
USAGE="${USAGE%?}"
MAX=90
if [ "${USAGE}" -ge "${MAX}" ] ; then
 HEALTH=1
fi

return $HEALTH
