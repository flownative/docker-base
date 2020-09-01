#!/bin/bash

while true; do
    currentMinute=$(date +"%M")
    if [ "${currentMinute}" == "15" ]; then
        "${LOGROTATE_BASE_PATH}/sbin/logrotate" "--state=${LOGROTATE_BASE_PATH}/var/status" "--log=${FLOWNATIVE_LOG_PATH}/logrotate.log" --verbose "${LOGROTATE_BASE_PATH}/etc/logrotate.conf"
        sleep 10
    fi
    sleep 55
done
