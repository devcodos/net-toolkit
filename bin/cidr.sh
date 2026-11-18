#!/usr/bin/env bash
# cidr.sh - show network details for an IPv4 address in CIDR notation
# Copyright (C) 2026 Saleh Bichara
# Licensed under GPL-3.0. See the LICENSE file in the repo root.
set -euo pipefail

usage() {
    echo "Usage: $0 <ip>/<prefix>    e.g. $0 192.168.1.10/24" >&2
    exit 2
}

to_ip() {
    echo "$(( ($1 >> 24) & 255 )).$(( ($1 >> 16) & 255 )).$(( ($1 >> 8) & 255 )).$(( $1 & 255 ))"
}

[[ $# -eq 1 ]] || usage
[[ "$1" =~ ^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})/([0-9]{1,2})$ ]] || usage

o1=$((10#${BASH_REMATCH[1]})); o2=$((10#${BASH_REMATCH[2]}))
o3=$((10#${BASH_REMATCH[3]})); o4=$((10#${BASH_REMATCH[4]}))
prefix=$((10#${BASH_REMATCH[5]}))

for o in "$o1" "$o2" "$o3" "$o4"; do
    (( o <= 255 )) || { echo "Error: each octet must be 0-255" >&2; exit 2; }
done
(( prefix <= 32 )) || { echo "Error: prefix must be 0-32" >&2; exit 2; }

ip=$(( (o1 << 24) | (o2 << 16) | (o3 << 8) | o4 ))
mask=$(( (0xFFFFFFFF << (32 - prefix)) & 0xFFFFFFFF ))
network=$(( ip & mask ))
broadcast=$(( network | (~mask & 0xFFFFFFFF) ))
total=$(( 1 << (32 - prefix) ))

if (( prefix <= 30 )); then
    first=$(( network + 1 )); last=$(( broadcast - 1 )); usable=$(( total - 2 ))
else
    first=$network; last=$broadcast; usable=$total
fi

echo "Address:    $(to_ip "$ip")/$prefix"
echo "Netmask:    $(to_ip "$mask")"
echo "Network:    $(to_ip "$network")"
echo "Broadcast:  $(to_ip "$broadcast")"
echo "First host: $(to_ip "$first")"
echo "Last host:  $(to_ip "$last")"
echo "Total:      $total addresses"
echo "Usable:     $usable hosts"
