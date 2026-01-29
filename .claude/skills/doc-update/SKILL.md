---
name: doc-update
description: Actualizar y mantener la documentación del proyecto. Usar cuando el usuario haya hecho cambios en el servidor y quiera documentarlos, o para mejorar la documentación existente.
user-invocable: true
allowed-tools: Read, Edit, Write, Grep, Glob
argument-hint: [archivo.md|sección|changelog]
---

# Skill: Mantenimiento de Documentación

Mantiene la documentación del proyecto actualizada y consistente.

## Argumentos

- `archivo.md`: Actualizar archivo específico
- `sección`: Actualizar sección específica (ej: "redis", "backup", "nginx")
- `changelog`: Agregar entrada al changelog de cambios
- Sin argumento: Revisar consistencia general

## Archivos de documentación

| Archivo | Propósito | Actualizar cuando... |
|---------|-----------|----------------------|
| `moodle-install.md` | Guía de instalación | Cambien procedimientos de instalación |
| `moodle-5.md` | Registro de upgrades | Se actualice Moodle o PHP |
| `comandos-moodle.md` | Referencia rápida | Se agreguen nuevos scripts o comandos |
| `testing-moodle.md` | Guía de testing | Cambien procedimientos de prueba |
| `CLAUDE.md` | Guía para Claude | Cambie el stack o arquitectura |
| `README.md` | Resumen del proyecto | Cambien versiones principales |

## Estilo de documentación

### Idioma
- Español (es-419, Latinoamérica)
- Comandos y código en inglés
- Términos técnicos pueden quedar en inglés

### Formato Markdown
- Encabezados con `#`, `##`, `###`
- Código en bloques con triple backtick y lenguaje
- Tablas para información estructurada
- Listas para pasos secuenciales

### Estructura de secciones
```markdown
## Título de la sección

Breve descripción del propósito.

### Prerrequisitos (si aplica)
- Requisito 1
- Requisito 2

### Procedimiento
1. Paso uno
2. Paso dos

### Verificación
```bash
comando para verificar
```

### Troubleshooting (si aplica)
- **Problema**: Descripción
  - **Solución**: Pasos
```

## Verificación de consistencia

Al revisar documentación, verificar:

1. **Versiones actualizadas**
   - PHP 8.4 (no 8.3)
   - Moodle 5.1.1 (no 4.x)
   - Debian 13 Trixie
   - MariaDB 11.8
   - Redis 8.0

2. **Rutas correctas**
   - Moodle: `/var/www/moodle`
   - Public: `/var/www/moodle/public`
   - Data: `/var/moodledata`
   - Config: `/var/www/moodle/config.php`

3. **Comandos PHP**
   - Usar `php8.4` o `php` (no php8.3)
   - Usuario: `www-data`

4. **Enlaces internos**
   - Referencias entre documentos funcionan
   - Secciones referenciadas existen

## Agregar changelog

Cuando se documenten cambios significativos, agregar al inicio del archivo relevante:

```markdown
> **Actualización YYYY-MM-DD**: Descripción breve del cambio realizado.
```

## Generación de PDFs

Después de cambios importantes, recordar al usuario:
- Los PDFs deben regenerarse manualmente
- Usar herramienta de conversión MD→PDF
- PDFs no se commitean (están en .gitignore por tamaño)
