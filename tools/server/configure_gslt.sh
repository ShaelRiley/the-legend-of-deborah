#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="${LOD_SERVER_CONFIG_DIR:-$HOME/.config/legend_of_deborah}"
TOKEN_FILE="$CONFIG_DIR/gslt.token"

mkdir -p "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"

printf 'Paste the Garry\x27s Mod GSLT (input hidden): '
IFS= read -r -s GSLT
printf '\n'

if [[ -z "$GSLT" ]]; then
    echo "No token entered; nothing was saved." >&2
    exit 1
fi

printf '%s' "$GSLT" > "$TOKEN_FILE"
chmod 600 "$TOKEN_FILE"
unset GSLT

echo "GSLT saved privately at: $TOKEN_FILE"
echo "Next: bash tools/server/run_public_server.sh"
