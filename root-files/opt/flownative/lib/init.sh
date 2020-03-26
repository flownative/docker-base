#!/bin/bash
# shellcheck disable=SC1090
# shellcheck disable=SC2012

# =======================================================================================
# LIBRARY: INIT
# =======================================================================================

# This library contains functions for running initialization scripts on container start-up

# Load helper lib

. "${FLOWNATIVE_LIB_PATH}/log.sh"

# ---------------------------------------------------------------------------------------
# init_run() - Run initialization scripts
#
# @global FLOWNATIVE_INIT_PATH
# @return void
#
init_run() {
    shopt -s nullglob
    shopt -s dotglob

    files_check=("${FLOWNATIVE_INIT_PATH}/etc/init.d"/*.sh)
    if (( ${#files_check[*]} )); then
        for file in $(ls "${FLOWNATIVE_INIT_PATH}/etc/init.d"/*.sh | sort -V); do
            filename=$(basename "$file")
            info "Init: Running ${filename} ..."
            $file | (sed "s/^/${filename}: /" | output)
        done;
    else
        info "Init: No custom init scripts found"
    fi
}
