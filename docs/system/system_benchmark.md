# System Benchmark Script

## Summary
Comprehensive benchmarking tool for measuring system performance across CPU, memory, disk, and network subsystems.

## Location
`/system/system_benchmark.sh`

## Purpose
The System Benchmark script provides detailed performance metrics for a system's core components. It helps identify performance bottlenecks, compare hardware configurations, establish baseline performance metrics, and track performance changes over time.

The script runs a series of standardized tests to evaluate:
- CPU processing power (single and multi-threaded)
- Memory read/write speeds
- Disk I/O (sequential and random)
- File system operations
- Network throughput (optional)

## Usage

```bash
./system_benchmark.sh [options]
```

## Parameters

| Parameter | Description |
|-----------|-------------|
| `-o, --output` | Specify output file for results (default: benchmark_results_<timestamp>.txt) |
| `-q, --quick` | Run a quick benchmark with fewer iterations |
| `-d, --disk-size <MB>` | Specify disk test file size in MB (default: 512) |
| `-s, --skip-network` | Skip network tests |
| `-h, --help` | Display help information |

## Examples

Basic usage:

```bash
./system_benchmark.sh
```

Run a quick benchmark and save results to a specific file:

```bash
./system_benchmark.sh --quick --output /path/to/results.txt
```

Run without network tests (useful for offline systems):

```bash
./system_benchmark.sh --skip-network
```

## Dependencies

- `dd` - For disk I/O testing
- `time` - For performance timing
- `bc` - For calculations
- `awk` - For data processing
- `grep` - For pattern matching
- `curl` - For network testing (optional)

## Notes

- The script creates temporary files during testing that are automatically cleaned up
- CPU tests can cause high CPU load for several minutes
- Disk tests create and delete large temporary files
- Network tests require internet connectivity
- Results are influenced by current system load; for best results, run when the system is idle
- Results are saved to a timestamped file for future reference and comparison

## Results Interpretation

The benchmark outputs metrics in the following format:

- **CPU Performance**: Time to calculate prime numbers (lower is better)
- **Memory Speed**: MB/s for read and write operations (higher is better)
- **Disk Performance**: MB/s for sequential operations, IOPS for random operations (higher is better)
- **File System Operations**: Files/sec for creation and deletion (higher is better)
- **Network Performance**: ms latency (lower is better), download time (lower is better)

## Related
- [VM Detection Script](vm.md)
- [System Health Monitor](syshealth.md)
