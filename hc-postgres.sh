#!/bin/ash

# Default health is zero which equals healthy
HEALTH=0

# Check #1 - Postgres is running
TEST="$(/usr/bin/pgrep postgres)"
if [ $? -eq 1 ] ; then
 HEALTH=1
fi
# Check #2a - Postgres isready
TEST="$(/usr/bin/pg_isready)"
if [ ! $? -eq 0 ] ; then
 HEALTH=1
fi
# Check #2b - Postgres isready TCP
TEST="$(/usr/bin/pg_isready --host 127.0.0.1)"
if [ ! $? -eq 0 ] ; then
 HEALTH=1
fi

# Check #2c - Postgres isready TCP Service
# TEST="$(/usr/bin/pg_isready --host postgres.data.svc.cluster.local)"
# if [ ! $? -eq 0 ] ; then
# HEALTH=1
# fi

# Check #3 - A psql client can connect
TEST=$(/usr/local/pgsql/bin/psql -c "SELECT datname FROM pg_database;")
if [ $? -eq 1 ] ; then
 HEALTH=1
fi

return $HEALTH

