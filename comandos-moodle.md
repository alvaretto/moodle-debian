# Comandos de Backup y Restauración de Moodle

## Scripts disponibles

### 1. Backup de Moodle

**Ubicación**: `/usr/local/bin/moodle-backup.sh`

**Ejecutar**:
```bash
sudo /usr/local/bin/moodle-backup.sh
```

**Qué hace**:
1. Activa modo mantenimiento en Moodle
2. Exporta la base de datos (comprimida con gzip)
3. Respalda /var/moodledata (archivos subidos)
4. Copia config.php
5. Desactiva modo mantenimiento
6. Elimina backups mayores a 30 días

**Archivos generados** (en `~/backups/`):
- `db_YYYYMMDD_HHMMSS.sql.gz` - Base de datos
- `moodledata_YYYYMMDD_HHMMSS.tar.gz` - Archivos
- `config_YYYYMMDD_HHMMSS.php` - Configuración

**Programación automática**: Todos los días a las 3:00 AM

---

### 2. Restauración de Moodle

**Ubicación**: `/usr/local/bin/moodle-restore.sh`

**Ver backups disponibles**:
```bash
sudo /usr/local/bin/moodle-restore.sh
```

**Restaurar un backup específico**:
```bash
sudo /usr/local/bin/moodle-restore.sh 20260126_215808
```

**Qué hace**:
1. Activa modo mantenimiento
2. Restaura la base de datos
3. Restaura /var/moodledata
4. Ajusta permisos
5. Desactiva modo mantenimiento

---

### 3. Estado del servidor

**Ubicación**: `/usr/local/bin/moodle-status.sh`

**Ejecutar**:
```bash
/usr/local/bin/moodle-status.sh
```

**Qué muestra**:
- IP de acceso (moodle.local y numérica)
- Estado de servicios (nginx, php, mariadb, redis, avahi)
- Uso de RAM y disco
- Últimos snapshots de Timeshift
- Últimos backups de Moodle

---

## Comandos útiles adicionales

### Servicios

```bash
# Ver estado de todos los servicios
sudo systemctl status nginx php8.4-fpm mariadb redis-server avahi-daemon

# Reiniciar servicios
sudo systemctl restart nginx php8.4-fpm mariadb redis-server

# Ver logs de Nginx
sudo tail -f /var/log/nginx/error.log
```

### Moodle CLI

```bash
# Activar modo mantenimiento
sudo -u www-data php /var/www/moodle/admin/cli/maintenance.php --enable

# Desactivar modo mantenimiento
sudo -u www-data php /var/www/moodle/admin/cli/maintenance.php --disable

# Purgar caché
sudo -u www-data php /var/www/moodle/admin/cli/purge_caches.php

# Ejecutar cron manualmente
sudo -u www-data php /var/www/moodle/admin/cli/cron.php
```

### Timeshift

```bash
# Listar snapshots
sudo timeshift --list

# Crear snapshot manual
sudo timeshift --create --comments "Descripción del snapshot"

# Restaurar (interactivo)
sudo timeshift --restore
```

### Base de datos

```bash
# Acceder a MariaDB
sudo mariadb

# Backup manual de la base de datos
mysqldump -u moodleuser -p moodle > backup.sql

# Restaurar base de datos
mysql -u moodleuser -p moodle < backup.sql
```

---

## Ubicaciones importantes

| Elemento | Ruta |
|----------|------|
| Moodle | `/var/www/moodle` |
| Moodledata | `/var/moodledata` |
| Config PHP | `/var/www/moodle/config.php` |
| Backups | `~/backups/` |
| Logs Nginx | `/var/log/nginx/` |
| Logs Backup | `/var/log/moodle-backup.log` |

---

## Cron configurado

```
# Cron de Moodle (cada 5 minutos)
*/5 * * * * /usr/bin/php8.4 /var/www/moodle/admin/cli/cron.php > /dev/null 2>&1

# Backup automático (3:00 AM)
0 3 * * * /usr/local/bin/moodle-backup.sh >> /var/log/moodle-backup.log 2>&1
```

Ver cron actual: `sudo crontab -l`
