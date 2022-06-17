#!/bin/ash
#
#

FOLDER_DATASTORE="/opt/postgres/datastore"
if [ ! -d $FOLDER_DATASTORE ] ; then
 mkdir -p $FOLDER_DATASTORE
fi

TEST="$(/usr/bin/pgrep /usr/libexec/postgresql14/postgres)"
if [ $? -eq 1 ] ; then
 unset TEST
 echo "---------- [ RDMS SERVER(postgres) ] ----------"
 if [ ! -f $FOLDER_DATASTORE/PG_VERSION ] ; then
  echo "Database is not initialized(/usr/bin/initdb --pgdata=$FOLDER_DATASTORE)"
 else
  /usr/bin/pg_ctl start --pgdata=$FOLDER_DATASTORE
 fi
fi

if [ -z "$ENTRYPOINT_PARAMS" ] ; then # Run as container app
 TEST="$(/usr/bin/pgrep /usr/bin/pgweb)"
 if [ $? -eq 1 ] ; then
  unset TEST
  echo "---------- [ WEB APPLICATION(pgweb) ] ----------"
  /usr/bin/pgweb --bind 0.0.0.0 --listen 8080 --host localhost --user postgres
  return 1
 fi
fi







