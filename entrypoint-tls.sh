#!/bin/bash

set -xue

ORIGIN_DIR="/mnt/volumes/secrets"
DEST_DIR="/etc/container/secrets"
mkdir -p "${DEST_DIR}"

if [ ! -f "${ORIGIN_DIR}/ca.pem" ] ; then
 SETUP_DIR="/home/postgres/tls"
 mkdir -p "${SETUP_DIR}"
 cd "${SETUP_DIR}" || exit 100

 # Generate CA private key
 openssl genrsa -out rootCA.key 4096

 # Create self-signed CA certificate (valid for 10 years)
 openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 3650 -out rootCA.crt \
  -subj "/C=US/ST=State/L=City/O=MyOrg/OU=IT/CN=MyPostgresCA"

 # Private key (must be 600 permissions for postgres)
 openssl genrsa -out server.key 2048
 chmod 600 server.key

 # Certificate Signing Request (CSR)
 openssl req -new -key server.key -out server.csr \
  -subj "/C=US/ST=State/L=City/O=MyOrg/OU=IT/CN=$(hostname -f)"

 # Sign the cert with rootCA
 openssl x509 -req -in server.csr -CA rootCA.crt -CAkey rootCA.key \
  -CAcreateserial -out server.crt -days 365 -sha256

  chmod 600 server.key
  chown postgres:postgres server.{crt,key}

  cp server.key "${DEST_DIR}/key.pem"
  cp server.crt "${DEST_DIR}/cert.pem"
  cp rootCA.crt "${DEST_DIR}/ca.pem"
else
  # Existing files from origin
  cp "${ORIGIN_DIR}"/*.pem "${DEST_DIR}/"
  cp "${ORIGIN_DIR}/replicator.pgpass" "/home/postgres/.pgpass"
fi

if [ ! -f "${DEST_DIR}/key.pem" ] ; then
  echo "No TLS key file"
  exit 99
fi

if [ ! -f "${DEST_DIR}/cert.pem" ] ; then
  echo "No TLS cert file"
  exit 98
fi

if [ ! -f "${DEST_DIR}/ca.pem" ] ; then
  echo "No TLS ca cert file"
  exit 97
fi


ls -al "${DEST_DIR}"/*.pem

chmod 600 "${DEST_DIR}"/*.pem

if [ ! -f "/home/postgres/.pgpass" ] ; then
  echo "no-password-provided" > /home/postgres/.pgpass
fi
chmod 600 /home/postgres/.pgpass
set +xue
