#!/bin/bash

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

