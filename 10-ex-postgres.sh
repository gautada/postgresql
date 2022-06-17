#!/bin/ash
 echo "---------- < RDMS SERVER(postgres) > ----------"
/usr/bin/pg_ctl stop --pgdata=/opt/postgres/datastore

# %wheel         ALL = (ALL) NOPASSWD: "/bin/chown -R $(whoami):$(whoami) /opt/$(whoami)"


