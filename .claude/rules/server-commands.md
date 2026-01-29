# Reglas para comandos de servidor

## Al ejecutar comandos en el servidor Moodle

### Principio de mínimo privilegio
- Usar `sudo` solo cuando sea estrictamente necesario
- Preferir `sudo -u www-data` para operaciones de Moodle
- No usar `sudo su` o shells interactivos

### Comandos seguros (ejecutar sin confirmación extra)
```bash
systemctl status *
systemctl is-active *
cat /var/log/*
tail /var/log/*
redis-cli ping
redis-cli info
free -h
df -h
ps aux
uptime
```

### Comandos que requieren precaución
```bash
systemctl restart *    # Puede interrumpir servicio
systemctl stop *       # Detiene servicio
apt install *          # Modifica sistema
apt remove *           # Elimina paquetes
```

### Comandos peligrosos (confirmar siempre)
```bash
rm -rf *               # Eliminación recursiva
dd *                   # Escritura directa a disco
mkfs *                 # Formateo
shutdown/reboot        # Apagar/reiniciar
git reset --hard       # Pérdida de cambios
DROP DATABASE          # Eliminar base de datos
```

### Antes de cambios mayores
1. Verificar estado actual del servicio
2. Confirmar que hay backup reciente
3. Informar al usuario del impacto
4. Proporcionar comando de rollback

### Rutas críticas (no modificar sin backup)
- `/var/www/moodle/config.php`
- `/var/moodledata/`
- `/etc/nginx/`
- `/etc/php/8.4/`
- `/etc/mysql/`
