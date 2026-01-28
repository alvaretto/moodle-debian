# Testing de Rendimiento para Moodle 5.1 — 60 Estudiantes Simultáneos

Guía para probar que el servidor Moodle portátil soporta 60 estudiantes
conectados simultáneamente desde tablets, antes de usarlo en clase.

**Hardware del servidor**: Intel Celeron B820 @ 1.70GHz, 2 cores, 12 GB RAM, SSD 125 GB
**Software**: Debian 13, Nginx, PHP 8.4-FPM, MariaDB 11.8, Redis 8.0
**Objetivo**: Simular 60 tablets haciendo login, navegando cursos y respondiendo cuestionarios

---

## Índice

1. [Fase 1: Preparar el entorno de prueba](#fase-1-preparar-el-entorno-de-prueba)
2. [Fase 2: Generar curso y usuarios de prueba](#fase-2-generar-curso-y-usuarios-de-prueba)
3. [Fase 3: Instalar JMeter](#fase-3-instalar-jmeter)
4. [Fase 4: Generar el plan de prueba](#fase-4-generar-el-plan-de-prueba)
5. [Fase 5: Ejecutar la prueba de carga](#fase-5-ejecutar-la-prueba-de-carga)
6. [Fase 6: Monitorear durante la prueba](#fase-6-monitorear-durante-la-prueba)
7. [Fase 7: Interpretar resultados](#fase-7-interpretar-resultados)
8. [Fase 8: Limpieza](#fase-8-limpieza)
9. [Prueba rápida sin JMeter](#prueba-rápida-sin-jmeter)
10. [Referencia de tamaños](#referencia-de-tamaños)

---

## Fase 1: Preparar el entorno de prueba

### 1.1. Crear snapshot antes de empezar

**IMPORTANTE**: Las herramientas de testing generan datos ficticios masivos.
Crear un snapshot para poder revertir después.

```bash
sudo timeshift --create --comments "Antes de testing de rendimiento"
```

### 1.2. Habilitar modo debug (requerido por los generadores)

Los generadores de Moodle solo funcionan con debug en nivel DEVELOPER.

**Opción A** — Desde la interfaz web:
```
Administración del sitio → Desarrollo → Depuración
  → Mensajes de debug: DEVELOPER
  → Guardar cambios
```

**Opción B** — Desde config.php (temporal):
```bash
sudo nano /var/www/moodle/config.php
```
Añadir antes de `require_once`:
```php
$CFG->debug = (E_ALL | E_STRICT);
$CFG->debugdisplay = 1;
```

**Opción C** — Usar `--bypasscheck` en cada comando (no requiere cambiar debug).

> **Recuerda**: Después de las pruebas, volver a poner debug en 0.

### 1.3. Configurar contraseña para usuarios de prueba

Añadir en `/var/www/moodle/config.php` (antes de `require_once`):

```php
$CFG->tool_generator_users_password = 'moodle';
```

Esto establece la contraseña `moodle` para todos los usuarios generados.

```bash
sudo nano /var/www/moodle/config.php
# Añadir la línea y guardar
sudo systemctl restart php8.4-fpm
```

---

## Fase 2: Generar curso y usuarios de prueba

### 2.1. Generar un curso de prueba tamaño M

El tamaño **M** genera ~100 usuarios inscritos, ideal para simular 60 simultáneos.

```bash
sudo -u www-data php8.4 /var/www/moodle/public/admin/tool/generator/cli/maketestcourse.php \
  --shortname=LOADTEST_60 \
  --fullname="Prueba de Carga - 60 Estudiantes" \
  --size=M \
  --bypasscheck
```

Esto crea un curso con:
- Usuarios inscritos (estudiantes + profesores)
- Instancias de foro con discusiones
- Instancias de páginas
- Cuestionarios y actividades

> **Tiempo estimado**: ~5-10 minutos para tamaño M.

### 2.2. Verificar el curso generado

```bash
# Ver que el curso existe en la BD
sudo mariadb -e "SELECT id, shortname, fullname FROM moodle.mdl_course WHERE shortname='LOADTEST_60';"

# Contar usuarios inscritos
sudo mariadb -e "
  SELECT COUNT(*) as usuarios_inscritos
  FROM moodle.mdl_user_enrolments ue
  JOIN moodle.mdl_enrol e ON ue.enrolid = e.id
  JOIN moodle.mdl_course c ON e.courseid = c.id
  WHERE c.shortname = 'LOADTEST_60';
"
```

---

## Fase 3: Instalar JMeter

JMeter es una aplicación Java. Necesita Java Runtime (JRE).

### 3.1. Instalar Java

```bash
sudo apt install -y default-jre
java -version
# Debe mostrar: openjdk version "17.x.x" o similar
```

### 3.2. Descargar JMeter

```bash
# Descargar Apache JMeter 5.6.3 (última versión estable)
cd /opt
sudo wget https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-5.6.3.tgz
sudo tar -xzf apache-jmeter-5.6.3.tgz
sudo rm apache-jmeter-5.6.3.tgz

# Crear enlace simbólico
sudo ln -s /opt/apache-jmeter-5.6.3/bin/jmeter /usr/local/bin/jmeter
sudo ln -s /opt/apache-jmeter-5.6.3/bin/jmeter.sh /usr/local/bin/jmeter.sh

# Verificar
jmeter --version
```

### 3.3. Alternativa: Ejecutar JMeter desde OTRO equipo

Es **más recomendable** ejecutar JMeter desde un segundo equipo (PC con Windows/Linux)
para que la carga de JMeter no afecte al servidor Moodle.

En el segundo equipo:
1. Instalar Java
2. Descargar JMeter desde https://jmeter.apache.org/download_jmeter.cgi
3. Conectarse a la misma red local del router del aula
4. Apuntar las pruebas a `http://moodle.local`

---

## Fase 4: Generar el plan de prueba

### 4.1. Generar el plan JMeter para 60 usuarios

El tamaño **M** genera un plan para 100 usuarios con 5 bucles.
Para 60 usuarios, se puede generar tamaño M y luego ajustar.

```bash
sudo -u www-data php8.4 /var/www/moodle/public/admin/tool/generator/cli/maketestplan.php \
  --shortname=LOADTEST_60 \
  --size=M \
  --bypasscheck
```

Esto genera dos archivos en `/var/moodledata/`:
- `testplan.jmx` — El plan de prueba para JMeter
- `users.csv` — Las credenciales de los usuarios de prueba

### 4.2. Copiar los archivos generados

```bash
# Verificar que se crearon
ls -la /var/moodledata/testplan.jmx /var/moodledata/users.csv 2>/dev/null

# Copiar a un directorio accesible
mkdir -p ~/testing-moodle
sudo cp /var/moodledata/testplan.jmx ~/testing-moodle/
sudo cp /var/moodledata/users.csv ~/testing-moodle/
sudo chown $USER:$USER ~/testing-moodle/*
```

### 4.3. Ajustar a 60 usuarios (opcional)

Si el plan generó 100 usuarios y quieres probar con 60:

```bash
# Editar el .jmx y cambiar el número de threads (usuarios)
# Buscar la línea: <stringProp name="ThreadGroup.num_threads">100</stringProp>
# Cambiar 100 por 60
sed -i 's/ThreadGroup.num_threads">100/ThreadGroup.num_threads">60/' ~/testing-moodle/testplan.jmx

# Verificar el cambio
grep "num_threads" ~/testing-moodle/testplan.jmx
```

También recortar `users.csv` a 60 líneas (más la cabecera):
```bash
head -61 ~/testing-moodle/users.csv > ~/testing-moodle/users_60.csv
mv ~/testing-moodle/users_60.csv ~/testing-moodle/users.csv
wc -l ~/testing-moodle/users.csv
# Debe mostrar 61 (1 cabecera + 60 usuarios)
```

---

## Fase 5: Ejecutar la prueba de carga

### 5.1. Modo línea de comandos (sin GUI, recomendado)

```bash
cd ~/testing-moodle

# Ejecutar el plan de prueba
jmeter -n \
  -t testplan.jmx \
  -l resultados.jtl \
  -e -o reporte/ \
  -Jhost=moodle.local \
  -Jusers=60 \
  -Jrampup=30
```

Parámetros:
| Parámetro | Significado |
|-----------|-------------|
| `-n` | Modo no-GUI (línea de comandos) |
| `-t testplan.jmx` | Archivo del plan de prueba |
| `-l resultados.jtl` | Archivo donde se guardan los resultados |
| `-e -o reporte/` | Genera reporte HTML en la carpeta `reporte/` |
| `-Jhost=moodle.local` | Host del servidor Moodle |
| `-Jusers=60` | Número de usuarios simultáneos |
| `-Jrampup=30` | Periodo de arranque en segundos (1 usuario cada 0.5s) |

### 5.2. Modo GUI (visual, para ajustar)

```bash
jmeter -t ~/testing-moodle/testplan.jmx
```

Esto abre la interfaz gráfica donde puedes ver en tiempo real:
- Tiempos de respuesta
- Errores
- Gráficos de rendimiento

### 5.3. Ver el reporte HTML generado

Después de ejecutar en modo CLI:
```bash
# Abrir el reporte en el navegador
xdg-open ~/testing-moodle/reporte/index.html
```

---

## Fase 6: Monitorear durante la prueba

Mientras JMeter ejecuta la prueba, abrir terminales adicionales para monitorear:

### Terminal 1: Recursos del sistema
```bash
htop
```
Observar:
- **CPU**: No debe estar al 100% sostenido
- **RAM**: Debe quedar memoria libre (no entrar en swap)
- **Load average**: No debe superar 4.0 (2 cores × 2)

### Terminal 2: PHP-FPM
```bash
# Estado de procesos PHP
sudo watch -n 2 'ps aux | grep php-fpm | grep -v grep | wc -l'
```
Si los procesos PHP llegan a 50 (max_children), el servidor está al límite.

### Terminal 3: MariaDB
```bash
sudo mariadb -e "SHOW STATUS LIKE 'Threads_connected';"
# Repetir cada pocos segundos, o usar:
sudo watch -n 2 "mariadb -e \"SHOW STATUS LIKE 'Threads_connected';\""
```

### Terminal 4: Redis
```bash
redis-cli monitor
# Muestra en tiempo real todas las operaciones de caché
# Ctrl+C para parar (genera mucha salida)

# Alternativa más ligera: estadísticas
redis-cli info stats | grep -E "instantaneous|connected|keyspace"
```

### Terminal 5: Nginx
```bash
sudo tail -f /var/log/nginx/moodle_access.log | cut -d'"' -f3 | cut -d' ' -f2
# Muestra los códigos de respuesta HTTP en tiempo real (200, 302, 500, etc.)
```

---

## Fase 7: Interpretar resultados

### 7.1. Métricas clave

| Métrica | Aceptable | Problemático |
|---------|-----------|--------------|
| **Tiempo de respuesta promedio** | < 2 segundos | > 5 segundos |
| **Tiempo de respuesta p95** | < 5 segundos | > 10 segundos |
| **Tasa de error** | < 1% | > 5% |
| **Throughput** | > 10 req/s | < 5 req/s |
| **CPU servidor** | < 80% | 100% sostenido |
| **RAM libre** | > 500 MB | Usando swap |

### 7.2. Leer resultados desde la terminal

```bash
# Resumen rápido de resultados
cd ~/testing-moodle

# Contar peticiones exitosas vs fallidas
grep -c ",200," resultados.jtl   # HTTP 200 OK
grep -c ",500," resultados.jtl   # HTTP 500 Error

# Tiempo promedio de respuesta (columna elapsed, en ms)
awk -F',' 'NR>1 {sum+=$2; n++} END {print "Promedio: " sum/n " ms"}' resultados.jtl
```

### 7.3. Qué hacer si los resultados son malos

| Problema | Causa probable | Solución |
|----------|---------------|----------|
| Tiempos > 5s | PHP-FPM saturado | Aumentar `pm.max_children` en pool |
| Errores 502/504 | PHP-FPM sin workers | Aumentar `pm.max_children` y `pm.max_spare_servers` |
| RAM agotada | Demasiados procesos PHP | Reducir `pm.max_children`, reducir `memory_limit` |
| CPU al 100% | Celeron al límite | Reducir JIT buffer, reducir concurrencia |
| Errores de BD | MariaDB sin conexiones | Aumentar `max_connections` |

Archivos de configuración relevantes:
```
PHP-FPM pool:    /etc/php/8.4/fpm/pool.d/www.conf
PHP config:      /etc/php/8.4/fpm/php.ini
MariaDB:         /etc/mysql/mariadb.conf.d/50-server.cnf
Nginx:           /etc/nginx/sites-available/moodle
```

---

## Fase 8: Limpieza

### 8.1. Eliminar datos de prueba

**Opción A** — Restaurar snapshot (más limpio):
```bash
sudo timeshift --restore
# Seleccionar el snapshot creado en Fase 1
```

**Opción B** — Eliminar manualmente:
```bash
# Eliminar el curso de prueba desde CLI
sudo -u www-data php8.4 /var/www/moodle/public/admin/cli/delete_course.php \
  --shortname=LOADTEST_60 \
  --non-interactive

# Purgar cachés
sudo -u www-data php8.4 /var/www/moodle/public/admin/cli/purge_caches.php

# Eliminar archivos de JMeter
rm -rf ~/testing-moodle/
```

### 8.2. Restaurar configuración de producción

Quitar las líneas temporales de `/var/www/moodle/config.php`:
```bash
sudo nano /var/www/moodle/config.php
```

**Eliminar** estas líneas (si las añadiste):
```php
$CFG->debug = (E_ALL | E_STRICT);       // ELIMINAR
$CFG->debugdisplay = 1;                 // ELIMINAR
$CFG->tool_generator_users_password = 'moodle';  // ELIMINAR
```

**Verificar** que queden los valores de producción:
```php
$CFG->debug = 0;
$CFG->debugdisplay = 0;
```

Reiniciar servicios:
```bash
sudo systemctl restart php8.4-fpm
```

---

## Prueba rápida sin JMeter

Si no quieres instalar Java + JMeter, puedes hacer una prueba básica con
herramientas ya disponibles en el sistema.

### Opción 1: Apache Bench (ab)

```bash
sudo apt install -y apache2-utils

# Simular 60 conexiones simultáneas, 300 peticiones totales
ab -n 300 -c 60 -k http://moodle.local/

# Con login (más realista): primero obtener la cookie
ab -n 300 -c 60 -k \
  -H "Cookie: MoodleSession=TU_SESSION_ID" \
  http://moodle.local/my/
```

Interpretar:
- **Requests per second**: Debe ser > 10
- **Time per request**: Debe ser < 2000 ms
- **Failed requests**: Debe ser 0

### Opción 2: curl en paralelo

```bash
# Crear script de prueba básica
cat > /tmp/test_moodle.sh << 'TESTSCRIPT'
#!/bin/bash
# Prueba básica: 60 peticiones simultáneas a la página principal
echo "Iniciando 60 peticiones simultáneas..."
START=$(date +%s%N)

for i in $(seq 1 60); do
  curl -s -o /dev/null -w "%{http_code} %{time_total}s\n" http://moodle.local/ &
done
wait

END=$(date +%s%N)
ELAPSED=$(( (END - START) / 1000000 ))
echo "---"
echo "60 peticiones completadas en ${ELAPSED}ms"
TESTSCRIPT

chmod +x /tmp/test_moodle.sh
bash /tmp/test_moodle.sh
```

### Opción 3: Prueba manual con tablets reales

La prueba más confiable para tu caso de uso:

1. Pedir prestadas 10-15 tablets
2. Abrir `http://moodle.local` en todas simultáneamente
3. Hacer login con diferentes usuarios
4. Iniciar un cuestionario en todas al mismo tiempo
5. Monitorear con `htop` en el servidor

Si 15 tablets funcionan sin problema, 60 también funcionarán (el cuello de
botella suele ser la red WiFi, no el servidor).

---

## Referencia de tamaños

### Generador de cursos (`maketestcourse.php`)

| Tamaño | Secciones | Actividades | Usuarios |
|--------|-----------|-------------|----------|
| XS | Mínimo | Pocas | ~10 |
| S | Pequeño | Moderadas | ~30 |
| **M** | Mediano | Muchas | **~100** |
| L | Grande | Muchas | ~1,000 |
| XL | Muy grande | Masivas | ~5,000 |
| XXL | Extremo | Extremas | ~10,000 |

### Generador de plan JMeter (`maketestplan.php`)

| Tamaño | Usuarios simultáneos | Bucles | Ramp-up (seg) |
|--------|---------------------|--------|---------------|
| XS | 1 | 5 | 1 |
| S | 30 | 5 | 6 |
| **M** | **100** | **5** | **40** |
| L | 1,000 | 6 | 100 |
| XL | 5,000 | 6 | 500 |
| XXL | 10,000 | 7 | 800 |

### Generador de sitio (`maketestsite.php`)

| Tamaño | Datos | Cursos | Tiempo aprox. |
|--------|-------|--------|---------------|
| XS | ~10 MB | 3 | ~30 seg |
| S | ~50 MB | 8 | ~2 min |
| M | ~200 MB | 73 | ~10 min |
| L | ~1.5 GB | 277 | ~1.5 horas |
| XL | ~10 GB | 1,065 | ~5 horas |
| XXL | ~20 GB | 4,177 | ~10 horas |

---

**Fuentes**:
- [Test course generator - MoodleDocs](https://docs.moodle.org/405/en/Test_course_generator)
- [Load testing Moodle with JMeter - MoodleDocs](https://docs.moodle.org/dev/Load_testing_Moodle_with_JMeter)
- [Performance and scalability - MoodleDocs](https://docs.moodle.org/dev/Performance_and_scalability)
- [moodle-performance-comparison (GitHub)](https://github.com/moodlehq/moodle-performance-comparison)
