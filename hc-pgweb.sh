#!/bin/ash

# Default health is zero which equals healthy
HEALTH=0

# Check #1 - A psql client can connect
# TEST="$(/usr/bin/curl http://postgres.data.svc.cluster.local:8080)"
TEST="$(/usr/bin/curl --output /dev/null --silent http://127.0.0.1:8080)"
if [ ! $? -eq 0 ] ; then
 HEALTH=1
fi

return $HEALTH
