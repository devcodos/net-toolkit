#!/usr/bin/env bash
# portcheck.sh - check whether a TCP port is open on a host
# Copyright (C) 2026 Saleh Bichara
# Licensed under GPL-3.0. See the LICENSE file in the repo root.
set -euo pipefail

usage() {
    echo "Usage: $0 <host> <port> [timeout_seconds]" >&2
    exit 2
}

[[ $# -ge 2 ]] || usage

host="$1"
port="$2"
wait_time="${3:-3}"

if ! [[ "$port" =~ ^[0-9]+$ ]] || (( port < 1 || port > 65535 )); then
    echo "Error: port must be a number from 1 to 65535" >&2
    exit 2
fi

# Try a TCP connection; host and port are passed as arguments
# so odd input can't inject commands.
if timeout "$wait_time" bash -c 'exec 3<>/dev/tcp/"$0"/"$1"' "$host" "$port" 2>/dev/null; then
    echo "OPEN    $host:$port"
else
    echo "CLOSED  $host:$port (refused, filtered, or timed out)"
    exit 1
fi
