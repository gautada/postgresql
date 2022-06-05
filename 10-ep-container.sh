#!/bin/ash
#
# Launch the podman service/process if not previously launched. If parameters are not provided
# launch as a process. If parameters provided fork the podman as a service.

if [ ! -d /opt/postgres/system ] ; then
 mkdir -p /opt/postgres/system
 chown postgres:postgres /opt/postgres/system
 /usr/local/pgsql/bin/initdb -D /opt/postgres/system
fi


TEST="$(/usr/bin/pgrep /usr/local/pgsql/bin/postgres)"
if [ $? -eq 1 ] ; then
 unset TEST
 echo "---------- [ RDMS SERVER(postgres) ] ----------"
 /usr/local/pgsql/bin/pg_ctl start -D /opt/postgres/system
fi
if [ -z "$ENTRYPOINT_PARAMS" ] ; then # Run as container app
 TEST="$(/usr/bin/pgrep /usr/bin/pgweb)"
 if [ $? -eq 1 ] ; then
  unset TEST
  echo "---------- [ WEB APPLICATION(pgweb) ] ----------"
  /usr/bin/pgweb --bind 0.0.0.0 --listen 8080 --host localhost --user postgres
 fi
fi







