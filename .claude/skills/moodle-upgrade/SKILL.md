---
name: moodle-upgrade
description: Planificar y ejecutar actualizaciones de Moodle, PHP, o componentes del stack. Usar cuando el usuario quiera actualizar versiones o verificar actualizaciones disponibles.
user-invocable: true
allowed-tools: Bash, Read, WebSearch, WebFetch
argument-hint: [check|plan|moodle|php|system]
---

# Skill: Actualización del Stack Moodle

Gestiona actualizaciones del servidor Moodle de forma segura.

## Argumentos

- `check`: Verificar versiones actuales y disponibles
- `plan`: Crear plan de actualización detallado
- `moodle`: Actualizar Moodle LMS
- `php`: Actualizar PHP
- `system`: Actualizar paquetes del sistema (apt)

## Verificación de versiones (`check`)

```bash
echo "=== Versiones actuales ==="
echo -n "Moodle: "
grep 'release' /var/www/moodle/version.php 2>/dev/null | head -1 || echo "No encontrado"

echo -n "PHP: "
php -v | head -1

echo -n "MariaDB: "
mariadb --version | head -1

echo -n "Nginx: "
nginx -v 2>&1

echo -n "Redis: "
redis-server --version

echo -n "Debian: "
cat /etc/debian_version

echo ""
echo "=== Actualizaciones disponibles ==="
sudo apt update -qq && apt list --upgradable 2>/dev/null | head -20
```

### Verificar última versión de Moodle
```bash
echo "Consultando tags de Moodle..."
git ls-remote --tags https://github.com/moodle/moodle.git 2>/dev/null | grep -E 'v[0-9]+\.[0-9]+\.[0-9]+$' | tail -10
```

## Plan de actualización (`plan`)

Al crear un plan, SIEMPRE incluir:

1. **Pre-requisitos**
   - Snapshot de Timeshift
   - Backup completo con moodle-backup.sh
   - Verificar espacio en disco (mínimo 5GB libres)
   - Programar ventana de mantenimiento

2. **Compatibilidad**
   - Verificar requisitos de PHP para nueva versión de Moodle
   - Revisar plugins instalados vs compatibilidad
   - Consultar Moodle release notes

3. **Procedimiento**
   - Activar modo mantenimiento
   - Ejecutar actualización
   - Verificar funcionamiento
   - Desactivar modo mantenimiento

4. **Rollback**
   - Restaurar snapshot si falla
   - O restaurar backup de BD + datos

## Actualización de Moodle (`moodle`)

Procedimiento estándar (consultar moodle-5.md para detalles):

```bash
# 1. Backup
sudo /usr/local/bin/moodle-backup.sh

# 2. Modo mantenimiento
sudo -u www-data php /var/www/moodle/admin/cli/maintenance.php --enable

# 3. Actualizar código
cd /var/www/moodle
sudo -u www-data git fetch origin
sudo -u www-data git checkout vX.Y.Z  # Nueva versión

# 4. Ejecutar upgrade
sudo -u www-data php /var/www/moodle/admin/cli/upgrade.php

# 5. Purgar caché
sudo -u www-data php /var/www/moodle/admin/cli/purge_caches.php

# 6. Desactivar mantenimiento
sudo -u www-data php /var/www/moodle/admin/cli/maintenance.php --disable
```

## Documentos de referencia

- `moodle-5.md`: Registro de actualización Moodle 4.5 → 5.1 + PHP 8.3 → 8.4
- `moodle-install.md`: Procedimientos de instalación base
- https://moodledev.io/general/releases - Release notes oficiales

## Advertencias

- NUNCA actualizar sin backup previo
- NUNCA actualizar durante horario de clases
- SIEMPRE probar en ventana de mantenimiento
- Si hay errores, NO continuar - restaurar backup
