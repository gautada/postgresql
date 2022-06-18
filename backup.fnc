#!/bin/sh

container_backup() {
 /usr/bin/pg_dumpall --username=postgres --host=localhost > postgresql_dumpall.sql
}
