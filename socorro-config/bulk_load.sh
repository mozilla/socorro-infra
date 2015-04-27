#!/usr/bin/env bash

for conf in *.conf; do
    echo "Bulk loading $conf"
    cat $conf | grep -v '^#' | while read line; do
        key=$(echo $line | cut -d= -f1)
        value=$(echo $line | cut -d= -f2-)
        prefix="socorro/$(basename -s .conf $conf)"
        result=$(curl -s -X PUT -d "$value" http://localhost:8500/v1/kv/$prefix/$key)
        if [ "$result" != "true" ]; then
            echo "ERROR loading $value into $key for $prefix"
            exit 1
        fi
    done
done
