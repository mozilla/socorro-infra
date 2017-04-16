#!/usr/bin/env bash

if [ "$1" == "" ]; then
    echo "Usage: $0 <app>"
    echo "valid app names are: consul, elasticsearch, postgres, rabbitmq, webapp"
    exit 1
fi

app=$1

case $app in

consul)
  # FIXME download socorro-config backup from S3?
  tar zxf socorro-config.tar.gz
  pushd socorro-config
  ./bulk_load.sh
  popd

elasticsearch)
  sudo setup-socorro.sh elasticsearch
  ;;

postgres)
  sudo /usr/pgsql-9.3/bin/postgresql93-setup initdb
  echo FIXME, add listen_addresses = '*' to
  echo in: /var/lib/pgsql/9.3/data/postgresql.conf
  echo FIXME, set "md5" for 172.*
  echo in: /var/lib/pgsql/9.3/data/pg_hba.conf 
  sudo systemctl restart postgresql-9.3
  sudo setup-socorro.sh postgres
  echo FIXME change the password for the breakpad_rw role:
  echo psql -c "ALTER ROLE breakpad_rw WITH PASSWORD '...';"
  ;;

rabbitmq)
  if [ -n "$RABBIT_PASSWORD" ]; then
      echo "please set the RABBIT_PASSWORD env var"
      exit 1
  fi
  sudo rabbitmqctl add_user socorro ${RABBIT_PASSWORD}
  sudo rabbitmqctl set_permissions -p / socorro ".*" ".*" "."
  ;;

webapp)
  sudo setup-socorro.sh webapp
  echo FIXME use elasticache?
  sudo yum install memcached
  sudo systemctl start memcached
  ;;

esac
