#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

(trap 'kill 0' SIGINT; \
bash -c './watch_build.sh' & \
bash -c './watch_restart.sh'
)

