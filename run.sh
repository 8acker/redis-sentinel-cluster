#!/bin/bash

function writeSentinelConfig() {
    if [[ ! -e /redis-sentinel-data ]]; then
        mkdir /redis-sentinel-data
    fi
    master=$1
    sentinel_conf=/redis-sentinel-data/${master}_sentinel.conf
    echo "sentinel monitor mymaster ${master} 6379 2" > ${sentinel_conf}
    echo "sentinel down-after-milliseconds mymaster 60000" >> ${sentinel_conf}
    echo "sentinel failover-timeout mymaster 180000" >> ${sentinel_conf}
    echo "sentinel parallel-syncs mymaster 1" >> ${sentinel_conf}
}

function addSlaveOf() {
    master=$1
    sentinel_conf=/redis-sentinel-data/${master}_sentinel.conf
    echo "slaveof ${master} 6379" >> ${sentinel_conf}
}

function launchmaster() {
  if [[ ! -e /redis-master-data ]]; then
    echo "Redis master data doesn't exist, data won't be persistent!"
    mkdir /redis-master-data
  fi
  master=$(hostname -i)
  writeSentinelConfig ${master}
  redis-server /redis-master/redis.conf
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

  writeSentinelConfig ${master}
  addSlaveOf ${master}
  redis-sentinel ${sentinel_conf}
  echo "${master} Sentinel started" >> /redis-sentinel-data/log
}

if [[ "${SLAVE}" == "true" ]]; then
  launchsentinel
  exit 0
fi

launchmaster
