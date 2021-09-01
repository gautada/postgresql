#!/bin/sh

/usr/sbin/crond -D

if [ ! -d /opt/postgres-data/system ] ; then
 mkdir -p /opt/postgres-data/system
 chown postgres:postgres /opt/postgres-data/system
 /usr/bin/initdb -D /opt/postgres-data/system
fi

/usr/bin/postgres -D /opt/postgres-data/system

