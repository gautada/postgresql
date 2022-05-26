#!/bin/ash
#
# Launch the podman service/process if not previously launched. If parameters are not provided
# launch as a process. If parameters provided fork the podman as a service.

if [ ! -d /opt/postgres/system ] ; then
 mkdir -p /opt/postgres/system
 chown postgres:postgres /opt/postgres/system
 /usr/local/pgsql/bin/initdb -D /opt/postgres/system
fi


TEST="$(/usr/bin/pgrep postgres)"
if [ $? -eq 1 ] ; then
 echo "---------- [ RDMS SERVER(postgres) ] ----------"
 if [ -z "$ENTRYPOINT_PARAMS" ] ; then # Run as container app
   /usr/local/pgsql/bin/postgres -D /opt/postgres/system
 else # Run as daemon
   /usr/local/pgsql/bin/pg_ctl start -D /opt/postgres/system
 fi
fi






