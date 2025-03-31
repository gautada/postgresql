#!/bin/sh

# backup.sh -> /usr/sbin/container-backup
#
# This will be a simple full backup designed to happen every 15 minutes

/usr/bin/pg_dumpall \
   --username=postgres \
   --host=localhost > \
   "/mnt/volumes/backup/$(/bin/date +"%H%M")postgresql.sql"

