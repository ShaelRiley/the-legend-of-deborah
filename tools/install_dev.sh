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
RPG_DATA_DIR="$GMOD_DIR/data/legend_of_deborah"

mkdir -p "$ADDONS_DIR" "$RPG_DATA_DIR"

if [[ -e "$TARGET" && ! -L "$TARGET" ]]; then
  echo "Refusing to replace existing non-symlink: $TARGET" >&2
  exit 1
fi

ln -sfn "$REPO_DIR" "$TARGET"

# Older builds exposed upload-facing *.log symlinks in the checkout. They are no
# longer the supported upload path because some Steam Deck file pickers reject
# symlinked files. Remove only those legacy symlinks; never delete real files.
for legacy_link in \
  "$REPO_DIR/console_latest.log" \
  "$REPO_DIR/rpg_summary_latest.log" \
  "$REPO_DIR/rpg_session_latest.log" \
  "$REPO_DIR/rpg_archive_latest.log"
do
  if [[ -L "$legacy_link" ]]; then
    rm -f "$legacy_link"
  fi
done

echo "The Legend of Deborah development checkout is mounted at:"
echo "  $TARGET -> $REPO_DIR"
echo
echo "Full console capture requires these one-time Steam launch options:"
echo "  -condebug -conclearlog"
echo
echo "Upload-facing evidence is now written as ordinary .txt files under:"
echo "  $RPG_DATA_DIR/"
echo
echo "Default files to upload after a runtime test:"
echo "  $RPG_DATA_DIR/console_latest.txt"
echo "  $RPG_DATA_DIR/rpg_summary_latest.txt"
echo
echo "When detailed timing/event order is needed:"
echo "  $RPG_DATA_DIR/rpg_session_latest.txt"
echo "Rolling cross-session archive (only when requested):"
echo "  $RPG_DATA_DIR/rpg_archive_latest.txt"
echo
echo "At the end of a runtime test run:"
echo "  lod_rpg_test_finish <short-test-label>"
echo "The upload copies refresh automatically when the summary is written."
echo "Use lod_rpg_test_upload_status to verify the physical upload files."
echo
echo "Launch Garry's Mod with gm_flatgrass and gamemode legend_of_deborah."
echo "For the legacy M1 audit you can still run:"
echo "  lod_m1_audit"
