# MoodleDebian

Documentación completa para instalar, mantener y escalar un servidor **Moodle portátil** sobre Debian 13 "Trixie", diseñado para atender **80-100 estudiantes simultáneos** en aulas sin conexión a Internet.

## Características

- **Portátil**: Funciona en un laptop que viaja entre ubicaciones
- **Offline**: No requiere Internet para operar
- **Optimizado**: Configurado para máximo rendimiento en 12GB RAM
- **Resiliente**: Backups automáticos y snapshots del sistema
- **Autodescubrimiento**: Los estudiantes acceden vía `http://moodle.local`

## Stack tecnológico

| Componente | Versión | Función |
|------------|---------|---------|
| Debian | 13 "Trixie" | Sistema operativo (XFCE) |
| Moodle | 5.1.1 | Plataforma de aprendizaje |
| PHP | 8.4-FPM | Motor de aplicación |
| MariaDB | 11.8 | Base de datos |
| Nginx | Debian default | Servidor web |
| Redis | 8.0 | Caché y sesiones |
| Timeshift | RSYNC | Snapshots del sistema |
| Avahi | mDNS | Descubrimiento de red |

## Documentación

### Guías principales

| Documento | Descripción |
|-----------|-------------|
| [moodle-install.md](moodle-install.md) | Guía completa de instalación desde cero |
| [manual-del-usuario.md](manual-del-usuario.md) | Manual de operación diaria |
| [comandos-moodle.md](comandos-moodle.md) | Referencia rápida de comandos |

### Guías especializadas

| Documento | Descripción |
|-----------|-------------|
| [moodle-5.md](moodle-5.md) | Registro de actualización Moodle 4.5 → 5.1 |
| [testing-moodle.md](testing-moodle.md) | Pruebas de carga para 60 estudiantes |

## Inicio rápido

### Acceder a Moodle
```
http://moodle.local
```
O usar la IP directa del servidor.

### Verificar estado del servidor
```bash
/usr/local/bin/moodle-status.sh
```

### Crear backup manual
```bash
sudo /usr/local/bin/moodle-backup.sh
```

### Reiniciar servicios
```bash
sudo systemctl restart nginx php8.4-fpm mariadb redis-server
```

## Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                    Tablets (WiFi)                           │
│              http://moodle.local                            │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────┐
│                   Laptop Servidor                           │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐        │
│  │  Nginx  │→ │ PHP-FPM │→ │ MariaDB │  │  Redis  │        │
│  │  :80    │  │  :9000  │  │  :3306  │  │  :6379  │        │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘        │
│       │            │            │            │              │
│       └────────────┴────────────┴────────────┘              │
│                         │                                   │
│  ┌──────────────────────▼──────────────────────────┐       │
│  │              /var/www/moodle                     │       │
│  │              /var/moodledata                     │       │
│  └─────────────────────────────────────────────────┘       │
│                                                             │
│  Avahi (mDNS) → moodle.local                               │
│  Timeshift    → Snapshots del sistema                      │
│  Cron         → Backups diarios 3:00 AM                    │
└─────────────────────────────────────────────────────────────┘
```

## Requisitos de hardware

| Componente | Mínimo | Recomendado |
|------------|--------|-------------|
| RAM | 8 GB | 12 GB |
| Almacenamiento | 60 GB SSD | 125 GB SSD |
| Procesador | 4 cores | 4+ cores |
| Red | WiFi integrado | WiFi + Ethernet |

## Rutas importantes

| Elemento | Ubicación |
|----------|-----------|
| Moodle | `/var/www/moodle` |
| Datos de usuarios | `/var/moodledata` |
| Configuración | `/var/www/moodle/config.php` |
| Backups | `~/backups/` |
| Scripts admin | `/usr/local/bin/moodle-*.sh` |
| Logs Nginx | `/var/log/nginx/` |

## Tareas automáticas

| Tarea | Frecuencia | Descripción |
|-------|------------|-------------|
| Cron de Moodle | Cada 5 min | Tareas programadas de Moodle |
| Backup completo | 3:00 AM diario | BD + archivos + config |
| Limpieza de backups | Con cada backup | Elimina backups > 30 días |

## Ecosistema Claude Code

Este proyecto incluye un ecosistema de Claude Code (`.claude/`) para asistencia con IA:

```bash
# Comandos disponibles
/moodle-status      # Estado del servidor
/moodle-backup      # Gestión de backups
/moodle-optimize    # Optimización
/moodle-test        # Pruebas de carga
/moodle-upgrade     # Actualizaciones
/moodle-security    # Auditoría de seguridad
```

Ver [.claude/README.md](.claude/README.md) para documentación completa.

## Contexto del proyecto

El servidor es un **laptop portátil** que viaja entre dos ubicaciones educativas con routers diferentes. Los estudiantes (60-100 simultáneos) acceden desde **tablets Windows 10** vía WiFi para realizar **exámenes tipo ICFES** generados con [R-exams](https://github.com/alvaretto/proyecto-r-exams-icfes-matematicas-optimizado).

## Licencia

Documentación de uso interno. Stack basado en software libre:
- Debian: DFSG
- Moodle: GPL v3
- MariaDB: GPL v2
- Nginx: BSD-2
- Redis: BSD-3
- PHP: PHP License
