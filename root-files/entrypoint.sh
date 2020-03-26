#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

. "${FLOWNATIVE_LIB_PATH}/init.sh"
. "${FLOWNATIVE_LIB_PATH}/supervisor.sh"

init_run

eval "$(supervisor_env)"
supervisor_initialize
supervisor_start

if [[ "$*" = *"run"* ]]; then
    trap 'supervisor_stop' SIGINT SIGTERM

    supervisor_pid=$(supervisor_get_pid)
    info "Entrypoint: Start up complete"

    # We can't use "wait" because supervisord is not a direct child of this shell:
    while [ -e "/proc/${supervisor_pid}" ]; do sleep 1.1; done
    info "Good bye 👋"
else
    "$@"
fi
