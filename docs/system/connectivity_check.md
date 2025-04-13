# Connectivity Check Script

## Summary
Tests network connectivity to a specified host and logs the results.

## Location
`/system/connectivity_check.sh`

## Purpose
This script verifies network connectivity by pinging a specified host. It's useful for:
- Monitoring network status
- Testing connectivity to critical services
- Troubleshooting network issues
- Creating connectivity logs for reports

## Usage

```bash
./connectivity_check.sh [-h host] [-o output_file] [-c ping_count] [-t timeout] [-v]
```

## Parameters

| Parameter | Description |
|-----------|-------------|
| `-h <host>` | Host to check connectivity (default: google.com or from config) |
| `-o <file>` | Output file for logging (default: console or from config) |
| `-c <count>` | Number of pings to send (default: 3) |
| `-t <seconds>` | Timeout in seconds (default: 5) |
| `-v` | Verbose output with additional diagnostics |
| `--help` | Display help information |

## Examples

Basic usage:

```bash
./connectivity_check.sh
```

Check connectivity to a specific host:

```bash
./connectivity_check.sh -h example.com
```

Verbose check with custom ping count and timeout:

```bash
./connectivity_check.sh -h internal-server.local -c 5 -t 2 -v
```

Log results to a file:

```bash
./connectivity_check.sh -o /var/log/connectivity.log
```

## Dependencies

- `ping` - For connectivity testing
- `traceroute` (optional) - For advanced diagnostics in verbose mode
- `host` (optional) - For DNS resolution testing

## Notes

- The script will use the default host from `arsenal.conf` if available
- In verbose mode, it will attempt additional diagnostics like traceroute
- Non-zero exit status indicates connectivity failure
- When network interfaces are down, the script provides relevant diagnostics

## Related
- [Network Diagnostics Script](network_diagnostics.md)
- [System Health Check](health_check.md)
