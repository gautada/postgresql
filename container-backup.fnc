#!/bin/sh

container_backup() {
 /usr/bin/pg_dumpall -h localhost
}
