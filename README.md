# net-toolkit

Small Bash tools for network troubleshooting. No dependencies beyond Bash and coreutils.

## Tools

| Tool | What it does |
|---|---|
| `bin/portcheck.sh` | Checks whether a TCP port is open on a host |

## Usage

    ./bin/portcheck.sh github.com 443
    ./bin/portcheck.sh 127.0.0.1 5432 5

Exit code is `0` if the port is open, `1` if closed or filtered, and `2` for bad input, so it works inside other scripts.

## GPL-3.0 license

GPL
