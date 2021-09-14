#!/bin/bash
# shellcheck disable=SC1090
# shellcheck disable=SC2086
# shellcheck disable=SC2046

# Load helper libraries

. "${FLOWNATIVE_LIB_PATH}/log.sh"
. "${FLOWNATIVE_LIB_PATH}/banner.sh"
. "${FLOWNATIVE_LIB_PATH}/packages.sh"

set -o errexit
set -o nounset
set -o pipefail

# ---------------------------------------------------------------------------------------
# Main routine

export FLOWNATIVE_LOG_PATH_AND_FILENAME=/dev/stdout

banner_flownative 'Flownative Base Image'

packages_install dpkg apt-utils ca-certificates supervisor syslog-ng logrotate

# Clean up a few directories / files we don't need:
rm -rf \
    /etc/supervisor

# Create directories
mkdir -p \
    "${FLOWNATIVE_INIT_PATH}/etc/init.d" \
    "${FLOWNATIVE_LOG_PATH}" \
    "${SYSLOG_BASE_PATH}/etc" \
    "${SYSLOG_BASE_PATH}/sbin" \
    "${SYSLOG_BASE_PATH}/var" \
    "${SYSLOG_BASE_PATH}/tmp" \
    "${LOGROTATE_BASE_PATH}/etc/conf.d" \
    "${LOGROTATE_BASE_PATH}/log" \
    "${LOGROTATE_BASE_PATH}/sbin" \
    "${LOGROTATE_BASE_PATH}/var" \
    "${SUPERVISOR_BASE_PATH}/etc/conf.d" \
    "${SUPERVISOR_BASE_PATH}/bin" \
    "${SUPERVISOR_BASE_PATH}/tmp" \

# Move syslog-ng files to correct location
rm /etc/default/syslog-ng
mv /usr/sbin/syslog-ng* ${SYSLOG_BASE_PATH}/sbin/
ln -s ${SYSLOG_BASE_PATH}/tmp/syslog-ng.ctl /var/lib/syslog-ng/syslog-ng.ctl

# Move logrotate files to correct location
rm -rf /etc/logrotate.d
mv /usr/sbin/logrotate ${LOGROTATE_BASE_PATH}/sbin/
mv /etc/logrotate.conf ${LOGROTATE_BASE_PATH}/etc/

# Move Supervisor files to correct location
rm /etc/default/supervisor
mv /usr/bin/supervisord ${SUPERVISOR_BASE_PATH}/bin/
mv /usr/bin/supervisorctl ${SUPERVISOR_BASE_PATH}/bin/

chown -R 1000:1000 \
    "${FLOWNATIVE_INIT_PATH}" \
    "${FLOWNATIVE_LOG_PATH}" \
    "${SYSLOG_BASE_PATH}/etc" \
    "${SYSLOG_BASE_PATH}/var" \
    "${SYSLOG_BASE_PATH}/tmp" \
    "${LOGROTATE_BASE_PATH}/etc" \
    "${LOGROTATE_BASE_PATH}/log" \
    "${LOGROTATE_BASE_PATH}/sbin" \
    "${LOGROTATE_BASE_PATH}/var" \
    "${SUPERVISOR_BASE_PATH}/etc" \
    "${SUPERVISOR_BASE_PATH}/tmp"

# Clean up
packages_remove_docs_and_caches 1>$(debug_device)
rm -rf \
    /var/cache/* \
    /var/log/*
