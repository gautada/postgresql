# PostgeSQL

[PostgreSQL](https://www.postgresql.org) PostgreSQL is a powerful, open
source object-relational database system with over 30 years of active
development that has earned it a strong reputation for reliability,
feature robustness, and performance.

This image package is called `postgresql`. The server name will be
`postgres.domain.tld`.  This is in view of the long standing
[naming issue](https://wiki.postgresql.org/wiki/Postgres) that is known
within the community.

## Version

Currently this image is based on
[PostgreSQL 15](https://www.postgresql.org/docs/15/index.html). Check
the specific version of the [package](https://pkgs.alpinelinux.org/packages?name=postgresql15&branch=v3.21&repo=community&arch=aarch64&origin=&flagged=&maintainer=)
in the Alpine Packages Repository.

## Configuration

To get the container up and running you must provide your own `pg_hba.conf`,
`pg_ident.conf` and `postgresql.conf`.  The default config files from
version 15 are attached in this project (comments removed) but you should
override deployment configuration via configmaps.

- **pg_hba.conf**:  (PostgreSQL Host-Based Authentication) file is a
configuration file used by PostgreSQL to control client authentication.
It defines which users can connect, from where, using which authentication
method.
- **pg_ident.conf**: is used for username mapping
between external authentication systems (such as OS users or Kerberos) and
PostgreSQL database users. It is mainly used when authentication methods like
peer, ident, or gss require mapping between system usernames and database
roles.
- **postgresql.conf**: is the main configuration file for PostgreSQL. It
controls server behavior, resource usage, logging, networking,
and performance tuning.

## Databases

### Lists databases

To list all of the database on the server use `\list`

## Users

Replicator user is needed to support replica backups

```sh
/usr/bin/createuser --username=postgres --pwprompt --connection-limit=5 \
                    --replication replicator
```

### List users

To list all of the user on the server use `\du`.

### Encrypted passwords

#### Enable encrypted passwords

In the `postgresql.conf` file enable encrypted password by added
`password_encryption = scram-sha-256`.

#### Set a user password

```sql
ALTER USER myuser WITH ENCRYPTED PASSWORD 'mypassword';
```

#### Check a user has password set

```sql
SELECT rolname, rolpassword FROM pg_authid WHERE rolname = 'myuser';
```

#### Change database owner

```sql
ALTER DATABASE mydb OWNER TO newuser;
```

#### Rename existing user

```sql
ALTER ROLE test RENAME to test;
```

### TLS Setup

#### Create Secret

```sh
kubectl create secret -n data generic postgresql \
  --from-file=key.pem=key.pem \
  --from-file=cert.pem=cert.pem \
  --from-file=ca.pem=ca.pem \
  --from-file=client-cert.pem=../client/cert.pem \
  --from-file=client-key.pem=../client/key.pem \
  --from-file=replicator.pgpass=../client/replicator.pgpass
```

## Notes

- [Postgresql Video Series](https://www.youtube.com/playlist?list=PLHq1uqvAteVsnMSMVp-Tcb0MSBVKQ7GLg)
with supporting [materials](https://github.com/marcel-dempers/docker-development-youtube-series)
- Testing

### PRIMARY

```sh
/usr/bin/podman run --name pg_primary \
    --env POSTGRESQL_SERVER_TYPE=master \
--env POSTGRESQL_CONFIG_FILE=/mnt/volumes/configmaps/primary/postgresql.conf \
--env POSTGRESQL_REPLICA_HOST=replica.postgresql.gautier.org \
--env POSTGRESQL_REPLICA_PORT=5433 \
--env POSTGRESQL_REPLICA_USER=replicator \
    --interactive \
    --publish 5432:5432 \
    --rm \
    --tty \
    --volume Backup:/mnt/volumes/backups \
    --volume Data:/mnt/volumes/container \
    --volume Configmaps:/mnt/volumes/configmaps \
    --volume Secrets:/mnt/volumes/secrets \
      docker.io/gautada/postgresql:dev
```

### REPLICA

```sh
/usr/bin/podman run --name pg_replica \
    --env POSTGRESQL_SERVER_TYPE=replica \
--env POSTGRESQL_CONFIG_FILE=/mnt/volumes/configmaps/replica/postgresql.conf \
    --env POSTGRESQL_PRIMARY_HOST=primary.postgresql.gautier.org \
    --env POSTGRESQL_PRIMARY_USER=replicator \
    --interactive \
    --publish 5433:5432 \
    --rm \
    --tty \
    --volume Backup:/mnt/volumes/backups \
    --volume Data:/mnt/volumes/container \
    --volume Configmaps:/mnt/volumes/configmaps \
    --volume Secrets:/mnt/volumes/secrets \
      docker.io/gautada/postgresql:dev
```
