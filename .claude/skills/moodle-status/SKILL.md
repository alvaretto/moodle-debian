---
name: moodle-status
description: Verificar el estado completo del servidor Moodle - servicios, recursos, backups, Redis, y conectividad. Usar cuando el usuario pregunte por el estado del servidor o quiera diagnosticar problemas.
user-invocable: true
allowed-tools: Bash, Read
argument-hint: [--full|--quick]
---

# Skill: Estado del Servidor Moodle

Ejecuta una verificación completa del servidor Moodle y reporta el estado.

## Comandos a ejecutar

### 1. Verificación rápida de servicios
```bash
for svc in nginx php8.4-fpm mariadb redis-server avahi-daemon; do
  echo -n "$svc: "
  systemctl is-active $svc 2>/dev/null || echo "no instalado"
done
```

### 2. Estado de Redis
```bash
redis-cli ping 2>/dev/null || echo "Redis no responde"
redis-cli info memory 2>/dev/null | grep -E "used_memory_human|maxmemory_human" || true
```

### 3. Recursos del sistema
```bash
echo "=== RAM ==="
free -h
echo ""
echo "=== Disco ==="
df -h / /var /home 2>/dev/null | head -5
echo ""
echo "=== Carga ==="
uptime
```

### 4. Últimos backups (si existe el script)
```bash
if [ -x /usr/local/bin/moodle-status.sh ]; then
  /usr/local/bin/moodle-status.sh
else
  echo "Script moodle-status.sh no encontrado"
  ls -lh ~/backups/*.gz 2>/dev/null | tail -5 || echo "No hay backups en ~/backups/"
fi
```

### 5. Conectividad Moodle
```bash
curl -s -o /dev/null -w "HTTP %{http_code} - TTFB: %{time_starttransfer}s\n" http://localhost/ 2>/dev/null || echo "Moodle no responde en localhost"
```

## Formato de respuesta

Presenta los resultados en una tabla clara:

| Componente | Estado | Detalles |
|------------|--------|----------|
| Nginx | ✅/❌ | ... |
| PHP-FPM | ✅/❌ | ... |
| MariaDB | ✅/❌ | ... |
| Redis | ✅/❌ | Memoria usada |
| Avahi | ✅/❌ | mDNS |
| RAM | XX% | X/12 GB |
| Disco | XX% | X/125 GB |
| Último backup | fecha | tamaño |

Si hay problemas, sugiere comandos de solución basándote en la documentación del proyecto.
