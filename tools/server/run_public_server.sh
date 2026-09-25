#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SERVER_ROOT="${LOD_SERVER_ROOT:-$HOME/Servers/the-legend-of-deborah}"
CONFIG_DIR="${LOD_SERVER_CONFIG_DIR:-$HOME/.config/legend_of_deborah}"
TOKEN_FILE="$CONFIG_DIR/gslt.token"
ADDON_DIR="$SERVER_ROOT/garrysmod/addons/the_legend_of_deborah"
SERVER_CFG="$SERVER_ROOT/garrysmod/cfg/lod_public_server.cfg"

if [[ ! -x "$SERVER_ROOT/srcds_run" ]]; then
    echo "Dedicated server is not installed at: $SERVER_ROOT" >&2
    echo "Run: bash tools/server/install_dedicated_server.sh" >&2
    exit 1
fi

if [[ ! -s "$TOKEN_FILE" ]]; then
    echo "GSLT not configured at: $TOKEN_FILE" >&2
    echo "Run: bash tools/server/configure_gslt.sh" >&2
    exit 1
fi

GSLT="$(cat "$TOKEN_FILE")"
if [[ -z "$GSLT" ]]; then
    echo "GSLT token file is empty." >&2
    exit 1
fi

# Deploy the same mounted roots used by the Workshop package. Keeping the
# dedicated server copy generated from main prevents a second implementation
# authority from drifting away from the repository.
DEPLOY_DIR="$SERVER_ROOT/.lod-deploy"
mkdir -p "$DEPLOY_DIR" "$(dirname "$ADDON_DIR")"
STAGED_ADDON="$(mktemp -d "$DEPLOY_DIR/stage.XXXXXX")"
trap 'rm -rf -- "$STAGED_ADDON"' EXIT
cp -a "$ROOT/gamemodes" "$STAGED_ADDON/"
cp -a "$ROOT/lua" "$STAGED_ADDON/"

# The development-only custom loading page cannot ship through Workshop and is
# unnecessary on the dedicated server. Keep server deployment aligned with the GMA.
rm -rf "$STAGED_ADDON/gamemodes/legend_of_deborah/content/html"
BUILD_COMMIT="$(git -C "$ROOT" rev-parse HEAD)"
BUILD_STATE=clean
if [[ -n "$(git -C "$ROOT" status --porcelain --untracked-files=normal)" ]]; then
    BUILD_STATE=modified
fi
printf '%s %s\n' "$BUILD_COMMIT" "$BUILD_STATE" > "$STAGED_ADDON/lod-build.txt"

# Stage completely before replacing the mounted addon. Keep rollback bytes OUTSIDE
# addons so GMod never mounts two copies. A failed copy leaves the old build intact.
if [[ -e "$ADDON_DIR" ]]; then
    rm -rf -- "$DEPLOY_DIR/previous"
    mv -- "$ADDON_DIR" "$DEPLOY_DIR/previous"
fi
if ! mv -- "$STAGED_ADDON" "$ADDON_DIR"; then
    if [[ -e "$DEPLOY_DIR/previous" ]]; then
        mv -- "$DEPLOY_DIR/previous" "$ADDON_DIR"
    fi
    exit 1
fi
trap - EXIT

mkdir -p "$SERVER_ROOT/garrysmod/data/legend_of_deborah"
cp "$ADDON_DIR/lod-build.txt" "$SERVER_ROOT/garrysmod/data/legend_of_deborah/dev_build.txt"

mkdir -p "$(dirname "$SERVER_CFG")"
# This file is operator-owned after first creation. A restart must not silently
# replace live configuration; release preflight checks the public listing values.
if [[ ! -e "$SERVER_CFG" ]]; then
cat > "$SERVER_CFG" <<'EOF'
hostname "The Legend of Deborah"
sv_lan 0
hide_server 0
sv_location us
sv_region -1
sv_password ""

# Keep Steam master-server advertisement on the game/query socket that UFW
# exposes publicly, and report an unambiguous Deborah identity to the browser.
sv_master_share_game_socket 1
host_name_store 1
sv_gamename_override "The Legend of Deborah"

# Public alpha concurrency: 4 Heroes + up to 6 human Soldiers + 2 spectators.
# Keep Source/GMod server-query metadata explicit so the browser reports the
# real population instead of relying on engine privacy/disclosure defaults.
sv_visiblemaxplayers 12
host_info_show 2
host_players_show 2
host_rules_show 1

# Source normally heartbeats automatically; send one immediately as well so a
# freshly restarted public server is announced to the Steam master list promptly.
heartbeat
EOF
fi

printf '\nLaunching public LOD dedicated server\n'
printf '  root:      %s\n' "$SERVER_ROOT"
printf '  gamemode:  legend_of_deborah\n'
printf '  map:       gm_flatgrass\n'
printf '  players:   12 max (4 Heroes + 6 Soldiers + 2 spectators)\n'
printf '  port:      27015\n\n'
printf 'Keep this terminal open. Press Ctrl+C to stop the server.\n\n'

cd "$SERVER_ROOT"
exec ./srcds_run \
    -game garrysmod \
    -console \
    -port 27015 \
    +maxplayers 12 \
    +sv_lan 0 \
    +hide_server 0 \
    +sv_region -1 \
    +gamemode legend_of_deborah \
    +map gm_flatgrass \
    +exec lod_public_server.cfg \
    +sv_setsteamaccount "$GSLT"
