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
