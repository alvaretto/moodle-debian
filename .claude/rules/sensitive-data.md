# Reglas para datos sensibles

## Archivos protegidos

El directorio `datos-sensibles/` contiene información de estudiantes y NO debe ser accedido ni modificado por Claude.

### Contenido protegido
- Listados de estudiantes (CSV, XLS)
- Credenciales de acceso
- Información personal identificable (PII)

### Reglas estrictas
1. NUNCA leer archivos en `datos-sensibles/`
2. NUNCA incluir nombres de estudiantes en documentación
3. NUNCA incluir contraseñas reales en ejemplos
4. NUNCA commitear archivos sensibles

### Ejemplos seguros para documentación
```
# Usar datos genéricos
usuario: estudiante01
password: [contraseña-segura]
email: estudiante@ejemplo.com
```

### Si el usuario solicita acceso
Rechazar cortésmente y explicar que los datos sensibles están protegidos por política del proyecto.
