#!/bin/ash

# Default health is zero which equals healthy
HEALTH=0

# Check #1 - Postgres is running
if /usr/bin/pgrep postgres ; then
 HEALTH=1
fi
# Check #2a - Postgres isready
if ! /usr/bin/pg_isready ; then
 HEALTH=1
fi
# Check #2b - Postgres isready TCP
if /usr/bin/pg_isready --host 127.0.0.1 ; then
 HEALTH=1
fi

# Check #2c - Postgres isready TCP Service
# TEST="$(/usr/bin/pg_isready --host postgres.data.svc.cluster.local)"
# if [ ! $? -eq 0 ] ; then
# HEALTH=1
# fi

# Check #3 - A psql client can connect
if /usr/bin/psql -c "SELECT datname FROM pg_database;" ; then
 HEALTH=1
fi

# CREATE TABLE customers (firstname text);
# INSERT INTO customer (firstname) VALUES ('Bob Smith');
return $HEALTH

