# net-toolkit

Small Bash tools for network troubleshooting. No dependencies beyond Bash and coreutils.

## Tools

| Tool | What it does |
|---|---|
| `bin/portcheck.sh` | Checks whether a TCP port is open on a host |
| `bin/cidr.sh` | Calculates network, broadcast, and host range from CIDR notation |

## Usage

    ./bin/portcheck.sh github.com 443
    ./bin/portcheck.sh 127.0.0.1 5432 5
    ./bin/cidr.sh 192.168.1.10/24

Exit codes (both tools): `0` on success, `1` if a port is closed or filtered (`portcheck.sh` only), and `2` for bad input, so they work inside other scripts.

## License

GPL-3.0. See the `LICENSE` file.
