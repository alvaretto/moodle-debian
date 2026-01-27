# MoodleDebian

Documentación para instalar y mantener un servidor Moodle portátil sobre Debian 13 "Trixie", diseñado para atender 80-100 estudiantes simultáneos en aulas sin conexión a Internet.

## Stack actual

| Componente | Versión |
|------------|---------|
| Debian | 13 "Trixie" (XFCE) |
| Moodle | 5.1.1 (tag v5.1.1) |
| PHP | 8.4 (FPM) |
| MariaDB | 11.8 |
| Nginx | Debian default |
| Redis | 8.0 (sesiones + caché) |
| Timeshift | RSYNC snapshots |

## Documentos

| Archivo | Contenido |
|---------|-----------|
| [moodle-install.md](moodle-install.md) | Guía completa de instalación desde cero: Debian, XFCE, LEMP, Moodle, Timeshift, mDNS, optimización, plugins, backups |
| [moodle-5.md](moodle-5.md) | Plan y registro de la actualización Moodle 4.5 + PHP 8.3 a Moodle 5.1 + PHP 8.4 |
| [comandos-moodle.md](comandos-moodle.md) | Referencia rápida de comandos: backup, restauración, servicios, cron |

## Contexto

El servidor es un portátil con 12 GB RAM y SSD 125 GB que viaja entre dos ubicaciones con routers diferentes. Los estudiantes acceden desde tablets Windows 10 vía WiFi usando `http://moodle.local` (mDNS) o la IP directa. El contenido son exámenes tipo ICFES generados con [R-exams](https://github.com/alvaretto/proyecto-r-exams-icfes-matematicas-optimizado).
