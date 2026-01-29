---
name: moodle-backup
description: Ejecutar o verificar backups de Moodle. Usar cuando el usuario quiera hacer backup, restaurar, o verificar el estado de los backups.
user-invocable: true
allowed-tools: Bash, Read
argument-hint: [run|list|verify|restore TIMESTAMP]
---

# Skill: Gestión de Backups de Moodle

Gestiona los backups del servidor Moodle según el argumento recibido.

## Argumentos

- `run` o sin argumento: Ejecutar backup completo
- `list`: Listar backups disponibles
- `verify`: Verificar integridad del último backup
- `restore TIMESTAMP`: Restaurar un backup específico (ej: `20260126_215808`)

## Acciones por argumento

### `run` - Ejecutar backup
```bash
# Verificar que existe el script
if [ -x /usr/local/bin/moodle-backup.sh ]; then
  echo "Iniciando backup de Moodle..."
  sudo /usr/local/bin/moodle-backup.sh
  echo ""
  echo "Últimos backups creados:"
  ls -lh ~/backups/ | tail -5
else
  echo "ERROR: Script de backup no encontrado en /usr/local/bin/moodle-backup.sh"
  echo "Consulta moodle-install.md sección de backups para instalarlo"
fi
```

### `list` - Listar backups
```bash
echo "=== Backups de Base de Datos ==="
ls -lh ~/backups/db_*.sql.gz 2>/dev/null | tail -10 || echo "No hay backups de BD"
echo ""
echo "=== Backups de Moodledata ==="
ls -lh ~/backups/moodledata_*.tar.gz 2>/dev/null | tail -10 || echo "No hay backups de datos"
echo ""
echo "=== Espacio usado ==="
du -sh ~/backups/ 2>/dev/null || echo "Directorio ~/backups/ no existe"
```

### `verify` - Verificar integridad
```bash
echo "Verificando último backup de BD..."
LAST_DB=$(ls -t ~/backups/db_*.sql.gz 2>/dev/null | head -1)
if [ -n "$LAST_DB" ]; then
  gzip -t "$LAST_DB" && echo "✅ $LAST_DB - OK" || echo "❌ $LAST_DB - CORRUPTO"
  echo "Tamaño: $(ls -lh "$LAST_DB" | awk '{print $5}')"
else
  echo "No hay backups de BD"
fi

echo ""
echo "Verificando último backup de datos..."
LAST_DATA=$(ls -t ~/backups/moodledata_*.tar.gz 2>/dev/null | head -1)
if [ -n "$LAST_DATA" ]; then
  gzip -t "$LAST_DATA" && echo "✅ $LAST_DATA - OK" || echo "❌ $LAST_DATA - CORRUPTO"
  echo "Tamaño: $(ls -lh "$LAST_DATA" | awk '{print $5}')"
else
  echo "No hay backups de datos"
fi
```

### `restore TIMESTAMP` - Restaurar
```bash
# IMPORTANTE: Confirmar con el usuario antes de restaurar
echo "⚠️  RESTAURACIÓN DE BACKUP"
echo "Esto sobrescribirá la base de datos y archivos actuales."
echo ""
if [ -x /usr/local/bin/moodle-restore.sh ]; then
  sudo /usr/local/bin/moodle-restore.sh $ARGUMENTS
else
  echo "Script de restauración no encontrado"
fi
```

## Notas importantes

- El backup automático se ejecuta diariamente a las 3:00 AM
- Los backups se eliminan automáticamente después de 30 días
- Antes de restaurar, SIEMPRE crear un snapshot con Timeshift
- Ubicación de backups: `~/backups/`
- Log de backups: `/var/log/moodle-backup.log`
