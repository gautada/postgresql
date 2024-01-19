# PostgeSQL

[PostgreSQL](https://www.postgresql.org) PostgreSQL is a powerful, open source object-relational database system with over 30 years of active development that has earned it a strong reputation for reliability, feature robustness, and performance.

## Container

- To get the container up and running you must provide your own `pg_hba.conf`, `pg_ident.conf` and `postgresql.conf`.  The default config files from version 16 are attached in this project (comments removed) but you should override your own through the `/mnt/volumes/configmaps` volume. 

## SSL/TLS

TLS support is enabled by default. To to setup for testing use a self-signed certificate.

### Create Self-Signed Certificate

- Create the certificate authority root key
```
openssl req -new -nodes -text -out root.csr \
            -keyout root.key -subj "/CN=psq.gautier.org"
```
 
-  Sign the root certificate signing request  to create the root certificate (Note: the extfile path is for macOS)
 ```
 openssl x509 -req -in root.csr -text -days 3650 \
  -extfile /System/Library/OpenSSL/openssl.cnf  \
  -extensions v3_ca -signkey root.key -out root.crt
 ```
 
 - Generate the `server.key` file and the `server.csr`
 ```
 openssl req -new -nodes -text -out server.csr \
  -keyout server.key -subj "/CN=psql.gautier.org"
 ```
 
 - Finally generate the `server.crt`
 ```
 openssl x509 -req  -in server.csr -text -days 3650 \
   -CA root.crt -CAkey root.key -CAcreateserial \
   -out server.crt
 ```
### Deploy the self signed certificate 
- `server.key` and `server.crt` need to be on the postgres server as defined in the `postgresql.conf` key `ssl_key_file` and `ssl_cert_file`. 
 
- `root.crt` should be stored on the client, so the client can verify that the server’s certificate was signed by the certification authority. Note: this is only for self signed certs.
- `root.key` should be stored offline for use in creating future certificates.
- The mode of the key file must be specifically set `chmod og-rwx server.key`.
 
 
## Notes

- [Dockerize PostgreSQL](https://docs.docker.com/samples/postgresql_service/)
- Check that the server is up and running: ```/usr/bin/psql -c "SELECT pg_reload_conf();"```
- [Distribution packages was chosen over building from source](https://www.linuxquestions.org/questions/linux-newbie-8/advantages-and-disadvantages-of-source-over-compiled-packages-839437/) & [Deployment from code vs deployment packages](https://www.rpmdeb.com/devops-articles/deployment-from-code-vs-deployment-packages/)
- [The DevOps Guy - Postgres play list](https://www.youtube.com/playlist?list=PLHq1uqvAteVsnMSMVp-Tcb0MSBVKQ7GLg)


