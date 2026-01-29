#!/usr/bin/env python3
"""
Hook: Validar ediciones de archivos
Bloquea ediciones a archivos sensibles o protegidos.
"""
import json
import sys

def main():
    try:
        data = json.load(sys.stdin)
        file_path = data.get('tool_input', {}).get('file_path', '')

        # Archivos bloqueados
        blocked_patterns = [
            'datos-sensibles',
            '.local.json',
            '.env',
            'credentials',
            'password',
            'secret'
        ]

        for pattern in blocked_patterns:
            if pattern.lower() in file_path.lower():
                print(json.dumps({
                    "decision": "block",
                    "reason": f"Archivo protegido: contiene '{pattern}'"
                }))
                sys.exit(2)

        # Archivos que requieren confirmación
        warn_patterns = [
            'config.php',
            '/etc/',
            '.gitignore',
            'CLAUDE.md'
        ]

        for pattern in warn_patterns:
            if pattern in file_path:
                print(f"⚠️  Editando archivo importante: {file_path}", file=sys.stderr)
                break

        sys.exit(0)

    except Exception as e:
        print(f"Error en hook: {e}", file=sys.stderr)
        sys.exit(0)  # No bloquear en caso de error

if __name__ == '__main__':
    main()
