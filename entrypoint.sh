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
# REPLICATION_PASSWORD="${POSTGRESQL_REPLICATION_PASSWORD:-replicator}"
BACKUP_RESTORE_FILE="${POSTGRESQL_BACKUP_RESTORE_FILE:-True}"
export ARCHIVE_DIR="${POSTGRESQL_ARCHIVE_DIRECTORY:-/home/postgres/archive}"

# shellcheck disable=SC2317

echo "[INFO] Setup security files ${DATA_DIR}" >&2
mkdir -p /etc/container/secrets/
cp /mnt/volumes/secrets/*.pem /etc/container/secrets/
chmod 600 /etc/container/secrets/*.pem
cat /etc/ssl/cert.pem /etc/container/secrets/ca.pem
ls -al /etc/container/secrets/
cp /mnt/volumes/secrets/replicator.pgpass /home/postgres/.pgpass
chmod 600 /home/postgres/.pgpass

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
  else
   echo "[WARN] Could not find a restore file ${RESTORE_FILE} "
   dir_path=$(dirname "${RESTORE_FILE}")
   echo "[WARN] Files in directory: ${dir_path}"
   ls -l "${dir_path}"
   mkdir -p "${DATA_DIR}"
   chmod 750 -R  "${DATA_DIR}"
   PGPASSWORD="$(cat "${HOME}/.pgpass")" || exit 1
   export PGPASSWORD
   # pg_basebackup \
   #  --pgdata="${DATA_DIR}" \
   #  --host="${REPLICATION_HOST}" \
   #  --port="${REPLICATION_PORT}" \
   #  --username="${REPLICATION_USER}" \
   #  --sslmode=verify-full \
   #  --sslcert=/etc/container/secrets/client-cert.pem \
   #  --sslkey=/etc/container/secrets/client-key.pem \
   #  --sslrootcert=/etc/ssl/cert.pem \
   #  -Xs -P || exit 3
   # unset PGPASSWORD
   pg_basebackup --pgdata="${DATA_DIR}" \
   -d "host=${REPLICATION_HOST}
   port=${REPLICATION_PORT}
   user=${REPLICATION_USER}
   dbname=replication
   sslmode=verify-full
   sslcert=/etc/container/secrets/client-cert.pem
   sslkey=/etc/container/secrets/client-key.pem
   sslrootcert=/etc/ssl/cert.pem" -P || exit 2
   echo "[INFO] Promote primary"
   rm -rf "${DATA_DIR}/standby.signal"
   touch "${DATA_DIR}/failover.signal"
  fi
 fi
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
 # cp "${CONFIG_FILE}" "${DATA_DIR}/postgresql.auto.conf"
 chmod 750 -R  "${DATA_DIR}"
 PGPASSWORD="$(cat "${HOME}/.pgpass")" || exit 1
 export PGPASSWORD
 pg_basebackup --pgdata="${DATA_DIR}" \
    -d "host=${REPLICATION_HOST}
        port=${REPLICATION_PORT}
        user=${REPLICATION_USER}
        dbname=replication
        sslmode=verify-full
        sslcert=/etc/container/secrets/client-cert.pem
        sslkey=/etc/container/secrets/client-key.pem
        sslrootcert=/etc/ssl/cert.pem" -P || exit 2
 unset PGPASSWORD
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

echo "[INFO] Start server ..."
echo "[INFO] ... with configuration: ${CONFIG_FILE}"
echo "[INFO] ... with data directory: ${DATA_DIR}"
echo "${REPLICATION_HOST}:${REPLICATION_PORT}:replication:replicator:$(cat "${HOME}/.pgpass")" > "${HOME}/.pgpass"
/usr/bin/postgres --config-file="${CONFIG_FILE}" -D "${DATA_DIR}"
