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

### List users

To list all of the user on the server use `\du`.

### Encrypted passwords

#### Enable encrypted passwords

In the `postgresql.conf` file enable encrypted password by added `password_encryption = scram-sha-256`.

#### Set a user password

```sql
ALTER USER myuser WITH ENCRYPTED PASSWORD 'mypassword';
```

#### Check a user has password set

```sql
SELECT rolname, rolpassword FROM pg_authid WHERE rolname = 'myuser';
```

#### Change database owner;

```
ALTER DATABASE mydb OWNER TO newuser;
```

#### Rename existing user

```
ALTER ROLE test RENAME to test;
```
### TLS Setup

## Notes

- [Postgresql Video Series](https://www.youtube.com/playlist?list=PLHq1uqvAteVsnMSMVp-Tcb0MSBVKQ7GLg)
with supporting [materials](https://github.com/marcel-dempers/docker-development-youtube-series)
