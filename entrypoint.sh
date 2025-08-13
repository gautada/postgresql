#!/bin/sh
#
# entrypoint: OVerloaded entrypoint. Just run the postgresql server
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
 if [ -d "${DATA_DIR}" ] ; then
  echo "[INFO] Existing data directory: ${DATA_DIR}" >&2
 else
  echo "[WARN] data directory ${DATA_DIR} does not exist."
  if [ -f "${RESTORE_FILE}" ] ; then
   echo "[INFO] Restore from file: ${RESTORE_FILE}"
   echo "[INFO] Initialize database directory: ${DATA_DIR}"
   /usr/bin/initdb "${DATA_DIR}"
   pg_ctl -D "${DATA_DIR}" start
   psql -U postgres -f "${RESTORE_FILE}"
   pg_ctl -D "${DATA_DIR}" stop
  else
   echo "[WARN] Could not find a restore file ${RESTORE_FILE} "
   dir_path=$(dirname "${RESTORE_FILE}")
   echo "[WARN] Files in directory: ${dir_path}"
   ls -l "${dir_path}"
   echo "[INFO] Restore from replica"
   mkdir -p "${DATA_DIR}"
   chmod 750 -R  "${DATA_DIR}"
   DBURL="postgresql://${REPLICATION_USER}:"
   DBURL="${DBURL}$(tr -d '[:space:]' < "${HOME}/.pgpass")"
   DBURL="${DBURL}@${REPLICATION_HOST}:${REPLICATION_PORT}/replication?"
   DBURL="${DBURL}sslmode=verify-full&"
   DBURL="${DBURL}sslcert=/etc/container/secrets/client-cert.pem&"
   DBURL="${DBURL}sslkey=/etc/container/secrets/client-key.pem&"
   DBURL="${DBURL}sslrootcert=/etc/ssl/cert.pem"
   echo "[INFO] Replica to restore: ${DBURL}"
   set +e
   # pg_basebackup --pgdata=./pgdata --dbname "${DBURL}"  --verbose --progress
   if ! pg_basebackup --pgdata=./pgdata --dbname "${DBURL}"  --verbose --progress; then
   # if [ $? -ne 0 ]; then
    echo "[ERROR] Replica restor failed"
    exit 45
   fi
   set -e
   echo "[INFO] Promote primary"
   rm -rf "${DATA_DIR}/standby.signal"
   touch "${DATA_DIR}/failover.signal"
  fi # Restore
 fi # Initialize DB
elif [ "${PG_TYPE}" = "REPLICA" ]; then
 echo "[INFO] Replicate from primary server ..."
 echo "[INFO] ... Read configuration from ${CONFIG_FILE}"
 line=$(grep "primary_conninfo" "${CONFIG_FILE}")
 REPLICATION_HOST="$(echo "${line}" | sed -n "s/.*host=\([^ ]*\).*/\1/p")"
 REPLICATION_PORT="$(echo "${line}" | sed -n "s/.*port=\([^ ]*\).*/\1/p")"
 REPLICATION_USER="$(echo "${line}" | sed -n "s/.*user=\([^ ]*\).*/\1/p")"
 # REPLICATION_PASSWORD=${POSTGRESQL_REPLICATION_PASSWORD:-$(echo "{$line}" | sed -n "s/.*user=\([^ ]*\).*/\1/p")}
 echo "[INFO] Replication parameters ..."
 echo "[INFO] ... Host: ${REPLICATION_HOST}"
 echo "[INFO] ... Port: ${REPLICATION_PORT}"
 echo "[INFO] ... User: ${REPLICATION_USER}"
 mkdir -p "${DATA_DIR}"
 chmod 750 -R  "${DATA_DIR}"
 DBURL="postgresql://${REPLICATION_USER}:"
 DBURL="${DBURL}$(tr -d '[:space:]' < "${HOME}/.pgpass")"
 DBURL="${DBURL}@${REPLICATION_HOST}:${REPLICATION_PORT}/replication?"
 DBURL="${DBURL}sslmode=verify-full&"
 DBURL="${DBURL}sslcert=/etc/container/secrets/client-cert.pem&"
 DBURL="${DBURL}sslkey=/etc/container/secrets/client-key.pem&"
 DBURL="${DBURL}sslrootcert=/etc/ssl/cert.pem"
 echo "[INFO] Start base backup: ***"
 pg_basebackup --pgdata=./pgdata --dbname "${DBURL}"  --verbose --progress
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
