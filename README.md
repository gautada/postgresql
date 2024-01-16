# PostgeSQL

[PostgreSQL](https://www.postgresql.org) PostgreSQL is a powerful, open source object-relational database system with over 30 years of active development that has earned it a strong reputation for reliability, feature robustness, and performance.

## Container

- To get the container up and running you must provide your own `pg_hba.conf`, `pg_ident.conf` and `postgresql.conf`.  The default config files from version 16 are attached in this project (comments removed) but you should override your own through the `/mnt/volumes/configmaps` volume. 

## Notes

- [Dockerize PostgreSQL](https://docs.docker.com/samples/postgresql_service/)
- Check that the server is up and running: ```/usr/bin/psql -c "SELECT pg_reload_conf();"```
- [Distribution packages was chosen over building from source](https://www.linuxquestions.org/questions/linux-newbie-8/advantages-and-disadvantages-of-source-over-compiled-packages-839437/) & [Deployment from code vs deployment packages](https://www.rpmdeb.com/devops-articles/deployment-from-code-vs-deployment-packages/)
- [The DevOps Guy - Postgres play list](https://www.youtube.com/playlist?list=PLHq1uqvAteVsnMSMVp-Tcb0MSBVKQ7GLg)


(ff)