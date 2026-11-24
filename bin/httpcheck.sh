#!/usr/bin/env bash
# httpcheck.sh - check HTTP status, response time and TLS certificate expiry
# Copyright (C) 2026 devcodos (https://github.com/devcodos)
# Licensed under GPL-3.0. See the LICENSE file in the repo root.
set -euo pipefail

usage() {
    echo "Usage: $0 <url> [warn_days]    e.g. $0 https://github.com 30" >&2
    exit 2
}

for cmd in curl openssl; do
    command -v "$cmd" >/dev/null || { echo "Error: $cmd not found" >&2; exit 2; }
done

[[ $# -ge 1 && $# -le 2 ]] || usage
url="$1"
warn_days="${2:-14}"

[[ "$url" =~ ^https?://([A-Za-z0-9.-]+)(:([0-9]{1,5}))?(/.*)?$ ]] || {
    echo "Error: URL must start with http:// or https://" >&2
    exit 2
}
host="${BASH_REMATCH[1]}"
port="${BASH_REMATCH[3]:-443}"
[[ "$warn_days" =~ ^[0-9]+$ ]] || usage

status=0

# 1. HTTP check
out=$(curl -sS -o /dev/null -L --max-time 10 \
    -w '%{http_code} %{time_connect} %{time_total}' "$url") || {
    echo "FAIL     $url (no response)"
    exit 1
}
read -r code t_connect t_total <<< "$out"
echo "HTTP     $code  connect ${t_connect}s  total ${t_total}s"
(( code >= 200 && code < 400 )) || status=1

# 2. TLS certificate check (https only)
if [[ "$url" == https://* ]]; then
    end=$(echo | timeout 10 openssl s_client -servername "$host" -connect "$host:$port" 2>/dev/null \
        | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2) || true
    if [[ -z "$end" ]]; then
        echo "TLS      could not read certificate"
        exit 1
    fi
    days=$(( ( $(date -d "$end" +%s) - $(date +%s) ) / 86400 ))
    if (( days < 0 )); then
        echo "TLS      EXPIRED $(( -days )) days ago"; status=1
    elif (( days < warn_days )); then
        echo "TLS      WARNING expires in $days days ($end)"; status=1
    else
        echo "TLS      OK, expires in $days days ($end)"
    fi
fi

exit "$status"
