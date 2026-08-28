#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STAGE="$ROOT/.build/workshop/the_legend_of_deborah"
DIST="$ROOT/dist"
OUT="$DIST/the_legend_of_deborah.gma"

find_tool() {
    local env_name="$1"
    shift
    local override="${!env_name:-}"
    if [[ -n "$override" && -x "$override" ]]; then
        printf '%s\n' "$override"
        return 0
    fi

    local candidate
    for candidate in "$@"; do
        if [[ -x "$candidate" ]]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

STEAM_A="$HOME/.local/share/Steam/steamapps/common/GarrysMod"
STEAM_B="$HOME/.steam/steam/steamapps/common/GarrysMod"
GMAD_BIN="$(find_tool GMAD \
    "$STEAM_A/bin/linux64/gmad" \
    "$STEAM_A/bin/linux64/gmad_linux" \
    "$STEAM_A/bin/gmad_linux" \
    "$STEAM_B/bin/linux64/gmad" \
    "$STEAM_B/bin/linux64/gmad_linux" \
    "$STEAM_B/bin/gmad_linux")" || {
        echo "Could not find Garry's Mod gmad. Set GMAD=/full/path/to/gmad or gmad_linux and retry." >&2
        exit 1
    }

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
GMAD_DIR="$(dirname "$GMAD_BIN")"
(
    cd "$GMAD_DIR"
    "./$(basename "$GMAD_BIN")" create -folder "$STAGE" -out "$OUT"
)

echo "Workshop package built: $OUT"
