# PostgeSQL

[PostgreSQL](https://www.postgresql.org) PostgreSQL is a powerful, open source object-relational database system with over 30 years of active development that has earned it a strong reputation for reliability, feature robustness, and performance.



https://docs.docker.com/engine/examples/postgresql_service/

## Container

### Versions

- [September 1, 2021](https://www.postgresql.org/docs/) - Active version is 13.4 as tag [REL_13_4](https://github.com/postgres/postgres/tags)

### Manual (Docker)

#### Build

```
docker build --build-arg ALPINE_TAG=3.14.1 --build-arg BRANCH=REL_13_4 --tag psql:dev -f Containerfile . 
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

