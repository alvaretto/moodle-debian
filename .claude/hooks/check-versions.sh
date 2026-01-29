#!/bin/bash
# Hook: Verificar versiones en documentación
# Se ejecuta después de editar archivos .md

# Leer input JSON
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null)

# Solo verificar archivos .md
if [[ ! "$FILE_PATH" =~ \.md$ ]]; then
    exit 0
fi

# Verificar versiones desactualizadas
WARNINGS=""

if grep -q "php8.3\|PHP 8.3" "$FILE_PATH" 2>/dev/null; then
    WARNINGS="$WARNINGS\n⚠️  Versión PHP desactualizada (8.3 → 8.4)"
fi

if grep -qE "Moodle (4\.[0-9]|MOODLE_4)" "$FILE_PATH" 2>/dev/null; then
    WARNINGS="$WARNINGS\n⚠️  Versión Moodle desactualizada (4.x → 5.1.1)"
fi

if grep -q "/var/www/html" "$FILE_PATH" 2>/dev/null; then
    WARNINGS="$WARNINGS\n⚠️  Ruta antigua (/var/www/html → /var/www/moodle)"
fi

if [ -n "$WARNINGS" ]; then
    echo -e "Verificación de versiones en $FILE_PATH:$WARNINGS"
fi

exit 0
