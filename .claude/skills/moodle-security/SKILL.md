---
name: moodle-security
description: Auditar y mejorar la seguridad del servidor Moodle. Usar cuando el usuario quiera verificar configuración de seguridad, revisar logs de acceso, o endurecer el servidor.
user-invocable: true
allowed-tools: Bash, Read, WebSearch
argument-hint: [audit|firewall|ssl|logs|harden]
---

# Skill: Seguridad del Servidor Moodle

Gestiona la seguridad del servidor Moodle.

## Argumentos

- `audit`: Auditoría completa de seguridad
- `firewall`: Revisar configuración de ufw
- `ssl`: Verificar certificados y HTTPS
- `logs`: Analizar logs de acceso y errores
- `harden`: Sugerencias de endurecimiento
- Sin argumento: Auditoría rápida

## Auditoría de seguridad (`audit`)

```bash
echo "=== Firewall (ufw) ==="
sudo ufw status verbose

echo ""
echo "=== Puertos abiertos ==="
ss -tlnp | grep LISTEN

echo ""
echo "=== Fail2ban ==="
sudo systemctl is-active fail2ban && sudo fail2ban-client status || echo "fail2ban no activo"

echo ""
echo "=== Permisos de archivos críticos ==="
ls -la /var/www/moodle/config.php
ls -la /var/moodledata/
ls -la ~/backups/

echo ""
echo "=== Usuarios con shell ==="
grep -v '/nologin\|/false' /etc/passwd | grep -v '^#'

echo ""
echo "=== Últimos accesos SSH ==="
last -n 10 2>/dev/null || echo "No hay registros"
```

## Firewall (`firewall`)

Configuración recomendada para Moodle portable:

```bash
# Ver estado actual
sudo ufw status numbered

# Reglas recomendadas (ya deberían estar):
# - SSH (22): ALLOW (o puerto personalizado)
# - HTTP (80): ALLOW
# - HTTPS (443): ALLOW
# - mDNS (5353/udp): ALLOW
```

## Análisis de logs (`logs`)

```bash
echo "=== Errores recientes de Nginx ==="
sudo tail -50 /var/log/nginx/error.log | grep -i error | tail -20

echo ""
echo "=== Accesos sospechosos ==="
sudo grep -E "wp-login|admin\.php|phpmyadmin" /var/log/nginx/access.log 2>/dev/null | tail -10 || echo "No hay accesos sospechosos recientes"

echo ""
echo "=== Intentos de login fallidos (fail2ban) ==="
sudo grep "Ban" /var/log/fail2ban.log 2>/dev/null | tail -10 || echo "No hay bans recientes"

echo ""
echo "=== Errores de PHP ==="
sudo tail -20 /var/log/php8.4-fpm.log 2>/dev/null || echo "Log no encontrado"
```

## Endurecimiento (`harden`)

Verificar configuraciones de seguridad:

### Moodle
- Guest access: Deshabilitado
- Self-registration: Deshabilitado
- Password policy: Fuerte
- Session timeout: Configurado

### Nginx
- Server tokens: off
- X-Frame-Options: SAMEORIGIN
- X-Content-Type-Options: nosniff

### PHP
- expose_php: Off
- display_errors: Off (producción)
- allow_url_fopen: Off (si no se necesita)

### Sistema
- Actualizaciones de seguridad automáticas
- fail2ban activo
- Firewall configurado

## Documento de referencia

Consultar `moodle-install.md` sección "Seguridad" para:
- Configuración detallada de firewall
- Setup de fail2ban
- Certificados SSL/TLS
- Hardening de servicios

## Advertencias

- Este servidor es para uso OFFLINE en aula
- No exponer a Internet sin VPN o firewall perimetral
- Mantener backups antes de cambios de seguridad
- Documentar todos los cambios en moodle-install.md
