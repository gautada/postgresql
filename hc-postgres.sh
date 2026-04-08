#!/bin/ash
# shellcheck shell=dash
# hc-postgres: Container postgres health check script
# Return 0 if healthy, 1 if unhealthy

HEALTH=0

# Check 1: Postgres process is running
# We use pgrep to check if postgres processes exist.
# -x ensures exact match for the command name.
if ! pgrep -x postgres > /dev/null; then
    echo "UNHEALTHY: Postgres process is NOT running." >&2
    exit 1
fi

# Check 2: pg_isready for local connection
# This confirms the server is accepting connections (ready).
if ! /usr/bin/pg_isready -h localhost > /dev/null 2>&1; then
    echo "UNHEALTHY: Postgres is NOT ready for local connections." >&2
    exit 1
fi

# Check 3: psql query execution
# This confirms we can successfully execute a SQL command.
# We use the system user (usually postgres) to connect.
# shellcheck disable=SC2016
if ! /usr/bin/psql -h localhost -U "${POSTGRES_USER:-postgres}" -c "SELECT 1" > /dev/null 2>&1; then
    echo "UNHEALTHY: Could not execute 'SELECT 1' against postgres." >&2
    exit 1
fi

echo "HEALTHY: Postgres is running, ready, and responding to queries."
exit "$HEALTH"
