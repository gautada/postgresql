#!/bin/ash

# Default health is zero which equals healthy
HEALTH=0

# Check #3 - A psql client can connect
TEST=$(/usr/local/pgsql/bin/psql -c "SELECT datname FROM pg_database;")
if [ $? -eq 1 ] ; then
 HEALTH=1
fi

return $HEALTH

