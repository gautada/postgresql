#!/bin/sh
#
# entrypoint: OVerloaded entrypoint. Just run the postgresql server

DB_DIR="${POSTGRESQL_DATA_DIRECTORY:-/home/postgres/pgdata}"
if [ ! -d "${DB_DIR}" ] ; then
 echo "Initialize database directory --- ${DB_DIR}"
 /usr/bin/initdb "${DB_DIR}"
 pg_ctl -D "${DB_DIR}" start
 BACKUP_FILE="${POSTGRESQL_BACKUP_FILE:-/mnt/volumes/container/postgresql.sql}"
 if [ -f "${BACKUP_FILE}" ] ; then
  echo "Restoring database from file --- ${BACKUP_FILE}"
  psql -U postgres -f "${BACKUP_FILE}"
 else
  echo "[WARN] Backup database file (${BACKUP_FILE}) is not available"
 fi
 pg_ctl -D "${DB_DIR}" stop
fi

CONFIG_FILE="${POSTGRESQL_CONFIG_FILE:-/etc/container/postgresql.conf}"
/usr/bin/postgres --config-file="${CONFIG_FILE}" -D "${DB_DIR}"
# tail -f /dev/null
#  mkdir /home/postgres/.tls
#  /bin/cp /mnt/volumes/secrets/tls.key /home/postgres/.tls/tls.key
#  /bin/cp /mnt/volumes/secrets/tls.crt /home/postgres/.tls/tls.crt
#  /bin/chmod 0600 /home/postgres/.tls/tls.key
#  /bin/chmod 0600 /home/postgres/.tls/tls.crt
#
# container_version() {
#  /usr/bin/postgres --version | awk -F ' ' '{print $3}'
#}
