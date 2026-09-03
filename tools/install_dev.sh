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
RPG_DATA_DIR="$GMOD_DIR/data/legend_of_deborah"
RPG_ARCHIVE_LINK="$REPO_DIR/rpg_archive_latest.log"
RPG_SESSION_LINK="$REPO_DIR/rpg_session_latest.log"
RPG_SUMMARY_LINK="$REPO_DIR/rpg_summary_latest.log"
mkdir -p "$ADDONS_DIR" "$RPG_DATA_DIR"

if [[ -e "$TARGET" && ! -L "$TARGET" ]]; then
  echo "Refusing to replace existing non-symlink: $TARGET" >&2
  exit 1
fi

ln -sfn "$REPO_DIR" "$TARGET"
# -condebug writes Garry's Mod's exact engine/client console stream here. Keep a
# stable ignored path inside the checkout so a playtester can upload one obvious
# file instead of navigating Steam's install tree. A dangling link before the
# first -condebug launch is intentional and becomes live once GMod writes it.
ln -sfn "$CONSOLE_LOG" "$CONSOLE_LINK"
# The RPG files live under garrysmod/data. Stable ignored links keep the entire
# test evidence package together in the checkout without copying or committing it.
ln -sfn "$RPG_DATA_DIR/rpg_test_log.txt" "$RPG_ARCHIVE_LINK"
ln -sfn "$RPG_DATA_DIR/rpg_test_session.txt" "$RPG_SESSION_LINK"
ln -sfn "$RPG_DATA_DIR/rpg_test_summary.txt" "$RPG_SUMMARY_LINK"

echo "The Legend of Deborah development checkout is mounted at:"
echo "  $TARGET -> $REPO_DIR"
echo
echo "Full console capture (one-time Steam launch-option setup):"
echo "  -condebug -conclearlog"
echo "This captures the exact console stream and clears the previous log every GMod start."
echo
echo "Primary test evidence links:"
echo "  $CONSOLE_LINK"
echo "  $RPG_SUMMARY_LINK"
echo "Detailed current-session stream when requested:"
echo "  $RPG_SESSION_LINK"
echo "Bounded rolling RPG archive (normally keep local unless requested):"
echo "  $RPG_ARCHIVE_LINK"
echo
echo "At the end of a runtime test run this in the Garry's Mod console:"
echo "  lod_rpg_test_finish <short-test-label>"
echo "Then upload console_latest.log + rpg_summary_latest.log by default."
echo
echo "Launch Garry's Mod with gm_flatgrass and gamemode legend_of_deborah."
echo "For the legacy M1 audit you can still run:"
echo "  lod_m1_audit"
