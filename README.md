# PostgeSQL

[PostgreSQL](https://www.postgresql.org) PostgreSQL is a powerful, open  
source object-relational database system with over 30 years of active  
development that has earned it a strong reputation for reliability,  
feature robustness, and performance.  

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

## SSL/TLS

TLS support is enabled by default. To to setup for testing use a self-signed certificate.  

### Create Self-Signed Certificate

- Create the certificate authority root key  
```sh
openssl req -new -nodes -text -out root.csr \
            -keyout root.key -subj "/CN=psq.gautier.org"
```
 
-  Sign the root certificate signing request  to create the root certificate 
(Note: the extfile path is for macOS)  
 ```sh
 openssl x509 -req -in root.csr -text -days 3650 \
  -extfile /System/Library/OpenSSL/openssl.cnf  \
  -extensions v3_ca -signkey root.key -out root.crt
 ```
 
 - Generate the `server.key` file and the `server.csr`
 ```sh
 openssl req -new -nodes -text -out server.csr \
  -keyout server.key -subj "/CN=psql.gautier.org"
 ```
 
 - Finally generate the `server.crt`
 ```sh
 openssl x509 -req  -in server.csr -text -days 3650 \
   -CA root.crt -CAkey root.key -CAcreateserial \
   -out server.crt
 ```
### Deploy the self signed certificate 
- `server.key` and `server.crt` need to be on the postgres server as defined in the `postgresql.conf` key `ssl_key_file` and `ssl_cert_file`.  
 
- `root.crt` should be stored on the client, so the client can verify that the server’s certificate was signed by the certification authority. Note: this is only for self signed certs.  
- `root.key` should be stored offline for use in creating future certificates.  
- The mode of the key file must be specifically set `chmod og-rwx server.key`.  
 
### Configure 

```sh
# | SSL/TLS
# ╰―――――――――――――――――――――――――
ssl = on
ssl_key_file = '/mnt/volumes/secrets/tls.key'
ssl_cert_file = '/mnt/volumes/secrets/tls.crt'
#ssl_ca_file = ''
#ssl_crl_file = ''
#ssl_ciphers = 'HIGH:MEDIUM:+3DES:!aNULL' # allowed SSL ciphers
#ssl_prefer_server_ciphers = on
#ssl_ecdh_curve = 'prime256v1'
#ssl_min_protocol_version = 'TLSv1.2'
#ssl_max_protocol_version = ''
#ssl_dh_params_file = ''
#ssl_passphrase_command = ''
#ssl_passphrase_command_supports_reload = off
```

## Availability

This container is designed to deploy in a kubernetes cluster.  The deployment mechanism provides an availability of 99.9% (Downtime Monthly: 4m 21s). Higher availability is not needed as this database backs applications that have a limited user base and has zero public access.

### Maintenance

Downtime due to maintenance is mitigated with local development environment based on compose and the CICD process.

### Disaster Recovery

Currently disaster recover is manual.  The container health mechanism should provide the advanced notice of disaster states that would cause down-time.

hc-disk
hc-postgres

## Notes

- [Dockerize PostgreSQL](https://docs.docker.com/samples/postgresql_service/)
- Check that the server is up and running: ```/usr/bin/psql -c "SELECT pg_reload_conf();"```
- [Distribution packages was chosen over building from source](https://www.linuxquestions.org/questions/linux-newbie-8/advantages-and-disadvantages-of-source-over-compiled-packages-839437/) & [Deployment from code vs deployment packages](https://www.rpmdeb.com/devops-articles/deployment-from-code-vs-deployment-packages/)
- [The DevOps Guy - Postgres play list](https://www.youtube.com/playlist?list=PLHq1uqvAteVsnMSMVp-Tcb0MSBVKQ7GLg)
- 2024-01-25 - Added and [enabled](https://dba.stackexchange.com/questions/165300/how-to-install-the-additional-module-pg-trgm) the pg_trgm extension (support for similarity of text using trigram matching) used in the tandoor-container.
- 2024-02-05: Updating to use the hourly backup mechanism.

