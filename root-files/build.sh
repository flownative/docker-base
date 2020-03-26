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

banner_flownative 'Flownative Base Image'

packages_install apt-utils ca-certificates supervisor

# Clean up a few directories / files we don't need:
rm -rf \
    /etc/supervisor

# Create directories
mkdir -p \
    "${FLOWNATIVE_INIT_PATH}/etc/init.d" \
    "${SUPERVISOR_BASE_PATH}/etc/conf.d" \
    "${SUPERVISOR_BASE_PATH}/bin" \
    "${SUPERVISOR_BASE_PATH}/tmp" \

# Move Supervisor files to correct location
mv /usr/bin/supervisord ${SUPERVISOR_BASE_PATH}/bin/
mv /usr/bin/supervisorctl ${SUPERVISOR_BASE_PATH}/bin/

chown -R 1000 \
    "${FLOWNATIVE_INIT_PATH}" \
    "${SUPERVISOR_BASE_PATH}/etc" \
    "${SUPERVISOR_BASE_PATH}/tmp"

# Clean up
packages_remove_docs_and_caches 1>$(debug_device)
rm -rf \
    /var/cache/* \
    /var/log/*
