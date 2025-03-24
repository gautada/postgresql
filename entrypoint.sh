#!/bin/sh
#
# entrypoint: OVerloaded entrypoint. Just run the postgresql server

PG_TYPE=$(echo "${POSTGRESQL_SERVER_TYPE:-PRIMARY}" | tr '[:lower:]' '[:upper:]')
CONFIG_FILE="${POSTGRESQL_CONFIG_FILE:-/etc/container/postgresql.conf}"
DATA_DIR="${POSTGRESQL_DATA_DIRECTORY:-/home/postgres/pgdata}"
RESTORE_FILE="${POSTGRESQL_RESTORE_FILE:-/mnt/volumes/container/postgresql.sql}"
REPLICATION_HOST="${POSTGRESQL_REPLICATION_HOST:-replica.postgresql.domain.tld}"
REPLICATION_PORT="${POSTGRESQL_REPLICATION_PORT:-5432}"
REPLICATION_USER="${POSTGRESQL_REPLICATION_USER:-replicator}"
REPLICATION_PASSWORD="${POSTGRESQL_REPLICATION_USER:-null}"
export ARCHIVE_DIR="${POSTGRESQL_ARCHIVE_DIRECTORY:-/home/postgres/archive}"

# shellcheck disable=SC2317

if [ "${PG_TYPE}" = "PRIMARY" ]; then
 if [ -d "${DATA_DIR}" ] ; then
  echo "[INFO] Existing data directory: ${DATA_DIR}" >&2
 else
  if [ -f "${RESTORE_FILE}" ] ; then
   echo "[INFO] Restore from file: ${RESTORE_FILE}"
   echo "[INFO] Initialize database directory: ${DATA_DIR}"
   /usr/bin/initdb "${DATA_DIR}"
   pg_ctl -D "${DATA_DIR}" start
   psql -U postgres -f "${RESTORE_FILE}"
   pg_ctl -D "${DATA_DIR}" stop
   echo "[INFO] Backup restorefile: ${RESTORE_FILE}"
   mv "${RESTORE_FILE}" "${RESTORE_FILE}~"
  else
   tail -f /var/null
   exit 99
   echo "[WARN] Could not find a restore file ${RESTORE_FILE} "
   dir_path=$(dirname "${RESTORE_FILE}")
   echo "[WARN] Files in directory: ${dir_path}"
   ls -l "${dir_path}"
   mkdir -p "${DATA_DIR}"
   chmod 750 -R  "${DATA_DIR}"
   PGPASSWORD="${REPLICATION_PASSWORD}" pg_basebackup \
    --pgdata="${DATA_DIR}" \
    --host="${REPLICATION_HOST}" \
    --port="${REPLICATION_PORT}" \
    --username="${REPLICATION_USER}" -Xs -P || exit 3
   echo "[INFO] Promote primary"
   rm -rf "${DATA_DIR}/standby.signal"
   touch "${DATA_DIR}/failover.signal"
  fi
 fi
elif [ "${PG_TYPE}" = "REPLICA" ]; then
   echo "[INFO] Replicate from primary server ..."
 echo "[INFO] ... Read configuration from ${CONFIG_FILE}"
 line=$(grep "primary_conninfo") "${CONFIG_FILE}"
 REPLICATION_HOST=${POSTGRESQL_REPLICATION_HOST:-$(echo "${line}" | sed -n "s/.*host=\([^ ]*\).*/\1/p")}
 REPLICATION_PORT=${POSTGRESQL_REPLICATION_PORT:-$(echo "${line}" | sed -n "s/.*port=\([^ ]*\).*/\1/p")}
 REPLICATION_USER=${POSTGRESQL_REPLICATION_USER:-$(echo "${line}" | sed -n "s/.*user=\([^ ]*\).*/\1/p")}
 REPLICATION_PASSWORD=${POSTGRESQL_REPLICATION_PASSWORD:-$(echo "{$line}" | sed -n "s/.*user=\([^ ]*\).*/\1/p")}
 echo "[INFO] Replication parameters ..."
 echo "[INFO] ... Host: ${REPLICATION_HOST}"
 echo "[INFO] ... Port: ${REPLICATION_PORT}"
 echo "[INFO] ... User: ${REPLICATION_USER}"
 mkdir -p "${DATA_DIR}"
 # cp "${CONFIG_FILE}" "${DATA_DIR}/postgresql.auto.conf"
 chmod 750 -R  "${DATA_DIR}"
 PGPASSWORD="${REPLICATION_PASSWORD}" pg_basebackup \
    --pgdata="${DATA_DIR}" \
    --host="${REPLICATION_HOST}" \
    --port="${REPLICATION_PORT}" \
    --username="${REPLICATION_USER}" -P || exit 2
 touch "${DATA_DIR}/standby.signal"
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

echo "[INFO] Start server ..."
echo "[INFO] ... with configuration: ${CONFIG_FILE}"
echo "[INFO] ... with data directory: ${DATA_DIR}"
/usr/bin/postgres --config-file="${CONFIG_FILE}" -D "${DATA_DIR}"
