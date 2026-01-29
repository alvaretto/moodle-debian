# Ecosistema Claude Code para MoodleDebian

Este directorio contiene la configuración completa de Claude Code para mantener, optimizar y escalar el servidor Moodle.

## Estructura

```
.claude/
├── settings.json           # Configuración compartida (permisos, hooks, env)
├── settings.local.json     # Configuración local (NO commitear)
├── skills/                 # Comandos personalizados (/comando)
│   ├── moodle-status/      # /moodle-status - Estado del servidor
│   ├── moodle-backup/      # /moodle-backup - Gestión de backups
│   ├── moodle-optimize/    # /moodle-optimize - Optimización
│   ├── moodle-test/        # /moodle-test - Pruebas de carga
│   ├── moodle-upgrade/     # /moodle-upgrade - Actualizaciones
│   ├── moodle-security/    # /moodle-security - Auditoría de seguridad
│   └── doc-update/         # /doc-update - Mantenimiento de docs
├── agents/                 # Agentes especializados
│   ├── moodle-ops/         # Operaciones y troubleshooting
│   ├── moodle-architect/   # Arquitectura y escalabilidad
│   └── moodle-docs/        # Documentación técnica
├── rules/                  # Reglas por contexto
│   ├── documentation.md    # Reglas para archivos .md
│   ├── sensitive-data.md   # Protección de datos sensibles
│   └── server-commands.md  # Reglas para comandos de servidor
├── hooks/                  # Scripts de automatización
│   ├── validate-edit.py    # Validar ediciones (PreToolUse)
│   ├── check-versions.sh   # Verificar versiones (PostToolUse)
│   └── log-changes.sh      # Registrar cambios (PostToolUse)
└── README.md               # Este archivo
```

## Skills disponibles

| Comando | Descripción | Argumentos |
|---------|-------------|------------|
| `/moodle-status` | Estado completo del servidor | `--full`, `--quick` |
| `/moodle-backup` | Gestión de backups | `run`, `list`, `verify`, `restore TIMESTAMP` |
| `/moodle-optimize` | Optimización de rendimiento | `php`, `mysql`, `redis`, `nginx`, `kernel`, `all` |
| `/moodle-test` | Pruebas de carga | `quick`, `full`, `N-students` |
| `/moodle-upgrade` | Planificar actualizaciones | `check`, `plan`, `moodle`, `php`, `system` |
| `/moodle-security` | Auditoría de seguridad | `audit`, `firewall`, `ssl`, `logs`, `harden` |
| `/doc-update` | Actualizar documentación | `archivo.md`, `sección`, `changelog` |

## Agentes especializados

### moodle-ops (Sonnet)
Operaciones del servidor - diagnóstico, mantenimiento, resolución de problemas en tiempo real.

### moodle-architect (Opus)
Arquitectura y escalabilidad - planificación de mejoras, optimización de recursos, diseño de soluciones.

### moodle-docs (Haiku)
Documentación técnica - redacción, consistencia, mantenimiento de guías.

## Hooks activos

| Evento | Hook | Función |
|--------|------|---------|
| SessionStart | mensaje | Mostrar contexto del proyecto |
| PreToolUse (Edit/Write) | validate-edit.py | Proteger archivos sensibles |
| PostToolUse (Edit/Write) | check-versions.sh | Verificar versiones en docs |
| PostToolUse (Edit/Write) | log-changes.sh | Registrar cambios |

## Variables de entorno

Definidas en `settings.json`:
- `MOODLE_SERVER`: moodle.local
- `MOODLE_PATH`: /var/www/moodle
- `MOODLEDATA_PATH`: /var/moodledata
- `PHP_VERSION`: 8.4
- `MOODLE_VERSION`: 5.1.1

## Uso

### Ejecutar un skill
```
/moodle-status
/moodle-backup list
/moodle-optimize mysql
```

### Los agentes se invocan automáticamente
Claude selecciona el agente apropiado según la tarea:
- Problemas de servidor → moodle-ops
- Planificación de mejoras → moodle-architect
- Actualizar documentación → moodle-docs

## Mantenimiento

### Actualizar versiones
Editar `settings.json` y actualizar las variables de entorno cuando cambie el stack.

### Agregar nuevos skills
1. Crear directorio en `skills/nombre-skill/`
2. Crear archivo `SKILL.md` con frontmatter YAML
3. Documentar en este README

### Modificar hooks
1. Editar scripts en `hooks/`
2. Asegurar que son ejecutables (`chmod +x`)
3. Actualizar `settings.json` si cambian nombres
