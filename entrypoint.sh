#!/bin/bash
#
# entrypoint: Overloaded entrypoint. Just run the postgresql server
echo "-------------------------------------------------------------------------"
mount --all
echo "-------------------------------------------------------------------------"
ls -al /mnt/volumes/container
echo "-------------------------------------------------------------------------"
ls -al /etc/container
set -xue

PG_TYPE=$(echo "${POSTGRESQL_SERVER_TYPE:-PRIMARY}" | tr '[:lower:]' '[:upper:]')
CONFIG_FILE="${POSTGRESQL_CONFIG_FILE:-/etc/container/postgresql.conf}"
DATA_DIR="${POSTGRESQL_DATA_DIRECTORY:-/home/postgres/pgdata}"
RESTORE_FILE="${POSTGRESQL_RESTORE_FILE:-/mnt/volumes/container/postgresql.sql}"
REPLICATION_HOST="${POSTGRESQL_REPLICATION_HOST:-replica.postgresql.domain.tld}"
REPLICATION_PORT="${POSTGRESQL_REPLICATION_PORT:-5432}"
REPLICATION_USER="${POSTGRESQL_REPLICATION_USER:-replicator}"
# REPLICATION_PASSWORD="${POSTGRESQL_REPLICATION_PASSWORD:-replicator}"
BACKUP_RESTORE_FILE="${POSTGRESQL_BACKUP_RESTORE_FILE:-True}"
export ARCHIVE_DIR="${POSTGRESQL_ARCHIVE_DIRECTORY:-/home/postgres/archive}"
echo "${REPLICATION_USER}"

# shellcheck disable=SC2317

echo "[INFO] Setup security files ${DATA_DIR}"
mkdir -p /etc/container/secrets/
cp /mnt/volumes/secrets/*.pem /etc/container/secrets/
chmod 600 /etc/container/secrets/*.pem
# kcat /etc/ssl/cert.pem /etc/container/secrets/ca.pem
ls -al /etc/container/secrets/
cp /mnt/volumes/secrets/replicator.pgpass /home/postgres/.pgpass
chmod 600 /home/postgres/.pgpass

if [ "${PG_TYPE}" = "PRIMARY" ]; then
 exec /etc/container/entrypoint-primary
elif [ "${PG_TYPE}" = "REPLICA" ]; then
 exec /etc/container/entrypoint-replica
else
 echo "[ERROR] Uknown server type(${PG_TYPE})"
 exit 1
fi


# -----------------------------------------------------------------------------
# Start Server

if [ ! -d "${DATA_DIR}" ] ; then
 echo "[ERROR] No data directory: ${DATA_DIR}" >&2
 exit 2
fi

if [ ! -d "${ARCHIVE_DIR}" ] ; then
 echo "[INFO] Setup archive directory: ${ARCHIVE_DIR}"
fi

if [ -f "${RESTORE_FILE}" ] ; then
 if [ "True" = "${BACKUP_RESTORE_FILE}" ] ; then
  echo "[INFO] Backup restore file: ${RESTORE_FILE}"
  mv "${RESTORE_FILE}" "${RESTORE_FILE}~"
 fi
fi

echo "[INFO] Launch crond"
/usr/bin/sudo /usr/sbin/crond -b  
echo "[INFO] Start server ..."
echo "[INFO] ... with configuration: ${CONFIG_FILE}"
echo "[INFO] ... with data directory: ${DATA_DIR}"
echo "${REPLICATION_HOST}:${REPLICATION_PORT}:replication:replicator:$(cat "${HOME}/.pgpass")" > "${HOME}/.pgpass"
/usr/bin/postgres --config-file="${CONFIG_FILE}" -D "${DATA_DIR}"
set +eux
