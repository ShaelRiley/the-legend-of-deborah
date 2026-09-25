#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STAGE="$ROOT/.build/workshop/the_legend_of_deborah"
DIST="$ROOT/dist"
OUT="$DIST/the_legend_of_deborah.gma"

source "$ROOT/tools/workshop/workshop_tools.sh"
GMAD_BIN="$(lod_workshop_find_tool GMAD gmad)"

rm -rf "$STAGE"
mkdir -p "$STAGE" "$DIST"

# Workshop package: mounted addon content only. Development docs/tools stay out.
cp -a "$ROOT/gamemodes" "$STAGE/"
cp -a "$ROOT/lua" "$STAGE/"
cp "$ROOT/tools/workshop/addon.json" "$STAGE/addon.json"

# Garry's Mod Workshop rejects HTML/CSS/JS. Keep the development loading page
# in source, but omit it from the Workshop GMA. The gamemode itself is unaffected.
rm -rf "$STAGE/gamemodes/legend_of_deborah/content/html"

rm -f "$OUT"
lod_workshop_run_tool "$GMAD_BIN" create -folder "$STAGE" -out "$OUT"

echo "Workshop package built: $OUT"
