#!/bin/bash
# shellcheck disable=SC1090

# =======================================================================================
# LIBRARY: SUPERVISOR
# =======================================================================================

# This library contains functions for running and watching services with Supervisor

# Load helper lib

. "${FLOWNATIVE_LIB_PATH}/log.sh"
. "${FLOWNATIVE_LIB_PATH}/process.sh"

# ---------------------------------------------------------------------------------------
# supervisor_env() - Load global environment variables for configuring Supervisor
#
# @global SUPERVISOR_* The SUPERVISOR_ environment variables
# @return "export" statements which can be passed to eval()
#
supervisor_env() {
    cat <<"EOF"
export SUPERVISOR_BASE_PATH="${SUPERVISOR_BASE_PATH}"
export PATH=${PATH}:${SUPERVISOR_BASE_PATH}/bin
EOF
}

# ---------------------------------------------------------------------------------------
# supervisor_get_pid() - Return the Supervisor process id
#
# @global SUPERVISOR_* The SUPERVISOR_ environment variables
# @return Returns the Supervisor process id, if it is running, otherwise 0
#
supervisor_get_pid() {
    local pid
    pid=$(process_get_pid_from_file "${SUPERVISOR_BASE_PATH}/tmp/supervisord.pid")

    if [[ -n "${pid}" ]]; then
        echo "${pid}"
    else
        false
    fi
}

# ---------------------------------------------------------------------------------------
# supervisor_has_pid() - Checks if a PID file exists
#
# @global SUPERVISOR_* The SUPERVISOR_ environment variables
# @return Returns false if no PID file exists
#
supervisor_has_pid() {
    if [[ ! -f "${SUPERVISOR_BASE_PATH}/tmp/supervisord.pid" ]]; then
        false
    fi
}


# ---------------------------------------------------------------------------------------
# supervisor_start() - Start Supervisor
#
# @global SUPERVISOR_* The SUPERVISOR_ environment variables
# @return void
#
supervisor_start() {
    local pid

    info "Supervisor: Starting ..."
    "${SUPERVISOR_BASE_PATH}/bin/supervisord" -c "${SUPERVISOR_BASE_PATH}/etc/supervisord.conf" &

    sleep 1
    with_backoff "supervisor_has_pid" || (error "Supervisor: Could not retrieve PID of the supervisord process, maybe it failed during start-up?"; exit 1)
    pid=$(supervisor_get_pid)

    info "Supervisor: Running as process #${pid}"
}

# ---------------------------------------------------------------------------------------
# supervisor_stop() - Stop the Supervisor process based on the current PID
#
# @global SUPERVISOR_* The SUPERVISOR_ environment variables
# @return void
#
supervisor_stop() {
    info "Supervisor: Stopping ..."
    supervisorctl shutdown
    info "Supervisor: Process stopped"
}

# ---------------------------------------------------------------------------------------
# supervisor_initialize() - Set up configuration
#
# @global SUPERVISOR_* The SUPERVISOR_* environment variables
# @return void
#
supervisor_initialize() {
    if [[ $(id --user) == 0 ]]; then
        error "Supervisor: Container is running as root, but only unprivileged users are supported"
        exit 1
    fi;
}
