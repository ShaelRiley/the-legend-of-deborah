#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GMA="$ROOT/dist/the_legend_of_deborah.gma"
WORKSHOP_ID="3791535712"
CHANGES="${1:-Alpha playtest build update}"

bash "$ROOT/tools/workshop/build_workshop.sh"

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
GMPUBLISH_BIN="$(find_tool GMPUBLISH \
    "$STEAM_A/bin/linux64/gmpublish" \
    "$STEAM_A/bin/linux64/gmpublish_linux" \
    "$STEAM_A/bin/gmpublish_linux" \
    "$STEAM_B/bin/linux64/gmpublish" \
    "$STEAM_B/bin/linux64/gmpublish_linux" \
    "$STEAM_B/bin/gmpublish_linux")" || {
        echo "Could not find Garry's Mod gmpublish. Set GMPUBLISH=/full/path/to/gmpublish or gmpublish_linux and retry." >&2
        exit 1
    }

BIN_DIR="$(dirname "$GMPUBLISH_BIN")"
PARENT_DIR="$(dirname "$BIN_DIR")"
export LD_LIBRARY_PATH="$BIN_DIR:$PARENT_DIR:${LD_LIBRARY_PATH:-}"

echo "Updating Garry's Mod Workshop item $WORKSHOP_ID..."
echo "Steam must be running and logged into the account that owns the item."
(
    cd "$BIN_DIR"
    "./$(basename "$GMPUBLISH_BIN")" update \
        -addon "$GMA" \
        -id "$WORKSHOP_ID" \
        -changes "$CHANGES"
)

echo
echo "Workshop update complete: https://steamcommunity.com/sharedfiles/filedetails/?id=$WORKSHOP_ID"
