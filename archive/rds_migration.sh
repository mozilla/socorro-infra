#!/usr/bin/env bash

# This script attempts to migrate an existing Socorro install on a
# traditional PostgreSQL server to Amazon AWS RDS.
#
# This is done in three phases:
# 1) transfer schema
# 2) transfer "core" dataset (enough for processing+webapp to work)
# 3) transfer historical dataset
#
# As of this writing, RDS has some restrictions such as inability to
# disable foreign keys, so we need to care about table order and don't
# make as much use of pg_restore's parallel restore option as would be ideal.
#
# NOTE - you most likely want to use the latest version of pg_dump, this
# should be safe to do against older database. If you get errors about
# tables already being in use, this is likely the cause.
#
# Also - the existing Socorro schema has some cruft leftover from old
# extensions such as citext. These are safe to ignore, but (as always)
# carefully review the logs.

set -e
set -x
set -f

if [ -z "$RDS_DB" ]; then
    echo "RDS_DB must be set"
    exit 1
elif [ ! -f tables_core.txt ] || [ ! -f tables_historical.txt ]; then
    echo "tables_core.txt and tables_historical.txt must exist"
    exit 1
fi

# Initial setup
function setup {
    psql -U root -h "$RDS_DB" -c \
      "CREATE DATABASE breakpad" template1
    psql -U root -h "$RDS_DB" -c \
      "CREATE USER breakpad_rw PASSWORD 'aPassword'" breakpad
    psql -U root -h "$RDS_DB" -c \
      "GRANT ALL ON DATABASE breakpad TO breakpad_rw" breakpad
    psql -U root -h "$RDS_DB" -c \
      "CREATE EXTENSION citext" breakpad
}

# phase 1 - transfer schema
function transfer_schema {
    # we expect warnings here about citext and pg_enhancements and plperl
    # this is cruft from old versions of extensions
    set +e
    pg_dump \
      --format=c \
      --no-owner \
      --no-privileges \
      --schema-only breakpad \
      --exclude-schema pg_catalog \
      -Z 9 | pg_restore \
        --no-owner \
        --no-privileges \
        --schema-only \
        -h "$RDS_DB" \
        -U breakpad_rw \
        -d breakpad
    set -e
}

# phase 2 - migrate core data
# take a list of tables to migrate and create a pgdump
function dump_data {
    if [ "$#" != "1" ]; then
        echo "Syntax: restore_data <table>"
        return 1
    fi
    TABLE=$1

    echo "Dumping $TABLE"
    pg_dump \
      --format=c \
      --no-owner \
      --no-privileges \
      --data-only \
      -t "$TABLE" \
      -f /pgdata/scratch/breakpad_"${TABLE}".pg \
      breakpad
}

# restore the data in the order specified
function restore_data {
    if [ "$#" != "1" ]; then
        echo "Syntax: restore_data <table>"
        return 1
    fi
    TABLE=$1

    echo "Restoring $TABLE"
    pg_restore \
      --format=c \
      -t "$TABLE" \
      --no-owner \
      --no-privileges \
      --data-only \
      -h "$RDS_DB" \
      -U breakpad_rw \
      -d breakpad \
      -w /pgdata/scratch/breakpad_"${TABLE}".pg
}

echo "Phase 1 - Initializing database and transfering schema"
setup
transfer_schema
echo "Phase 2 - Transfering core data"
# all non-partitioned tables except raw_adi* and missing_symbols
while read table; do
    time dump_data "$table"
    time restore_data "$table"
done < tables_core.txt
echo "Phase 3 - Transfering historical data"
# generate sorted list of partition tables with:
# psql breakpad -c '\dt' | awk '{print $3}' | grep '_20' | sort -t 2 -k 2 -rn
# * grep out "raw_crashes" and "processed_crashes"
# * remove the active partitions
# transfer raw_adi* last
while read table; do
    time dump_data "$table"
    time restore_data "$table"
done < tables_historical.txt
echo "Phase 4 - fix sequences"
# see https://wiki.postgresql.org/wiki/Fixing_Sequences
psql -Atq -f fix_sequences.sql -o temp
psql -f temp
rm temp
