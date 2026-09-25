#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GMA="$ROOT/dist/the_legend_of_deborah.gma"
WORKSHOP_ID="3791535712"
CHANGES="${1:-Alpha playtest build update}"

source "$ROOT/tools/workshop/workshop_tools.sh"
# Resolve publisher before building a package that cannot be uploaded here.
GMPUBLISH_BIN="$(lod_workshop_find_tool GMPUBLISH gmpublish)"
bash "$ROOT/tools/workshop/build_workshop.sh"

echo "Updating Garry's Mod Workshop item $WORKSHOP_ID..."
echo "Steam must be running and logged into the account that owns the item."
lod_workshop_run_tool "$GMPUBLISH_BIN" update \
    -addon "$GMA" \
    -id "$WORKSHOP_ID" \
    -changes "$CHANGES"

echo
echo "Workshop update complete: https://steamcommunity.com/sharedfiles/filedetails/?id=$WORKSHOP_ID"
