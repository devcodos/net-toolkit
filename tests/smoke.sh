#!/usr/bin/env bash
# smoke.sh - offline behavior tests for the scripts in bin/
# Licensed under GPL-3.0. See the LICENSE file in the repo root.
set -uo pipefail

cd "$(dirname "$0")/.." || exit 1
fails=0

command -v python3 >/dev/null || { echo "python3 is required for the tests" >&2; exit 1; }

# check <name> <expected_exit_code> <command...>
check() {
    local name="$1" want="$2" got
    shift 2
    "$@" >/dev/null 2>&1
    got=$?
    if [[ $got -eq $want ]]; then
        echo "ok    $name"
    else
        echo "FAIL  $name (expected exit $want, got $got)"
        fails=$((fails + 1))
    fi
}

# check_out <name> <regex> <command...>   (passes if the output matches)
check_out() {
    local name="$1" pattern="$2" out
    shift 2
    out="$("$@" 2>&1)" || true
    if grep -Eq "$pattern" <<< "$out"; then
        echo "ok    $name"
    else
        echo "FAIL  $name (output did not match: $pattern)"
        fails=$((fails + 1))
    fi
}

free_port() {
    python3 -c 'import socket; s = socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1])'
}

tmp="$(mktemp -d)"
server_pid=""
trap 'kill "${server_pid:-}" 2>/dev/null; rm -rf "$tmp"' EXIT

# A local web server gives us a port that is open and a URL that answers
open_port="$(free_port)"
closed_port="$(free_port)"
while [[ "$closed_port" == "$open_port" ]]; do closed_port="$(free_port)"; done

mkdir "$tmp/www"
echo ok > "$tmp/www/index.html"
python3 -m http.server "$open_port" --bind 127.0.0.1 --directory "$tmp/www" >/dev/null 2>&1 &
server_pid=$!
for _ in 1 2 3 4 5 6 7 8 9 10; do
    bin/portcheck.sh 127.0.0.1 "$open_port" 1 >/dev/null 2>&1 && break
    sleep 0.5
done

# portcheck.sh
check "portcheck: no arguments"       2 bin/portcheck.sh
check "portcheck: port 0"             2 bin/portcheck.sh 127.0.0.1 0
check "portcheck: port too large"     2 bin/portcheck.sh 127.0.0.1 99999
check "portcheck: port not a number"  2 bin/portcheck.sh 127.0.0.1 abc
check "portcheck: open port"          0 bin/portcheck.sh 127.0.0.1 "$open_port"
check "portcheck: closed port"        1 bin/portcheck.sh 127.0.0.1 "$closed_port" 1

# cidr.sh
check_out "cidr: /24 network"         'Network: +192\.168\.1\.0$'       bin/cidr.sh 192.168.1.10/24
check_out "cidr: /24 broadcast"       'Broadcast: +192\.168\.1\.255$'   bin/cidr.sh 192.168.1.10/24
check_out "cidr: /24 usable hosts"    'Usable: +254 hosts'              bin/cidr.sh 192.168.1.10/24
check_out "cidr: /26 network"         'Network: +172\.16\.5\.128$'      bin/cidr.sh 172.16.5.130/26
check_out "cidr: /26 broadcast"       'Broadcast: +172\.16\.5\.191$'    bin/cidr.sh 172.16.5.130/26
check_out "cidr: /31 usable hosts"    'Usable: +2 hosts'                bin/cidr.sh 10.0.0.1/31
check_out "cidr: /32 usable hosts"    'Usable: +1 hosts'                bin/cidr.sh 10.0.0.1/32
check "cidr: no arguments"            2 bin/cidr.sh
check "cidr: octet above 255"         2 bin/cidr.sh 300.1.1.1/24
check "cidr: prefix above 32"         2 bin/cidr.sh 10.0.0.1/33

# dnscheck.sh (input validation only, so no network is needed)
check "dnscheck: no arguments"        2 bin/dnscheck.sh
check "dnscheck: invalid domain"      2 bin/dnscheck.sh 'bad_domain!'
check "dnscheck: invalid resolver"    2 bin/dnscheck.sh example.com not-an-ip
check "dnscheck: too many arguments"  2 bin/dnscheck.sh example.com 1.1.1.1 extra

# httpcheck.sh
check "httpcheck: no arguments"       2 bin/httpcheck.sh
check "httpcheck: not an http URL"    2 bin/httpcheck.sh ftp://example.com
check "httpcheck: bad warn days"      2 bin/httpcheck.sh "http://127.0.0.1:$open_port/" abc
check_out "httpcheck: status 200"     'HTTP +200'  bin/httpcheck.sh "http://127.0.0.1:$open_port/"
check "httpcheck: 200 exits 0"        0 bin/httpcheck.sh "http://127.0.0.1:$open_port/"
check "httpcheck: 404 exits 1"        1 bin/httpcheck.sh "http://127.0.0.1:$open_port/no-such-page"
check "httpcheck: refused exits 1"    1 bin/httpcheck.sh "http://127.0.0.1:$closed_port/"

echo
if (( fails > 0 )); then
    echo "$fails test(s) failed"
    exit 1
fi
echo "All tests passed"
