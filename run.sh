#!/bin/bash

function writeSentinelConfig() {
    if [[ ! -e /redis-sentinel-data ]]; then
        mkdir /redis-sentinel-data
    fi
    master=$1
    sentinel_conf=/redis-sentinel-data/${master}_sentinel.conf
    echo "sentinel monitor mymaster ${master} 6379 2" > ${sentinel_conf}
    echo "sentinel down-after-milliseconds mymaster 60000" >> ${sentinel_conf}
    echo "sentinel failover-timeout mymaster 120000" >> ${sentinel_conf}
    echo "sentinel parallel-syncs mymaster 1" >> ${sentinel_conf}
    echo "sentinel auth-pass mymaster 1234abcd" >> ${sentinel_conf}
}

function launchmaster() {
  if [[ ! -e /redis-master-data ]]; then
    echo "Redis master data doesn't exist, data won't be persistent!"
    mkdir /redis-master-data
  fi
  redis-server /redis-master/redis.conf
  master=$(hostname -i)
  writeSentinelConfig ${master}
  redis-sentinel /redis-sentinel-data/${master}_sentinel.conf
  echo "Master started" >> /redis-master-data/log
}

function launchsentinel() {
  while true; do
    master=$(redis-cli -h ${SENTINEL_MASTER_HOST} -p 26379 --csv SENTINEL get-master-addr-by-name mymaster | tr ',' ' ' | cut -d' ' -f1)
    if [[ -n ${master} ]]; then
      master="${master//\"}"
    else
      echo "Could not get master info"
      exit 1
    fi

    redis-cli -h ${master} INFO
    if [[ "$?" == "0" ]]; then
      break
    fi
    echo "Connecting to master failed.  Waiting..."
    sleep 10
  done
  sed -i "s/master-ip/${master}/g" /redis-slave/redis.conf
  redis-server /redis-slave/redis.conf
  writeSentinelConfig ${master}
  echo "slaveof ${master} 6379" >> ${sentinel_conf}
  redis-sentinel ${sentinel_conf}
}

if [[ "${SLAVE}" == "true" ]]; then
  launchsentinel
  exit 0
fi

launchmaster
