# PostgeSQL

[PostgreSQL](https://www.postgresql.org) PostgreSQL is a powerful, open source object-relational database system with over 30 years of active development that has earned it a strong reputation for reliability, feature robustness, and performance.

To make administration more accessible and to make the overall usage easier this container also incorporates [pgwb](http://sosedoff.github.io/pgweb/) - **pgweb** is a web-based database browser for PostgreSQL, written in Go with zero-dependency binaries. Pgweb was created as an attempt to build very simple and portable application to work with local or remote PostgreSQL databases.


## Change Log

- [September 1, 2021](https://github.com/postgres/postgres/tags) Version Update to 13.4 as tag REL_13_4
- [May 26, 2022](https://github.com/postgres/postgres/tags) -  Version Update to 14.3 as tag REL_14_3
- [May 29, 2022](http://sosedoff.github.io/pgweb/) - Added pgweb version is 0.11.11 as tag [v0.11.11](https://github.com/sosedoff/pgweb/tags)
 
## Notes

- [Dockerize PostgreSQL](https://docs.docker.com/samples/postgresql_service/)
- Check that the server is up and running:

```
/usr/bin/psql -c "SELECT pg_reload_conf();"
```

Principle

A distribution's package is prefered over building from source over.

https://www.linuxquestions.org/questions/linux-newbie-8/advantages-and-disadvantages-of-source-over-compiled-packages-839437/
https://www.rpmdeb.com/devops-articles/deployment-from-code-vs-deployment-packages/

