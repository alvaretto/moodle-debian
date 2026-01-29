---
name: moodle-optimize
description: Optimizar el rendimiento del servidor Moodle. Usar cuando el usuario quiera mejorar velocidad, reducir uso de RAM, o preparar para más estudiantes.
user-invocable: true
allowed-tools: Bash, Read, WebSearch
argument-hint: [php|mysql|redis|nginx|kernel|all]
---

# Skill: Optimización del Servidor Moodle

Analiza y sugiere optimizaciones para el servidor Moodle de 12GB RAM.

## Argumentos

- `php`: Optimizar PHP-FPM y OPcache
- `mysql`: Optimizar MariaDB
- `redis`: Optimizar Redis
- `nginx`: Optimizar Nginx
- `kernel`: Optimizar parámetros del kernel (sysctl)
- `all` o sin argumento: Análisis completo

## Diagnóstico inicial

Antes de optimizar, recopilar métricas actuales:

```bash
echo "=== Uso de RAM actual ==="
free -h
echo ""
echo "=== Procesos con más RAM ==="
ps aux --sort=-%mem | head -10
echo ""
echo "=== Conexiones activas ==="
ss -s
echo ""
echo "=== PHP-FPM pools ==="
ps aux | grep php-fpm | wc -l
```

## Áreas de optimización

### PHP-FPM (`php`)
Revisar y optimizar `/etc/php/8.4/fpm/pool.d/www.conf`:
- `pm.max_children` - Para 12GB RAM, recomendado: 30-50
- `pm.start_servers` - Recomendado: 5
- `pm.min_spare_servers` - Recomendado: 5
- `pm.max_spare_servers` - Recomendado: 20

OPcache en `/etc/php/8.4/fpm/php.ini`:
- `opcache.memory_consumption=256`
- `opcache.max_accelerated_files=10000`
- `opcache.revalidate_freq=60`

### MariaDB (`mysql`)
Revisar `/etc/mysql/mariadb.conf.d/50-server.cnf`:
- `innodb_buffer_pool_size` - Para 12GB, recomendado: 2G-4G
- `innodb_log_file_size` - Recomendado: 256M
- `query_cache_size` - Recomendado: 64M
- `max_connections` - Recomendado: 150

Ejecutar análisis:
```bash
sudo mysqltuner 2>/dev/null || echo "mysqltuner no instalado"
```

### Redis (`redis`)
Revisar `/etc/redis/redis.conf`:
- `maxmemory` - Recomendado: 512mb
- `maxmemory-policy` - Recomendado: allkeys-lru

Verificar uso:
```bash
redis-cli info memory | grep -E "used_memory_human|maxmemory"
redis-cli info stats | grep -E "keyspace_hits|keyspace_misses"
```

### Nginx (`nginx`)
Revisar `/etc/nginx/nginx.conf`:
- `worker_processes auto`
- `worker_connections 1024`
- `keepalive_timeout 65`
- gzip habilitado

### Kernel (`kernel`)
Revisar `/etc/sysctl.d/99-moodle.conf`:
```
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
vm.swappiness = 10
fs.file-max = 65535
```

## Documento de referencia

Consultar `moodle-install.md` sección "Optimizaciones de producción" para configuraciones detalladas validadas para este hardware específico.

## Salida esperada

Presentar:
1. Estado actual de cada componente
2. Valores recomendados vs actuales
3. Comandos específicos para aplicar cambios
4. Impacto esperado en rendimiento
