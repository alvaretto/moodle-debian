# Manual del Usuario - Servidor Moodle

Guía práctica para la operación diaria del servidor Moodle portátil.

## Tabla de contenidos

1. [Antes de empezar](#antes-de-empezar)
2. [Encender y preparar el servidor](#encender-y-preparar-el-servidor)
3. [Verificar que todo funciona](#verificar-que-todo-funciona)
4. [Durante la clase](#durante-la-clase)
5. [Al terminar la clase](#al-terminar-la-clase)
6. [Backups y restauración](#backups-y-restauración)
7. [Problemas comunes](#problemas-comunes)
8. [Mantenimiento periódico](#mantenimiento-periódico)

---

## Antes de empezar

### Información básica

| Dato | Valor |
|------|-------|
| Dirección del servidor | `http://moodle.local` |
| Usuario administrador | Configurado durante instalación |
| Capacidad | 60-100 estudiantes simultáneos |

### Lo que necesitas

- El laptop servidor con batería cargada (o conectado a corriente)
- Acceso al router WiFi del aula
- Las tablets de los estudiantes conectadas al mismo WiFi

---

## Encender y preparar el servidor

### Paso 1: Encender el laptop

1. Enciende el laptop servidor
2. Espera a que inicie Debian (escritorio XFCE)
3. Inicia sesión con tu usuario

### Paso 2: Conectar al WiFi del aula

1. Clic en el ícono de red (esquina superior derecha)
2. Selecciona el WiFi del aula
3. Ingresa la contraseña si es necesario

### Paso 3: Verificar servicios (automático)

Los servicios se inician automáticamente. Para verificar, abre una terminal y ejecuta:

```bash
/usr/local/bin/moodle-status.sh
```

Deberías ver todos los servicios en verde (✓).

---

## Verificar que todo funciona

### Verificación rápida

Abre el navegador del servidor y ve a:
```
http://localhost
```

Deberías ver la página de inicio de Moodle.

### Verificación completa

En terminal, ejecuta:

```bash
/usr/local/bin/moodle-status.sh
```

**Salida esperada:**
```
=== Estado del Servidor Moodle ===
Dirección: http://moodle.local (192.168.x.x)

Servicios:
  nginx:        ✓ activo
  php8.4-fpm:   ✓ activo
  mariadb:      ✓ activo
  redis-server: ✓ activo
  avahi-daemon: ✓ activo

Recursos:
  RAM: 2.1G / 12G (17%)
  Disco: 45G / 125G (36%)

Últimos backups:
  2026-01-29 03:00 - db + moodledata
```

### Verificar desde una tablet

1. Conecta la tablet al mismo WiFi
2. Abre el navegador
3. Ve a `http://moodle.local`
4. Debe aparecer la página de Moodle

**Si no funciona con moodle.local**, usa la IP directa que muestra `moodle-status.sh`.

---

## Durante la clase

### Monitorear el servidor

Si quieres ver el estado en tiempo real, abre terminal y ejecuta:

```bash
watch -n 5 '/usr/local/bin/moodle-status.sh'
```

Esto actualiza cada 5 segundos. Presiona `Ctrl+C` para salir.

### Si el servidor se pone lento

1. **Verifica RAM**: Si está > 90%, algunos estudiantes deben cerrar pestañas
2. **Reinicia Redis** (libera caché):
   ```bash
   sudo systemctl restart redis-server
   ```
3. **Purga caché de Moodle**:
   ```bash
   sudo -u www-data php /var/www/moodle/admin/cli/purge_caches.php
   ```

### Si un estudiante no puede acceder

1. Verificar que está en el WiFi correcto
2. Probar con IP directa en lugar de `moodle.local`
3. Reiniciar el navegador de la tablet
4. En último caso, reiniciar la tablet

---

## Al terminar la clase

### Opción A: Apagar el servidor (recomendado si no se usa más hoy)

1. Asegúrate de que todos los estudiantes hayan cerrado sesión
2. Ejecuta backup manual (opcional pero recomendado):
   ```bash
   sudo /usr/local/bin/moodle-backup.sh
   ```
3. Apaga el sistema:
   ```bash
   sudo shutdown now
   ```

### Opción B: Dejar encendido (si hay otra clase pronto)

1. El servidor puede quedarse encendido
2. El backup automático se ejecuta a las 3:00 AM
3. Asegúrate de que esté conectado a corriente

---

## Backups y restauración

### Backup manual

Ejecutar cuando:
- Antes de cambios importantes
- Después de crear muchos exámenes
- Antes de actualizar Moodle

```bash
sudo /usr/local/bin/moodle-backup.sh
```

**Tiempo estimado**: 2-5 minutos dependiendo del tamaño de datos.

### Ver backups disponibles

```bash
sudo /usr/local/bin/moodle-restore.sh
```

Muestra lista de backups con fecha y hora.

### Restaurar un backup

**⚠️ CUIDADO**: Esto sobrescribe todos los datos actuales.

```bash
# Ver backups disponibles
sudo /usr/local/bin/moodle-restore.sh

# Restaurar uno específico (ejemplo)
sudo /usr/local/bin/moodle-restore.sh 20260129_030000
```

### Ubicación de backups

Los backups se guardan en `~/backups/`:
- `db_FECHA.sql.gz` - Base de datos
- `moodledata_FECHA.tar.gz` - Archivos de usuarios
- `config_FECHA.php` - Configuración

---

## Problemas comunes

### "No se puede acceder a moodle.local"

**Causa probable**: El servicio Avahi (mDNS) no está funcionando.

**Solución**:
```bash
sudo systemctl restart avahi-daemon
```

**Alternativa**: Usar la IP directa del servidor.

### "Error 502 Bad Gateway"

**Causa probable**: PHP-FPM no está respondiendo.

**Solución**:
```bash
sudo systemctl restart php8.4-fpm
```

### "Error de base de datos"

**Causa probable**: MariaDB no está funcionando.

**Solución**:
```bash
sudo systemctl restart mariadb
```

### "Página muy lenta"

**Causa probable**: Caché lleno o muchas conexiones.

**Solución**:
```bash
# Reiniciar Redis
sudo systemctl restart redis-server

# Purgar caché de Moodle
sudo -u www-data php /var/www/moodle/admin/cli/purge_caches.php
```

### "Disco lleno"

**Causa probable**: Demasiados backups o logs.

**Solución**:
```bash
# Ver uso de disco
df -h

# Eliminar backups antiguos manualmente si es necesario
ls -la ~/backups/
```

### El servidor no enciende / pantalla negra

1. Verificar que tiene batería o está conectado a corriente
2. Mantener presionado el botón de encendido 10 segundos
3. Si persiste, puede ser problema de hardware

### Reiniciar todo el stack

Si nada funciona, reinicia todos los servicios:

```bash
sudo systemctl restart nginx php8.4-fpm mariadb redis-server avahi-daemon
```

Si sigue fallando, reinicia el servidor:

```bash
sudo reboot
```

---

## Mantenimiento periódico

### Semanal

- [ ] Verificar que los backups automáticos se están ejecutando
- [ ] Revisar espacio en disco (`df -h`)
- [ ] Revisar logs de errores si hubo problemas

### Mensual

- [ ] Eliminar backups muy antiguos si es necesario
- [ ] Crear snapshot de Timeshift:
  ```bash
  sudo timeshift --create --comments "Snapshot mensual"
  ```
- [ ] Verificar actualizaciones de seguridad:
  ```bash
  sudo apt update && sudo apt list --upgradable
  ```

### Antes de cada período escolar

- [ ] Verificar todo el hardware (batería, cargador, WiFi)
- [ ] Crear backup completo
- [ ] Crear snapshot de Timeshift
- [ ] Probar acceso desde tablets
- [ ] Verificar que los cursos y exámenes están listos

---

## Comandos de referencia rápida

### Estado y monitoreo
```bash
/usr/local/bin/moodle-status.sh          # Estado completo
systemctl status nginx                    # Estado de Nginx
systemctl status php8.4-fpm              # Estado de PHP
systemctl status mariadb                  # Estado de MariaDB
systemctl status redis-server             # Estado de Redis
```

### Servicios
```bash
sudo systemctl restart nginx              # Reiniciar Nginx
sudo systemctl restart php8.4-fpm        # Reiniciar PHP
sudo systemctl restart mariadb            # Reiniciar MariaDB
sudo systemctl restart redis-server       # Reiniciar Redis
```

### Moodle
```bash
# Modo mantenimiento
sudo -u www-data php /var/www/moodle/admin/cli/maintenance.php --enable
sudo -u www-data php /var/www/moodle/admin/cli/maintenance.php --disable

# Purgar caché
sudo -u www-data php /var/www/moodle/admin/cli/purge_caches.php

# Ejecutar cron manualmente
sudo -u www-data php /var/www/moodle/admin/cli/cron.php
```

### Backups
```bash
sudo /usr/local/bin/moodle-backup.sh      # Crear backup
sudo /usr/local/bin/moodle-restore.sh     # Listar/restaurar backups
```

### Sistema
```bash
df -h                                     # Espacio en disco
free -h                                   # Memoria RAM
sudo timeshift --list                     # Listar snapshots
sudo timeshift --create                   # Crear snapshot
sudo shutdown now                         # Apagar
sudo reboot                               # Reiniciar
```

---

## Contacto y soporte

Para problemas técnicos que no puedas resolver con esta guía, consulta:

1. La documentación técnica en `moodle-install.md`
2. Los logs del sistema en `/var/log/`
3. La documentación oficial de Moodle: https://docs.moodle.org

---

*Última actualización: Enero 2026*
