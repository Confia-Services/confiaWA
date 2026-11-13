#!/usr/bin/env bash
# Rebuilds the Confía database from scratch on a local Postgres and prints a catalog fingerprint.
#
#   0000_baseline.sql  →  0011 … 0018  →  seed.sql
#
# Requirements: psql with a superuser connection (standard PG* env vars), Postgres 16+, pg_cron installed
# and preloaded with  shared_preload_libraries='pg_cron'  and  cron.database_name='<DBNAME>'  (0015 needs it).
# The Supabase platform pieces the migrations rely on (roles, auth.uid(), storage.buckets …) are stubbed
# by _supabase_stub.sql.
#
# Usage:   DBNAME=confia_test supabase/tests/run_local.sh
# Compare: run supabase/tests/schema_catalog.sql on confia-prod and diff the md5 column printed at the end.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SUPA="$(cd "$HERE/.." && pwd)"
DBNAME="${DBNAME:-confia_test}"
PSQL="psql -X -q -v ON_ERROR_STOP=1"

echo "== recreate database $DBNAME"
$PSQL -d postgres -c "drop database if exists $DBNAME with (force)"
$PSQL -d postgres -c "create database $DBNAME"

echo "== platform stub"
$PSQL -d "$DBNAME" -f "$HERE/_supabase_stub.sql"

echo "== migrations"
for f in $(ls "$SUPA"/migrations/*.sql | sort); do
  echo "   $(basename "$f")"
  $PSQL -d "$DBNAME" -f "$f"
done

echo "== seed"
$PSQL -d "$DBNAME" -f "$SUPA/seed.sql"

if [ -f "$HERE/smoke.sql" ]; then
  echo "== smoke test"
  $PSQL -d "$DBNAME" -f "$HERE/smoke.sql"
fi

echo "== catalog fingerprint (class | md5 | length)"
$PSQL -d "$DBNAME" -At -F ' | ' -c "$(sed '$d' "$HERE/schema_catalog.sql") select k, md5(coalesce(v,'')), length(coalesce(v,'')) from cat order by k"
echo "OK"
