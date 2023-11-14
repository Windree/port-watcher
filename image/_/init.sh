#!/bin/bash
set -Eeuo pipefail

pid_file=$(mktemp --dry-run --tmpdir=/run)

function main() {
    echo "Connection watch started on port $1."
    while [ : ]; do
        if nc -zw1 $2 $3; then
            echo "Connection test to $2:$3 successful."
            start_watcher "$1"
        else
            echo "Connection test to $2:$3 failed."
            stop_watcher "$1"
        fi
        sleep 60
    done
}

function start_watcher() {
    [ -f "$pid_file" ] && return
    nc -lk "$1" &
    if [ "$?" -ne 0 ]; then
        echo "Faled to start watcher."
        exit 1
    else
        echo "$!" >"$pid_file"
    fi
}

function stop_watcher() {
    [ ! -f "$pid_file" ] && return
    if ! kill $(cat "$pid_file"); then
        echo "Faled to stop watcher."
        exit 1
    fi
    rm "$pid_file"
}

function stop() {
    stop_watcher
    if [ -f "$pid_file" ]; then
        rm -f "$pid_file"
    fi
}

trap stop exit

main "$LISTEN" "$ADDR" "$PORT"
