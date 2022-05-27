# PostgeSQL

[PostgreSQL](https://www.postgresql.org) PostgreSQL is a powerful, open source object-relational database system with over 30 years of active development that has earned it a strong reputation for reliability, feature robustness, and performance.

To make administration more accessible and to make that overall usage easier this container also incorporates [pgwb](http://sosedoff.github.io/pgweb/) - Pgweb is a web-based database browser for PostgreSQL, written in Go and works on OSX, Linux and Windows machines. Main idea behind using Go for backend development is to utilize ability of the compiler to produce zero-dependency binaries for multiple platforms. Pgweb was created as an attempt to build very simple and portable application to work with local or remote PostgreSQL databases.

https://docs.docker.com/engine/examples/postgresql_service/

## Container

### Versions

#### PostgreSQL

- [September 1, 2021](https://www.postgresql.org/docs/) - Active version is 13.4 as tag [REL_13_4](https://github.com/postgres/postgres/tags)
- [May 26, 2022](https://www.postgresql.org/docs/) - Active version is 14.3 as tag [REL_14_3](https://github.com/postgres/postgres/tags)

#### pgwb

- [May 29, 2022](http://sosedoff.github.io/pgweb/) - Active version is 0.11.11 as tag [v0.11.11](https://github.com/sosedoff/pgweb/tags)

### Build

```
docker build --build-arg ALPINE_VERSION=3.15.4 --build-arg POSTGRES_VERSION=14_3 --file Containerfile --no-cache --tag postgres:dev .
```

### Run
```
docker run --interactive --tty --name postgres --publish 5432:5432 --volume ~/Workspace/postgres/postgres-container:/opt/postgres --rm postgres:dev /usr/local/pgsql/bin/psql
``` 

#### Run
```
docker run -i -p 4321:43231 -t --name psql --rm psql:dev
```

Update pg_hba.conf without restart.

https://github.com/citusdata/pg_auto_failover/issues/67
```
k exec -n data pods/postgres-0 -it -- /usr/bin/psql -c "SELECT pg_reload_conf();"
```

docker build --build-arg ALPINE_VERSION=3.15.4 --build-arg POSTGRES_VERSION=16_4 --file Containerfile --no-cache --tag gitea:dev .


docker run --interactive --tty --name gitea --publish 8080:8080 --volume ~/Workspace/drone/gitea-container:/opt/gitea --rm gitea:dev /usr/bin/gitea --config /opt/gitea/app.ini --work-path /opt/gitea --custom-path /opt/gitea/customv web --port 8080



