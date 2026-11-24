#!/usr/bin/env bash
# dnscheck.sh - look up common DNS record types for a domain
# Copyright (C) 2026 devcodos (https://github.com/devcodos)
# Licensed under GPL-3.0. See the LICENSE file in the repo root.
set -euo pipefail

usage() {
    echo "Usage: $0 <domain> [resolver]    e.g. $0 github.com 1.1.1.1" >&2
    exit 2
}

command -v dig >/dev/null || { echo "Error: dig not found (sudo apt install dnsutils)" >&2; exit 2; }

[[ $# -ge 1 && $# -le 2 ]] || usage

domain="$1"
resolver="${2:-}"

if ! [[ "$domain" =~ ^[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?$ ]]; then
    echo "Error: invalid domain name" >&2
    exit 2
fi
if [[ -n "$resolver" ]] && ! [[ "$resolver" =~ ^[0-9A-Fa-f:.]+$ ]]; then
    echo "Error: resolver must be an IP address" >&2
    exit 2
fi

args=(+short +time=3 +tries=1)
[[ -n "$resolver" ]] && args+=("@$resolver")

found=0
for type in A AAAA CNAME MX NS TXT; do
    result=$(dig "${args[@]}" "$domain" "$type" 2>/dev/null || true)
    if [[ -n "$result" ]]; then
        found=1
        echo "== $type =="
        echo "$result"
    fi
done

if (( found == 0 )); then
    echo "No records found for $domain" >&2
    exit 1
fi
