#!/bin/bash

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
 DBURL+="$(tr -d '[:space:]' < "${HOME}/.pgpass")"
 DBURL+="${REPLICATION_HOST}:${REPLICATION_PORT}/replication?"
 DBURL+="sslmode=verify-full&"
 DBURL+="sslcert=/etc/container/secrets/client-cert.pem&"
 DBURL+="sslkey=/etc/container/secrets/client-key.pem&"
 DBURL+="${DBURL}sslrootcert=/etc/ssl/cert.pem"
 echo "[INFO] Start base backup: ***"
 pg_basebackup --pgdata=./pgdata --dbname "${DBURL}"  --verbose --progress
 touch "${DATA_DIR}/standby.signal"


