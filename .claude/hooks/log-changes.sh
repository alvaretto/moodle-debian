#!/bin/bash
# Hook: Registrar cambios en archivo de log
# Se ejecuta después de Write/Edit exitosos

LOG_FILE="$HOME/.claude/moodle-changes.log"
mkdir -p "$(dirname "$LOG_FILE")"

# Leer input JSON
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('tool_name',''))" 2>/dev/null)
FILE_PATH=$(echo "$INPUT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null)
SESSION_ID=$(echo "$INPUT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('session_id','')[:8])" 2>/dev/null)

# Registrar el cambio
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
echo "[$TIMESTAMP] [$SESSION_ID] $TOOL_NAME: $FILE_PATH" >> "$LOG_FILE"

# Mantener solo últimas 1000 líneas
tail -1000 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"

exit 0
