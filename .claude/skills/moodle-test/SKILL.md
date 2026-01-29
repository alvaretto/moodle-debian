---
name: moodle-test
description: Ejecutar pruebas de carga y rendimiento del servidor Moodle. Usar cuando el usuario quiera verificar capacidad para N estudiantes o hacer benchmarks.
user-invocable: true
allowed-tools: Bash, Read
argument-hint: [quick|full|N-students]
---

# Skill: Testing de Rendimiento de Moodle

Ejecuta pruebas de carga para validar la capacidad del servidor.

## Argumentos

- `quick`: Test rápido con curl (sin JMeter)
- `full`: Test completo con JMeter (requiere instalación previa)
- `N-students`: Simular N estudiantes (ej: `60` para 60 estudiantes)
- Sin argumento: Test rápido por defecto

## Prerrequisitos

Antes de hacer tests de carga:
1. Crear snapshot de Timeshift
2. Verificar que no hay clases en curso
3. Tener acceso al servidor

## Test rápido (`quick`)

```bash
echo "=== Test de conectividad básica ==="
for i in 1 2 3 4 5; do
  curl -s -o /dev/null -w "Request $i - TTFB: %{time_starttransfer}s  Total: %{time_total}s\n" http://localhost/
done

echo ""
echo "=== Test con Apache Benchmark (10 requests, 5 concurrent) ==="
ab -n 10 -c 5 http://localhost/ 2>/dev/null | grep -E "Requests per second|Time per request|Failed" || echo "ab no instalado (apt install apache2-utils)"
```

## Test de N estudiantes

```bash
# Generar curso de prueba si no existe
echo "Verificando curso de prueba..."
COURSE_EXISTS=$(sudo -u www-data php /var/www/moodle/admin/cli/cfg.php --name=testcourse 2>/dev/null || echo "no")

if [ "$COURSE_EXISTS" = "no" ]; then
  echo "Generando curso de prueba para $ARGUMENTS estudiantes..."
  sudo -u www-data php8.4 /var/www/moodle/admin/tool/generator/cli/maketestcourse.php \
    --shortname=LOADTEST_$ARGUMENTS \
    --size=M \
    --bypasscheck
fi
```

## Test completo con JMeter (`full`)

Consultar `testing-moodle.md` para:
1. Configuración de JMeter
2. Plan de pruebas para 60 estudiantes
3. Métricas a monitorear
4. Interpretación de resultados

```bash
# Verificar si JMeter está instalado
which jmeter 2>/dev/null || echo "JMeter no instalado. Ver testing-moodle.md para instrucciones"
```

## Monitoreo durante el test

Ejecutar en terminal separada:
```bash
watch -n 1 'echo "=== RAM ===" && free -h && echo "" && echo "=== PHP-FPM ===" && ps aux | grep php-fpm | wc -l && echo "" && echo "=== MySQL ===" && mysqladmin status 2>/dev/null'
```

## Métricas objetivo (12GB RAM, 60 estudiantes)

| Métrica | Objetivo | Crítico |
|---------|----------|---------|
| TTFB | < 500ms | > 2s |
| Requests/sec | > 50 | < 20 |
| RAM usada | < 80% | > 95% |
| PHP-FPM workers | < 30 | > 45 |
| Error rate | 0% | > 1% |

## Documento de referencia

Ver `testing-moodle.md` para guía completa de testing incluyendo:
- Generación de datos de prueba
- Configuración de JMeter
- Scripts de monitoreo en tiempo real
- Análisis de resultados
