# net-toolkit

Small Bash tools for network troubleshooting. No dependencies beyond Bash and coreutils.

## Tools

| Tool | What it does |
|---|---|
| `bin/portcheck.sh` | Checks whether a TCP port is open on a host |
| `bin/cidr.sh` | Calculates network, broadcast, and host range from CIDR notation |
| `bin/dnscheck.sh` | Looks up A, AAAA, CNAME, MX, NS and TXT records, optionally via a chosen resolver |
| `bin/httpcheck.sh` | Checks HTTP status, response time and TLS certificate expiry |

## Usage

    ./bin/portcheck.sh github.com 443
    ./bin/portcheck.sh 127.0.0.1 5432 5
    ./bin/cidr.sh 192.168.1.10/24
    ./bin/dnscheck.sh github.com 1.1.1.1
    ./bin/httpcheck.sh https://github.com 30

Exit codes (all tools): `0` on success, `1` if a check fails (closed port, no DNS records, HTTP error, failed request, or certificate expiring), and `2` for bad input, so they work inside other scripts.

## License

GPL-3.0. See the `LICENSE` file.
