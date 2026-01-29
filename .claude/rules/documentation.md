# Reglas para archivos de documentación (*.md)

## Al editar documentación Markdown

### Verificar antes de editar
- Leer el archivo completo para entender estructura
- Identificar secciones relacionadas que puedan necesitar actualización
- Verificar versiones mencionadas (PHP 8.4, Moodle 5.1.1, etc.)

### Formato consistente
- Usar encabezados jerárquicos (#, ##, ###)
- Bloques de código con triple backtick y lenguaje
- Tablas para datos estructurados
- Listas numeradas para pasos secuenciales

### Comandos y código
- Todos los comandos deben ser copy-paste ready
- Incluir comentarios explicativos en scripts largos
- Usar rutas absolutas cuando sea posible
- Especificar usuario (sudo, www-data) cuando sea necesario

### No hacer
- No agregar emojis (excepto en mensajes de estado)
- No usar inglés para texto explicativo
- No duplicar información que existe en otro archivo
- No agregar secciones vacías o placeholders

### Versiones actuales (Enero 2026)
```
Debian: 13 "Trixie"
Moodle: 5.1.1 (tag v5.1.1)
PHP: 8.4-FPM
MariaDB: 11.8
Redis: 8.0
Nginx: default Debian
```
