#!/bin/bash
# shellcheck disable=SC1090

# =======================================================================================
# LIBRARY: SYSLOG-NG
# =======================================================================================

# This library contains functions for running syslog-ng

# Load helper lib

. "${FLOWNATIVE_LIB_PATH}/log.sh"
. "${FLOWNATIVE_LIB_PATH}/process.sh"

# ---------------------------------------------------------------------------------------
# syslog_env() - Load global environment variables for configuring syslog-ng
#
# @global SYSLOG_*, LOGROTATE_BASE_PATH The SYSLOG_ and LOGROTATE_BASE_PATH environment variables
# @return "export" statements which can be passed to eval()
#
syslog_env() {
    cat <<"EOF"
export SYSLOG_BASE_PATH="${SYSLOG_BASE_PATH}"
export SYSLOG_ENABLE=${SYSLOG_ENABLE:-true}
export SYSLOG_JSON=${SYSLOG_JSON:-false}
export PATH=${PATH}:${SYSLOG_BASE_PATH}/sbin:${LOGROTATE_BASE_PATH}/sbin
EOF
}

# ---------------------------------------------------------------------------------------
# syslog_get_pid() - Return the syslog-ng process id
#
# @global SYSLOG_* The SYSLOG_ environment variables
# @return Returns the Supervisor process id, if it is running, otherwise 0
#
syslog_get_pid() {
    local pid
    pid=$(process_get_pid_from_file "${SYSLOG_BASE_PATH}/tmp/syslog-ng.pid")

    if [[ -n "${pid}" ]]; then
        echo "${pid}"
    else
        false
    fi
}

# ---------------------------------------------------------------------------------------
# syslog_has_pid() - Checks if a PID file exists
#
# @global SYSLOG_* The SYSLOG_ environment variables
# @return Returns false if no PID file exists
#
syslog_has_pid() {
    if [[ ! -f "${SYSLOG_BASE_PATH}/tmp/syslog-ng.pid" ]]; then
        false
    fi
}

# ---------------------------------------------------------------------------------------
# syslog_start() - Start syslog-ng
#
# @global SYSLOG_* The SYSLOG_ environment variables
# @return void
#
syslog_start() {
    local pid

    info "syslog-ng: Starting ..."

    # Determine output mode on /dev/stdout
    if [ -p /dev/stdout ]; then
        export SYSLOG_DESTINATION_STDOUT_MODE=pipe
    else
        export SYSLOG_DESTINATION_STDOUT_MODE=file
    fi

    # shellcheck disable=SC2016
    export SYSLOG_DESTINATION_STDOUT_TEMPLATE=${SYSLOG_DESTINATION_STDOUT_TEMPLATE:-'${HOUR}:${MIN}:${SEC} ${TZ} ${HOST} [${LEVEL}] ${MESSAGE}'}

    if is_boolean_yes "${SYSLOG_JSON}"; then
        info "syslog-ng: Logging mode is JSON"
        export SYSLOG_DESTINATION_STDOUT_DEVICE=/dev/null
        export SYSLOG_DESTINATION_STDOUT_JSON_DEVICE=/dev/stdout
    else
        info "syslog-ng: Logging mode is text"
        export SYSLOG_DESTINATION_STDOUT_DEVICE=/dev/stdout
        export SYSLOG_DESTINATION_STDOUT_JSON_DEVICE=/dev/null
    fi

    "${SYSLOG_BASE_PATH}/sbin/syslog-ng" \
        --cfgfile="${SYSLOG_BASE_PATH}/etc/syslog-ng.conf" \
        --control="${SYSLOG_BASE_PATH}/tmp/syslog-ng.ctl" \
        --persist-file="${SYSLOG_BASE_PATH}/var/syslog-ng.persist" \
        --pidfile="${SYSLOG_BASE_PATH}/tmp/syslog-ng.pid" \
        --foreground \
        --no-caps &

    sleep 1
    with_backoff "syslog_has_pid" || (
        error "syslog-ng: Could not retrieve PID of the syslog-ng process, maybe it failed during start-up?"
        exit 1
    )
    pid=$(syslog_get_pid)

    info "syslog-ng: Running as process #${pid}"
}

# ---------------------------------------------------------------------------------------
# syslog_stop() - Stop the syslog-ng process based on the current PID
#
# @global SYSLOG_* The SYSLOG_ environment variables
# @return void
#
syslog_stop() {
    local pid

    info "syslog-ng: Stopping ..."

    pid=$(syslog_get_pid)
    kill "${pid}"
}

# ---------------------------------------------------------------------------------------
# syslog_initialize() - Set up configuration
#
# @global SYSLOG_* The SYSLOG_* environment variables
# @return void
#
syslog_initialize() {
    if [[ $(id --user) == 0 ]]; then
        error "syslog-ng: Container is running as root, but only unprivileged users are supported"
        exit 1
    fi
}
