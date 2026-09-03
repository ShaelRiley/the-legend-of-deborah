#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -n "${GMOD_GARRYSMOD_DIR:-}" ]]; then
  CANDIDATES=("$GMOD_GARRYSMOD_DIR")
else
  CANDIDATES=(
    "$HOME/.local/share/Steam/steamapps/common/GarrysMod/garrysmod"
    "$HOME/.steam/steam/steamapps/common/GarrysMod/garrysmod"
    "$HOME/.steam/root/steamapps/common/GarrysMod/garrysmod"
  )
fi

GMOD_DIR=""
for candidate in "${CANDIDATES[@]}"; do
  if [[ -d "$candidate" ]]; then
    GMOD_DIR="$candidate"
    break
  fi
done

if [[ -z "$GMOD_DIR" ]]; then
  echo "Could not find Garry's Mod's garrysmod directory." >&2
  echo "Set GMOD_GARRYSMOD_DIR=/path/to/GarrysMod/garrysmod and rerun this script." >&2
  exit 1
fi

ADDONS_DIR="$GMOD_DIR/addons"
TARGET="$ADDONS_DIR/the-legend-of-deborah-dev"
CONSOLE_LOG="$GMOD_DIR/console.log"
CONSOLE_LINK="$REPO_DIR/console_latest.log"
mkdir -p "$ADDONS_DIR"

if [[ -e "$TARGET" && ! -L "$TARGET" ]]; then
  echo "Refusing to replace existing non-symlink: $TARGET" >&2
  exit 1
fi

ln -sfn "$REPO_DIR" "$TARGET"
# -condebug writes Garry's Mod's exact engine/client console stream here.  Keep a
# stable, ignored path inside the checkout so playtesters can upload one obvious
# file instead of navigating Steam's install tree.  A dangling link before the
# first -condebug launch is intentional and becomes live as soon as GMod writes it.
ln -sfn "$CONSOLE_LOG" "$CONSOLE_LINK"

echo "The Legend of Deborah development checkout is mounted at:"
echo "  $TARGET -> $REPO_DIR"
echo
echo "Full console capture (one-time Steam launch-option setup):"
echo "  -condebug -conclearlog"
echo "This writes the exact console stream and clears the previous log every GMod start."
echo "Upload this stable convenience path after a test:"
echo "  $CONSOLE_LINK"
echo "Engine source:"
echo "  $CONSOLE_LOG"
echo
echo "The structured RPG instrumentation log remains separate under:"
echo "  $GMOD_DIR/data/legend_of_deborah/rpg_test_log.txt"
echo
echo "Launch Garry's Mod with gm_flatgrass and gamemode legend_of_deborah."
echo "Then run this in the Garry's Mod developer console:"
echo "  lod_m1_audit"
echo
echo "The full report will be written under:"
echo "  $GMOD_DIR/data/legend_of_deborah/"
