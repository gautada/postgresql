#!/bin/bash

echo "ENTRYPOINT ---- PRIMARY -----"
echo ""
echo ""

# PG_TYPE=$(echo "${POSTGRESQL_SERVER_TYPE:-PRIMARY}" | tr '[:lower:]' '[:upper:]')
# CONFIG_FILE="${POSTGRESQL_CONFIG_FILE:-/etc/container/postgresql.conf}"
DATA_DIR="${POSTGRESQL_DATA_DIRECTORY:-/home/postgres/pgdata}"
RESTORE_FILE="${POSTGRESQL_RESTORE_FILE:-/mnt/volumes/data/postgresql.sql}"

REPLICATION_HOST="${POSTGRESQL_REPLICATION_HOST:-replica.postgresql.domain.tld}"
REPLICATION_PORT="${POSTGRESQL_REPLICATION_PORT:-5432}"
REPLICATION_USER="${POSTGRESQL_REPLICATION_USER:-replicator}"
# REPLICATION_PASSWORD="${POSTGRESQL_REPLICATION_PASSWORD:-replicator}"

# BACKUP_RESTORE_FILE="${POSTGRESQL_BACKUP_RESTORE_FILE:-True}"
ARCHIVE_DIR="${POSTGRESQL_ARCHIVE_DIRECTORY:-/home/postgres/archive}"

# if [ -d "${DATA_DIR}" ] ; then
#   echo "[INFO] Existing data directory: ${DATA_DIR}" >&2
#  else
#   echo "[WARN] data directory ${DATA_DIR} does not exist."


# if [ -f "${RESTORE_FILE}" ] ; then
#   echo "[INFO] Restore from file: ${RESTORE_FILE}"
#   echo "[INFO] Initialize database directory: ${DATA_DIR}"
#   /usr/bin/initdb "${DATA_DIR}"
#   pg_ctl -D "${DATA_DIR}" start
#   psql -U postgres -f "${RESTORE_FILE}"
#   pg_ctl -D "${DATA_DIR}" stop
#   echo "[INFO] Restored DB from file"
# else
#   echo "[WARN] Could not find a restore file ${RESTORE_FILE} "
#   dir_path=$(dirname "${RESTORE_FILE}")
#   echo "[WARN] Files in directory: ${dir_path}"
#   ls -l "${dir_path}"
  echo "[INFO] Restore from replica"
  mkdir -p "${DATA_DIR}"
  chmod 750 -R  "${DATA_DIR}"
  DBURL="postgresql://${REPLICATION_USER}:"
  DBURL+="$(tr -d '[:space:]' < "${HOME}/.pgpass")"
  DBURL+="@${REPLICATION_HOST}:${REPLICATION_PORT}/replication?"
  DBURL+="sslmode=verify-full&"
  DBURL+="sslcert=/etc/container/secrets/client-cert.pem&"
  DBURL+="sslkey=/etc/container/secrets/client-key.pem&"
  DBURL+="sslrootcert=/etc/ssl/cert.pem"
  echo "[INFO] Replica to restore: ${DBURL}"
  set +e
  # pg_basebackup --pgdata=./pgdata --dbname "${DBURL}"  --verbose --progress
  # if [ $? -ne 0 ]; then
  if ! pg_basebackup --pgdata=./pgdata --dbname "${DBURL}"  --verbose --progress; then
    echo "[WARN] Replica restore failed"
    echo "[INFO] Restore from archive(${ARCHIVE_DIR}) directory"
    # LATEST_SQL_FILE=$(find "${ARCHIVE_DIR}" -maxdepth 1 \
    #   -name "*.sql" -type f -printf "%T@ %p\n" \
    #   | sort -n | tail -1 | cut -d' ' -f2-)
    # shellcheck disable=SC2012
    LATEST_SQL_FILE="$(ls -t "${ARCHIVE_DIR}"/*.sql 2>/dev/null | head -n 1)"
    if [ -n "${LATEST_SQL_FILE}" ] ; then
      echo "[INFO] Overload restore file(${RESTORE_FILE} -> ${LATEST_SQL_FILE})"
      RESTORE_FILE="${LATEST_SQL_FILE}"
    fi
    if [ -f "${RESTORE_FILE}" ] ; then
      set -e
      echo "[INFO] Restore from file: ${RESTORE_FILE}"
      echo "[INFO] Initialize database directory: ${DATA_DIR}"
      /usr/bin/initdb "${DATA_DIR}"
      pg_ctl -D "${DATA_DIR}" start
      psql -U postgres -f "${RESTORE_FILE}"
      pg_ctl -D "${DATA_DIR}" stop
      echo "[INFO] Restored DB from file"
    else
      echo "[ERROR] Replica and  file(${RESTORE_FILE}) restore failed"
      exit 45
    fi
  fi
  set -e
  echo "[INFO] Promote primary"
  rm -rf "${DATA_DIR}/standby.signal"
  touch "${DATA_DIR}/failover.signal"
# fi # Restore
