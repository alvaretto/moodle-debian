# Actualización de Moodle 4.5 a Moodle 5.1 con PHP 8.4

## Contexto

| Aspecto | Antes (4.5) | Después (5.1) |
|---------|-------------|---------------|
| **Moodle** | 4.5 (MOODLE_405_STABLE) | 5.1 (MOODLE_501_STABLE) |
| **PHP** | 8.3 | 8.4 |
| **MariaDB** | 11.8 (Debian 13) | 11.8 (sin cambios, cumple requisito >= 10.6) |
| **SO** | Debian 13 "Trixie" | Sin cambios |
| **Nginx root** | `/var/www/moodle` | `/var/www/moodle/public` |

**Fecha**: Enero 2026

**Decisión**: Saltar Moodle 5.0 (release regular, soporte hasta oct 2026) e ir directo a 5.1 (soporte hasta abr 2027). El upgrade directo de 4.5 a 5.1 es posible porque el requisito mínimo es Moodle 4.2.3+. Proveedores como Open LMS han tomado la misma decisión.

Fuente: [Skipping 5.0 for 5.1 - Open LMS](https://support.openlms.net/hc/en-us/articles/21405723422876-Skipping-Moodle-5-0-and-Preparing-for-a-Direct-Upgrade-to-5-1)

---

## Requisitos de Moodle 5.1

| Componente | Mínimo | Tu sistema | Estado |
|------------|--------|------------|--------|
| PHP | 8.2.0 | 8.4 | OK |
| MariaDB | 10.6 | 11.8 | OK |
| `max_input_vars` | >= 5000 | 5000 | OK (ya configurado) |
| Extensión `sodium` | Requerida | Verificar | Instalar si falta |
| Prefijo BD (`$CFG->prefix`) | <= 10 chars | `mdl_` (4 chars) | OK |
| Arquitectura PHP | 64-bit | 64-bit | OK |
| Moodle origen | >= 4.2.3 | 4.5 | OK |

Fuentes:
- [Moodle 5.1 Release Notes](https://moodledev.io/general/releases/5.1)
- [Technical Requirements](https://moodledev.io/docs/5.0/gettingstarted/requirements)

---

## Cambio estructural en Moodle 5.1: directorio `/public`

Este es el cambio más importante de la actualización. A partir de Moodle 5.1, el código se reorganiza:

```
/var/www/moodle/              <-- Raíz de instalación (NO accesible desde web)
├── config.php                <-- Configuración (fuera del web root = más seguro)
├── lib/                      <-- Librerías del core
├── admin/                    <-- Herramientas de administración
├── course/                   <-- Lógica de cursos
├── ...                       <-- Resto del core
└── public/                   <-- NUEVO: Document root del servidor web
    ├── index.php
    ├── r.php                 <-- Router de Moodle (nuevo routing engine)
    ├── theme/
    ├── mod/
    ├── blocks/
    └── ...                   <-- Archivos accesibles por HTTP
```

**Impacto**: Nginx debe apuntar a `/var/www/moodle/public` en lugar de `/var/www/moodle`. Si no se actualiza, Moodle no cargará.

**`config.php`**: Sigue en `/var/www/moodle/config.php` (fuera del directorio público). `$CFG->wwwroot` y `$CFG->dirroot` siguen funcionando. Se añade `$CFG->root` (solo lectura) apuntando a la raíz de instalación.

Fuentes:
- [Code Restructure Guide](https://moodledev.io/docs/5.1/guides/restructure)
- [Nginx - MoodleDocs](https://docs.moodle.org/501/en/Nginx)
- [Upgrading to 5.1? Read this first](https://moodle.org/mod/forum/discuss.php?d=470193)

---

## Cambios heredados de Moodle 5.0

Al saltar de 4.5 a 5.1, también se aplican los cambios de 5.0:

### Eliminado del core

| Componente | Estado | Acción necesaria |
|------------|--------|------------------|
| **Editor Atto** | Eliminado del core | TinyMCE es el editor incluido. Si necesitas Atto: [GitHub](https://github.com/moodlehq/moodle-editor_atto) |
| **Actividad Survey** | Eliminada del core | Buscar alternativa si la usabas |
| **Soporte Oracle DB** | Eliminado | No aplica (usas MariaDB) |

### Cambios en frontend

- **Bootstrap 5**: Actualización desde Bootstrap 4. El tema Boost se adapta automáticamente.
- **TinyMCE 6**: Editor por defecto.
- **WCAG 2.1**: Mejoras de accesibilidad.

### Nuevas funcionalidades (5.0 + 5.1)

- Proveedor de IA Ollama configurable desde administración.
- Vista general de actividades para profesores y estudiantes.
- Banco de preguntas a nivel de curso.
- **Nuevo routing engine** (5.1): URLs más limpias. Es opcional; hay capa de compatibilidad.

Fuentes:
- [Moodle 5.0 Developer Update](https://moodledev.io/docs/5.0/devupdate)
- [Configuring the Router](https://docs.moodle.org/501/en/Configuring_the_Router)

---

## Compatibilidad de plugins

| Plugin | Versión para 5.1 | Estado | Acción |
|--------|-------------------|--------|--------|
| **format_onetopic** | Rama `master` | Compatible (confirmado por usuarios en 5.1) | `git checkout master` |
| **format_multitopic** | Tag `v5.0.1` / rama `master` | Compatible (incluye CI para 5.1) | `git checkout v5.0.1` o `master` |

Fuentes:
- [Onetopic - Moodle Plugins](https://moodle.org/plugins/format_onetopic)
- [Multitopic - GitHub Releases](https://github.com/james-cnz/moodle-format_multitopic/releases)

---

## Checklist de seguimiento

Marca cada paso al completarlo:

```
FASE 0: BACKUPS Y SNAPSHOTS
[x] 0.1 - Crear snapshot Timeshift del sistema completo
[x] 0.2 - Ejecutar backup completo de Moodle (BD + moodledata + config.php)
[x] 0.3 - Verificar que los backups son válidos

FASE 1: PREPARAR PHP 8.4
[x] 1.1 - Verificar paquetes PHP 8.4 instalados
[x] 1.2 - Extensión sodium (viene incluida en php8.4-common)
[x] 1.3 - Copiar configuración PHP 8.3 a PHP 8.4 (php.ini, pool, opcache)
[x] 1.4 - Cambiar socket PHP-FPM en Nginx (php8.3 -> php8.4)
[x] 1.5 - Activar PHP 8.4 FPM, desactivar PHP 8.3 FPM

FASE 2: ACTUALIZAR MOODLE A 5.1
[x] 2.1 - Activar modo mantenimiento
[x] 2.2 - Checkout tag v5.1.1 (git fetch --tags necesario por clone single-branch)
[x] 2.3 - Actualizar plugins (onetopic master, multitopic v5.0.1)
[x] 2.4 - Actualizar Nginx: root /var/www/moodle/public + try_files /r.php
[x] 2.5 - Ejecutar upgrade.php --non-interactive (4.5.8+ → 5.1.1 exitoso)
[x] 2.6 - Desactivar modo mantenimiento
[x] 2.7 - Verificar funcionamiento (HTTP 200 OK)

FASE 3: POST-ACTUALIZACIÓN
[x] 3.1 - Purgar cachés (requirió fix permisos /var/cache/moodle)
[x] 3.2 - Verificar acceso (192.168.0.2 funciona, moodle.local pendiente mDNS)
[ ] 3.3 - Verificar editor TinyMCE funciona (pendiente: prueba manual)
[ ] 3.4 - Verificar plugins de formato de curso (pendiente: prueba manual)
[ ] 3.5 - Verificar importación XML de R-exams (pendiente: prueba manual)
[x] 3.6 - Verificar permisos de directorios
[x] 3.7 - Crear snapshot Timeshift post-actualización
[x] 3.8 - Actualizar documentación (comandos-moodle.md, moodle-install.md)

OPTIMIZACIÓN POST-UPGRADE (adicional)
[x] Instalar y activar Redis server para sesiones
[x] Configurar OPcache JIT tracing
[x] Ajustar PHP-FPM, MariaDB y OPcache para 12GB RAM
[x] Actualizar crontab php8.3 → php8.4
[x] Actualizar moodle-status.sh con redis-server
```

**Actualización ejecutada**: 27 de enero de 2026.
**Resultado**: Moodle 5.1.1 (Build: 20251208) funcionando con PHP 8.4 + Redis + JIT.

---

## FASE 0: Backups y snapshots

### 0.1 Crear snapshot Timeshift

```bash
sudo timeshift --create --comments "Pre-upgrade Moodle 5.1 - Sistema completo"
```

Verificar que se creó:

```bash
sudo timeshift --list
```

### 0.2 Ejecutar backup completo de Moodle

```bash
sudo /usr/local/bin/moodle-backup.sh
```

### 0.3 Verificar que los backups son válidos

```bash
# Verificar que los archivos existen y tienen tamaño razonable
ls -lh ~/backups/

# Verificar integridad del dump de BD
gunzip -t ~/backups/db_*.sql.gz && echo "BD OK" || echo "BD CORRUPTA"

# Verificar integridad del tar de moodledata
tar -tzf ~/backups/moodledata_*.tar.gz > /dev/null && echo "Moodledata OK" || echo "Moodledata CORRUPTO"
```

---

## FASE 1: Preparar PHP 8.4

### 1.1 Verificar paquetes PHP 8.4 instalados

```bash
# Ver versión activa
php -v

# Listar módulos PHP 8.4 instalados
dpkg -l | grep php8.4
```

Si faltan módulos, instalarlos:

```bash
sudo apt install -y php8.4-fpm php8.4-mysql php8.4-xml php8.4-mbstring \
  php8.4-curl php8.4-zip php8.4-gd php8.4-intl php8.4-soap \
  php8.4-opcache php8.4-redis php8.4-apcu
```

### 1.2 Instalar extensión sodium

Moodle 5.x requiere la extensión `sodium`:

```bash
sudo apt install -y php8.4-sodium
```

Verificar:

```bash
php -m | grep sodium
# Debe mostrar: sodium
```

### 1.3 Copiar configuración de PHP 8.3 a PHP 8.4

#### php.ini (FPM y CLI)

Aplicar la misma configuración en ambos archivos:

```bash
sudo nano /etc/php/8.4/fpm/php.ini
sudo nano /etc/php/8.4/cli/php.ini
```

Valores a configurar (mismos que tenías en 8.3):

```ini
upload_max_filesize = 100M
post_max_size = 100M
max_execution_time = 300
max_input_vars = 5000
memory_limit = 256M
```

Verificar `max_input_vars` desde CLI:

```bash
php -i | grep max_input_vars
# Debe mostrar: max_input_vars => 5000 => 5000
```

#### Pool PHP-FPM

```bash
sudo nano /etc/php/8.4/fpm/pool.d/www.conf
```

```ini
pm = dynamic
pm.max_children = 50
pm.start_servers = 10
pm.min_spare_servers = 5
pm.max_spare_servers = 20
pm.max_requests = 500
php_admin_value[memory_limit] = 256M
```

#### OPcache

```bash
sudo nano /etc/php/8.4/fpm/conf.d/10-opcache.ini
```

```ini
opcache.enable = 1
opcache.memory_consumption = 256
opcache.interned_strings_buffer = 32
opcache.max_accelerated_files = 20000
opcache.revalidate_freq = 60
opcache.fast_shutdown = 1
```

### 1.4 Cambiar socket PHP-FPM en Nginx

```bash
sudo nano /etc/nginx/sites-available/moodle
```

Cambiar la línea del socket:

```nginx
# ANTES (PHP 8.3):
# fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;

# DESPUÉS (PHP 8.4):
fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
```

**No cambiar el `root` todavía** — eso se hará en la FASE 2 junto con el cambio de código Moodle.

### 1.5 Activar PHP 8.4 FPM, desactivar PHP 8.3 FPM

```bash
sudo systemctl stop php8.3-fpm
sudo systemctl disable php8.3-fpm
sudo systemctl enable php8.4-fpm
sudo systemctl start php8.4-fpm
sudo nginx -t && sudo systemctl restart nginx
```

Verificar que los servicios corren:

```bash
systemctl status php8.4-fpm
systemctl status nginx
```

> **Nota**: En este punto Moodle 4.5 no funcionará con PHP 8.4 (es esperado). Continúa directamente con la FASE 2.

---

## FASE 2: Actualizar Moodle a 5.1

### 2.1 Activar modo mantenimiento

Usar PHP 8.3 explícitamente porque 4.5 no soporta PHP 8.4:

```bash
sudo -u www-data /usr/bin/php8.3 /var/www/moodle/admin/cli/maintenance.php --enable
```

### 2.2 Cambiar rama git a MOODLE_501_STABLE

```bash
cd /var/www/moodle

# Obtener las últimas ramas y tags del repositorio
sudo -u www-data git fetch origin

# Ver tags disponibles de la serie 5.1
sudo -u www-data git tag -l "v5.1*"

# Opción A (recomendada): Usar el tag de release más reciente
# Reemplaza v5.1.X por el tag más reciente que aparezca (ej: v5.1.0, v5.1.1...)
sudo -u www-data git checkout v5.1.X

# Opción B: Usar la rama estable (recibe actualizaciones semanales)
sudo -u www-data git checkout MOODLE_501_STABLE
```

> **Importante**: Para producción, Moodle recomienda usar un **tag de release** (ej: `v5.1.0`) en lugar de la rama `MOODLE_501_STABLE`, porque la rama recibe cambios semanales.

Fuente: [Git for Administrators - MoodleDocs](https://docs.moodle.org/501/en/Git_for_Administrators)

### 2.3 Actualizar plugins

Después del checkout, los plugins en `course/format/` pueden haber sido sobrescritos por el código de Moodle 5.1. Verificar y reinstalar:

#### format_onetopic

```bash
cd /var/www/moodle/course/format/

# Si el directorio onetopic ya no existe (git lo eliminó), re-clonar:
sudo -u www-data git clone https://github.com/davidherney/moodle-format_onetopic.git onetopic

cd onetopic
sudo -u www-data git checkout master
```

Si el directorio existe y tiene repositorio git:

```bash
cd /var/www/moodle/course/format/onetopic
sudo -u www-data git fetch origin
sudo -u www-data git checkout master
```

#### format_multitopic

```bash
cd /var/www/moodle/course/format/

# Si el directorio no existe, re-clonar:
sudo -u www-data git clone https://github.com/james-cnz/moodle-format_multitopic.git multitopic

cd multitopic
sudo -u www-data git checkout v5.0.1
```

Si el directorio existe:

```bash
cd /var/www/moodle/course/format/multitopic
sudo -u www-data git fetch origin
sudo -u www-data git checkout v5.0.1
```

### 2.4 Actualizar Nginx: document root a `/public`

Este es el paso clave de Moodle 5.1. Editar la configuración de Nginx:

```bash
sudo nano /etc/nginx/sites-available/moodle
```

Configuración completa actualizada para Moodle 5.1:

```nginx
server {
    listen 80;
    server_name moodle.local _;

    # CAMBIO MOODLE 5.1: root apunta a /public
    root /var/www/moodle/public;
    index index.php index.html;

    access_log /var/log/nginx/moodle_access.log;
    error_log /var/log/nginx/moodle_error.log;

    client_max_body_size 100M;

    # Compresión para tablets lentas
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml application/json application/javascript
               application/xml application/xml+rss text/javascript;
    gzip_min_length 1000;

    location / {
        try_files $uri $uri/ /r.php;
    }

    location ~ [^/]\.php(/|$) {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_read_timeout 300;
        fastcgi_send_timeout 300;
    }

    location ~ /\.(?!well-known) {
        deny all;
    }

    location ~* \.(engine|inc|install|make|module|profile|po|sh|sql|theme|twig|tpl(\.php)?|xtmpl|yml)(~|\.sw[op]|\.bak|\.orig)?$ {
        deny all;
    }
}
```

**Cambios respecto a la configuración anterior**:

1. `root` cambia de `/var/www/moodle` a `/var/www/moodle/public`
2. `try_files` incluye `/r.php` (el nuevo router de Moodle 5.1)

Verificar y aplicar:

```bash
sudo nginx -t && sudo systemctl restart nginx
```

### 2.5 Ejecutar upgrade.php por CLI

```bash
sudo -u www-data php /var/www/moodle/admin/cli/upgrade.php
```

El proceso:

1. Verificará requisitos del entorno (PHP 8.4, MariaDB 11.8, sodium, etc.)
2. Pedirá confirmación (responder `s` o `y`)
3. Ejecutará las migraciones de base de datos (incluye cambios de 5.0 y 5.1)
4. Registrará plugins actualizados
5. Mostrará `++ Success ++` / `++ Éxito ++` al terminar

> **Si falla**: No entrar en pánico. El sistema anterior sigue intacto gracias a los backups de la FASE 0. Ver sección "Rollback" al final.

### 2.6 Desactivar modo mantenimiento

```bash
sudo -u www-data php /var/www/moodle/admin/cli/maintenance.php --disable
```

### 2.7 Verificar funcionamiento

Abrir en el navegador:

```bash
firefox http://localhost &
```

Verificar en **Administración del sitio > Servidor > Entorno**:

- Todos los checks en verde
- PHP 8.4 reconocido
- MariaDB 11.8 reconocida
- Extensión sodium presente
- Moodle 5.1 como versión activa

---

## FASE 3: Post-actualización

### 3.1 Purgar cachés

```bash
sudo -u www-data php /var/www/moodle/admin/cli/purge_caches.php
```

### 3.2 Verificar acceso desde tablet/navegador

- Acceder a `http://moodle.local` desde otro dispositivo en la misma red
- Verificar que la página carga correctamente
- Verificar login de estudiante

### 3.3 Verificar editor TinyMCE

- Entrar a cualquier actividad que tenga campo de texto enriquecido
- Verificar que el editor TinyMCE carga y permite escribir
- Si usabas Atto y lo necesitas: [GitHub - editor_atto](https://github.com/moodlehq/moodle-editor_atto)

### 3.4 Verificar plugins de formato de curso

- Entrar a un curso con formato Onetopic o Multitopic
- Verificar que las pestañas aparecen y funcionan
- Navegar entre secciones

### 3.5 Verificar importación XML de R-exams

- Ir a **Administración del sitio > Banco de preguntas > Importar**
- Importar un archivo XML de prueba generado con R-exams
- Verificar que las preguntas se importan correctamente

### 3.6 Verificar permisos de directorios

Después de cambiar PHP y Moodle, verificar que los permisos son correctos:

```bash
# Verificar propietario de moodledata
ls -la /var/moodledata
# Debe ser: www-data:www-data

# Verificar propietario de cache y sesiones
ls -la /var/cache/moodle
ls -la /tmp/moodle_sessions

# Corregir si es necesario
sudo chown -R www-data:www-data /var/moodledata /var/cache/moodle /tmp/moodle_sessions
sudo chmod 750 /var/moodledata

# Verificar que PHP-FPM 8.4 corre como www-data
grep -E "^user|^group" /etc/php/8.4/fpm/pool.d/www.conf
```

> **Nota**: La captura `FireShot Capture 002 - Error - moodle.local.png` del proyecto muestra el error "Invalid permissions detected when trying to create a directory". Este es exactamente el tipo de error que se previene con esta verificación.

### 3.7 Crear snapshot post-actualización

```bash
sudo timeshift --create --comments "Post-upgrade Moodle 5.1 + PHP 8.4 - Funcionando"
```

### 3.8 Actualizar documentación

Actualizar `comandos-moodle.md`:

- `php8.3-fpm` -> `php8.4-fpm`
- `/etc/php/8.3/` -> `/etc/php/8.4/`
- `/usr/bin/php8.3` -> `/usr/bin/php8.4`

Actualizar `moodle-install.md`:

- `MOODLE_405_STABLE` -> `MOODLE_501_STABLE`
- `php8.2` / `php8.3` -> `php8.4`
- `root /var/www/moodle;` -> `root /var/www/moodle/public;`
- Socket: `php8.2-fpm.sock` -> `php8.4-fpm.sock`

---

## Rollback (si algo sale mal)

### Opción A: Revertir Moodle y Nginx (problema en la actualización)

```bash
# 1. Activar mantenimiento (si Moodle aún responde)
sudo -u www-data php /var/www/moodle/admin/cli/maintenance.php --enable

# 2. Volver a la rama anterior
cd /var/www/moodle
sudo -u www-data git checkout MOODLE_405_STABLE

# 3. Restaurar plugins a versión anterior
cd /var/www/moodle/course/format/onetopic
sudo -u www-data git checkout MOODLE_405_STABLE

cd /var/www/moodle/course/format/multitopic
sudo -u www-data git checkout v4.5.3

# 4. Restaurar base de datos desde backup
sudo /usr/local/bin/moodle-restore.sh

# 5. Revertir Nginx: root vuelve a /var/www/moodle (sin /public)
sudo nano /etc/nginx/sites-available/moodle
# Cambiar: root /var/www/moodle/public; -> root /var/www/moodle;
# Cambiar: try_files $uri $uri/ /r.php; -> try_files $uri $uri/ /index.php?$query_string;
# Cambiar: php8.4-fpm.sock -> php8.3-fpm.sock

# 6. Revertir a PHP 8.3
sudo systemctl stop php8.4-fpm
sudo systemctl start php8.3-fpm
sudo nginx -t && sudo systemctl restart nginx

# 7. Desactivar mantenimiento
sudo -u www-data /usr/bin/php8.3 /var/www/moodle/admin/cli/maintenance.php --disable
```

### Opción B: Restaurar sistema completo (problema grave)

```bash
# Restaurar snapshot de Timeshift
sudo timeshift --restore
# Seleccionar el snapshot "Pre-upgrade Moodle 5.1"
# Reiniciar cuando pida
```

---

## Soporte y ciclo de vida

| Versión | Tipo | Fin de bugs | Fin de seguridad |
|---------|------|-------------|------------------|
| Moodle 4.5 | LTS | Abril 2027 | Octubre 2027 |
| ~~Moodle 5.0~~ | ~~Regular~~ | ~~Abril 2026~~ | ~~Octubre 2026~~ |
| **Moodle 5.1** | Regular | Octubre 2026 | Abril 2027 |
| Moodle 5.2 | Regular | Abril 2027 | Octubre 2027 |
| Moodle 5.3 | LTS | (por confirmar) | (por confirmar) |

La próxima LTS será **Moodle 5.3** (prevista octubre 2026).

Fuentes:
- [Moodle Releases](https://moodledev.io/general/releases)
- [Moodle 5.1 Release Notes](https://moodledev.io/general/releases/5.1)
- [Upgrading - MoodleDocs](https://docs.moodle.org/501/en/Upgrading)
- [Code Restructure Guide](https://moodledev.io/docs/5.1/guides/restructure)
- [Nginx - MoodleDocs](https://docs.moodle.org/501/en/Nginx)
- [Git for Administrators](https://docs.moodle.org/501/en/Git_for_Administrators)
- [Upgrading to 5.1? Read this first](https://moodle.org/mod/forum/discuss.php?d=470193)
- [Moodle 5.1 Public Folder Guide](https://elearning.3rdwavemedia.com/blog/moodle-5-upgrade-guide-public-folder-structure/7321/)
