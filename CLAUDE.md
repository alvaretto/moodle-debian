# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **documentation repository** (not a software project) for deploying and maintaining a portable Moodle LMS on Debian 13 "Trixie". The target environment is a laptop with 12GB RAM and 125GB SSD serving 80-100 students in offline classroom settings via WiFi.

**Language**: Spanish (target audience: Latin American educators)

## Technology Stack

| Component | Version | Notes |
|-----------|---------|-------|
| Debian | 13 "Trixie" | XFCE desktop |
| Moodle | 5.1.1 | From git tag v5.1.1 |
| PHP | 8.4-FPM | With OPcache |
| MariaDB | 11.8 | Tuned for 12GB RAM |
| Nginx | Debian default | FastCGI to PHP-FPM |
| Redis | 8.0 | Sessions + application cache |
| Timeshift | RSYNC mode | System snapshots |

## Key Documentation Files

- **moodle-install.md**: Complete installation guide (LEMP, Moodle, mDNS, Redis, security, optimization)
- **moodle-5.md**: Upgrade path from Moodle 4.5+PHP 8.3 to Moodle 5.1+PHP 8.4
- **comandos-moodle.md**: Quick reference for daily operations
- **testing-moodle.md**: Load testing procedures for 60 concurrent users

## Common Commands

### Admin Scripts (installed on the server)
```bash
sudo /usr/local/bin/moodle-backup.sh      # Full backup (DB + moodledata + config)
sudo /usr/local/bin/moodle-restore.sh     # List or restore backups
/usr/local/bin/moodle-status.sh           # Service status, RAM, disk, backups
```

### Service Management
```bash
sudo systemctl restart nginx php8.4-fpm mariadb redis-server
sudo systemctl status nginx php8.4-fpm mariadb redis-server avahi-daemon
```

### Moodle CLI
```bash
sudo -u www-data php /var/www/moodle/admin/cli/maintenance.php --enable|--disable
sudo -u www-data php /var/www/moodle/admin/cli/purge_caches.php
sudo -u www-data php /var/www/moodle/admin/cli/cron.php
```

### Timeshift Snapshots
```bash
sudo timeshift --list
sudo timeshift --create --comments "Description"
sudo timeshift --restore
```

## Architecture

### Network Discovery
- Server announces as `moodle.local` via avahi-daemon (mDNS)
- Works across different routers/IPs without client reconfiguration
- Students access via `http://moodle.local` or direct IP

### Backup Strategy
- **System level**: Timeshift RSYNC snapshots (pre-upgrade, major changes)
- **Application level**: Daily automated backup at 3:00 AM (~/backups/)
- **Components backed up**: MariaDB dump, /var/moodledata, config.php

### Performance Optimization Layers
1. Redis for sessions and MUC (Moodle Universal Cache)
2. PHP OPcache for bytecode caching
3. Nginx gzip compression
4. MariaDB query cache and buffer tuning
5. Kernel tuning via sysctl for network I/O

## Key Paths on Server

| Purpose | Path |
|---------|------|
| Moodle installation | `/var/www/moodle` |
| Moodle public web root | `/var/www/moodle/public` |
| User data | `/var/moodledata` |
| Moodle config | `/var/www/moodle/config.php` |
| Backups | `~/backups/` |
| Nginx logs | `/var/log/nginx/` |
| Backup log | `/var/log/moodle-backup.log` |

## Scheduled Tasks

```
# Moodle cron (every 5 minutes)
*/5 * * * * /usr/bin/php8.4 /var/www/moodle/admin/cli/cron.php

# Automated backup (daily at 3:00 AM)
0 3 * * * /usr/local/bin/moodle-backup.sh >> /var/log/moodle-backup.log 2>&1
```

## Claude Code Ecosystem

This project includes a comprehensive Claude Code ecosystem in `.claude/` with:

### Skills (Slash Commands)
| Command | Purpose |
|---------|---------|
| `/moodle-status` | Check server health and resources |
| `/moodle-backup` | Manage backups (run, list, verify, restore) |
| `/moodle-optimize` | Performance tuning (php, mysql, redis, nginx, kernel) |
| `/moodle-test` | Load testing for N students |
| `/moodle-upgrade` | Plan and execute upgrades |
| `/moodle-security` | Security audit and hardening |
| `/doc-update` | Documentation maintenance |

### Specialized Agents
- **moodle-ops**: Real-time operations and troubleshooting
- **moodle-architect**: Architecture planning and scaling
- **moodle-docs**: Technical writing and documentation

### Automation Hooks
- Protected files validation (PreToolUse)
- Version consistency checks (PostToolUse)
- Change logging (PostToolUse)

See `.claude/README.md` for full ecosystem documentation.

## Context for Claude

- This repository documents a **production deployment**, not development code
- Changes are about improving documentation, adding procedures, or updating for new versions
- The server is **offline** (no internet); all packages must be pre-installed
- Target capacity: 60-100 concurrent students on tablets via WiFi
- Content source: ICFES-style math exams generated with R-exams
