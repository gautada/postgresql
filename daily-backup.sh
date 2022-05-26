#!/bin/sh

if [ ! -d /opt/postgres-data/backup ] ; then
 mkdir -p /opt/postgres-data/backup
fi

/usr/bin/pg_dumpall > /opt/postgres-data/backup/daily
