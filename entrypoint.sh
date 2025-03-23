#!/bin/sh
#
# entrypoint: OVerloaded entrypoint. Just run the postgresql server

# STEPS
# Determine if master or replica
# IF Master?
# - IF there is a backup file then load the backup file to a minimal config
# - Check if there are replicas, if yes fail.
# - If no replicas then launch master from backup and archive backup.
# ELSE
# - Replicate from replica 
# - Launch master (replicas should kick-in
# ELSE Replica
# - check replica: SELECT pg_is_in_recovery(); Returns true → This is a replica.
# - pg_basebackup
# - constant replicate

PG_TYPE=$(echo "${POSTGRESQL_SERVER_TYPE:-master}" | tr '[:lower:]' '[:upper:]')
DATA_DIR="${POSTGRESQL_DATA_DIRECTORY:-/home/postgres/pgdata}"
BACKUP_FILE="${POSTGRESQL_BACKUP_FILE:-/mnt/volumes/container/postgresql.sql}"
REPLICA_HOST="${POSTGRESQL_REPLICA_HOST:-replica.postgresql.domain.tld}"
REPLICA_PORT="${POSTGRESQL_REPLICA_PORT:-5432}"
# REPLICA_DB="${POSTGRESQL_REPLICA_DATABASE:-db}"
REPLICA_USER="${POSTGRESQL_REPLICA_USER:-replication}"
# REPLICA_PWD="${POSTGRESQL_REPLICA_USER:-pwd}"
PRIMARY_HOST="${POSTGRESQL_PRIMARY_HOST:-primary.postgresql.domain.tld}"
PRIMARY_PORT="${POSTGRESQL_PRIMARY_PORT:-5432}"
# PRIMARY_DB="${POSTGRESQL_REPLICA_DATABASE:-db}"
PRIMARY_USER="${POSTGRESQL_PRIMARY_USER:-replication}"
# REPLICA_PWD="${POSTGRESQL_REPLICA_USER:-pwd}"
export ARCHIVE_DIR="${POSTGRESQL_ARCHIVE_DIRECTORY:-/home/postgres/archive}"
CONFIG_FILE="${POSTGRESQL_CONFIG_FILE:-/etc/container/postgresql.conf}"

if [ "${PG_TYPE}" = "MASTER" ]; then
 if [ -d "${DATA_DIR}" ] ; then
  echo "[INFO] Existing data directory: ${DATA_DIR}" >&2
 else
  if [ -f "${BACKUP_FILE}" ] ; then
   echo "[INFO] Recover from backup file: ${BACKUP_FILE}"
   echo "[INFO] Initialize database directory: ${DATA_DIR}"
   /usr/bin/initdb "${DATA_DIR}"
   pg_ctl -D "${DATA_DIR}" start
   psql -U postgres -f "${BACKUP_FILE}"
   pg_ctl -D "${DATA_DIR}" stop
   mv "${BACKUP_FILE}" "${BACKUP_FILE}~"
  else
   echo "[WARN] Recover from standby: @to-do: read standby pg_basebackup"
   mkdir -p "${DATA_DIR}"
   pg_basebackup --pgdata="${DATA_DIR}" --host="${REPLICA_HOST}" \
                 --port="${REPLICA_PORT}" --username="${REPLICA_USER}"
  fi
 fi 
elif [ "${PG_TYPE}" = "REPLICA" ]; then
 echo "[WARN] Establish standby: @to-do read primary pg_basebackup"
 # pg_basebackup --help
 mkdir -p "${DATA_DIR}"
 # cp "${CONFIG_FILE}" "${DATA_DIR}/postgresql.auto.conf"
 chmod 750 -R  "${DATA_DIR}"
 pg_basebackup --pgdata="${DATA_DIR}" --host="${PRIMARY_HOST}" \
               --port="${PRIMARY_PORT}" --username="${PRIMARY_USER}"
 # Set server to standby
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
