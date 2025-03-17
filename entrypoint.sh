#!/bin/sh
#
# entrypoint: OVerloaded entrypoint. Just run the postgresql server

DB_DIR="${POSTGRES_DATA:-/home/postgres/pgdata}"
if [ ! -d "${DB_DIR}" ] ; then
 echo "Initialize database directory --- ${DB_DIR}"
 /usr/bin/initdb "${DB_DIR}"
fi
/usr/bin/postgres --config-file=/etc/container/postgresql.conf
#  mkdir /home/postgres/.tls
#  /bin/cp /mnt/volumes/secrets/tls.key /home/postgres/.tls/tls.key
#  /bin/cp /mnt/volumes/secrets/tls.crt /home/postgres/.tls/tls.crt
#  /bin/chmod 0600 /home/postgres/.tls/tls.key
#  /bin/chmod 0600 /home/postgres/.tls/tls.crt
#
# container_version() {
#  /usr/bin/postgres --version | awk -F ' ' '{print $3}'
#}
