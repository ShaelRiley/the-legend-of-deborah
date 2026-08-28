#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORKSHOP_ID="3791535712"
ICON_SOURCE="$ROOT/gamemodes/legend_of_deborah/content/html/legend_of_deborah_loading.jpg"
GENERATED_ICON="$ROOT/.build/workshop/workshop_icon.jpg"

if [[ ! -f "$ICON_SOURCE" ]]; then
    echo "Workshop artwork not found: $ICON_SOURCE" >&2
    exit 2
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "ffmpeg is required to generate the Workshop icon." >&2
    exit 2
fi

mkdir -p "$(dirname "$GENERATED_ICON")"

# Steam requires a square 512x512 baseline-style JPEG with 4:2:0 chroma.
# Preserve the complete source artwork rather than center-cropping it.
ffmpeg -hide_banner -loglevel error -y \
    -i "$ICON_SOURCE" \
    -vf "scale=512:512:force_original_aspect_ratio=decrease,pad=512:512:(ow-iw)/2:(oh-ih)/2:black" \
    -frames:v 1 -q:v 2 -pix_fmt yuvj420p \
    "$GENERATED_ICON"

echo "Generated fitted Workshop icon: $GENERATED_ICON"

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

echo "Updating Workshop icon for item $WORKSHOP_ID..."
(
    cd "$BIN_DIR"
    "./$(basename "$GMPUBLISH_BIN")" update \
        -icon "$GENERATED_ICON" \
        -id "$WORKSHOP_ID"
)

echo "Workshop icon updated. Refresh the item page after Steam finishes processing it."
