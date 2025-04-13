# Database Backup Script

## Summary
Creates compressed database backups with flexible configuration options and retention management.

## Location
`/database/database_backup.sh`

## Purpose
This script creates backups of MySQL/MariaDB databases with the following features:
- Single database or all databases backup
- Compressed or uncompressed SQL dumps
- Configurable backup directory
- Backup rotation with retention policies
- MD5 checksum verification
- Multiple authentication methods

## Usage

```bash
./database_backup.sh [options]
```

## Parameters

| Parameter | Description |
|-----------|-------------|
| `-d, --database <name>` | Database name to backup (default: all databases if not specified) |
| `-o, --output <dir>` | Backup directory (default: from config) |
| `-u, --user <user>` | Database username (default: from config) |
| `-h, --host <host>` | Database hostname (default: from config) |
| `-p, --port <port>` | Database port (default: from config) |
| `-a, --all-databases` | Backup all databases |
| `-n, --no-compression` | Disable compression (default: enabled) |
| `-r, --retention <days>` | Backup retention in days (default: from config) |
| `--help` | Show help information |

## Examples

Basic usage:

```bash
./database_backup.sh -d mydb
```

Backup all databases with 60-day retention:

```bash
./database_backup.sh -a -r 60
```

Backup a specific database to a custom location:

```bash
./database_backup.sh -d wordpress -o /mnt/backup/databases -u dbuser -h dbhost
```

## Dependencies

- `mysqldump` - For creating database dumps
- `gzip` - For compression (optional)
- `md5sum` - For backup verification

## Notes

- The script sources configuration from `config/arsenal.conf` if available
- Database credentials can be provided via:
  1. Command-line parameters
  2. Environment variables
  3. Configuration files
  4. Interactive prompt
- The backup directory is created if it doesn't exist
- Old backups are automatically cleaned up based on retention policy

## Related
- [Advanced Database Management](autodb.md)
- [Database Restore Script](database_restore.md)
