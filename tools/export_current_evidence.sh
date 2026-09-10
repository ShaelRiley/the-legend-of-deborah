#!/usr/bin/env bash
set -euo pipefail

MARKER="sol_deadeye_stable"
OPEN_DOLPHIN=0

usage() {
  cat <<'USAGE'
usage: tools/export_current_evidence.sh [--marker <text>] [--open]

Exports the current Garry's Mod evidence trio to ~/Downloads/LOD-current-evidence,
verifies the console mirror watcher, confirms console_latest.txt matches console.log,
and checks that the requested marker is present in current RPG evidence.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --marker)
      [[ $# -ge 2 ]] || { echo "ERROR: --marker requires a value" >&2; exit 2; }
      MARKER="$2"
      shift 2
      ;;
    --open)
      OPEN_DOLPHIN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

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
  echo "ERROR: could not find Garry's Mod garrysmod directory." >&2
  echo "Set GMOD_GARRYSMOD_DIR=/absolute/path/to/garrysmod and rerun." >&2
  exit 1
fi

DATA_DIR="$GMOD_DIR/data/legend_of_deborah"
CONSOLE_LOG="$GMOD_DIR/console.log"
CONSOLE_MIRROR="$DATA_DIR/console_latest.txt"
RPG_SUMMARY="$DATA_DIR/rpg_summary_latest.txt"
RPG_SESSION="$DATA_DIR/rpg_session_latest.txt"
MIRROR_PID_FILE="$DATA_DIR/.console_mirror.pid"
DEST_DIR="${LOD_EVIDENCE_EXPORT_DIR:-$HOME/Downloads/LOD-current-evidence}"
TEMP_DIR="${DEST_DIR}.tmp.$$"

SOURCES=("$CONSOLE_MIRROR" "$RPG_SUMMARY" "$RPG_SESSION")

for path in "$CONSOLE_LOG" "${SOURCES[@]}"; do
  if [[ ! -f "$path" ]]; then
    echo "ERROR: required evidence source is missing:" >&2
    echo "  $path" >&2
    exit 1
  fi
done

if [[ ! -f "$MIRROR_PID_FILE" ]]; then
  echo "ERROR: console mirror PID file is missing: $MIRROR_PID_FILE" >&2
  echo "Run ./tools/install_dev.sh once, then rerun this exporter." >&2
  exit 1
fi

mirror_pid="$(cat "$MIRROR_PID_FILE" 2>/dev/null || true)"
if [[ ! "$mirror_pid" =~ ^[0-9]+$ ]] || ! kill -0 "$mirror_pid" 2>/dev/null; then
  echo "ERROR: console mirror watcher is not alive (PID: ${mirror_pid:-unreadable})." >&2
  echo "Run ./tools/install_dev.sh once, then rerun this exporter." >&2
  exit 1
fi

mirror_args="$(ps -p "$mirror_pid" -o args= 2>/dev/null || true)"
if [[ "$mirror_args" != *"console_log_mirror.sh"* || "$mirror_args" != *"$CONSOLE_LOG"* || "$mirror_args" != *"$CONSOLE_MIRROR"* ]]; then
  echo "ERROR: PID $mirror_pid is alive but is not the expected console mirror watcher." >&2
  echo "Run ./tools/install_dev.sh once, then rerun this exporter." >&2
  exit 1
fi

# Allow one watcher interval plus margin before declaring the mirror stale.
if ! cmp -s -- "$CONSOLE_LOG" "$CONSOLE_MIRROR"; then
  sleep 0.8
fi
if ! cmp -s -- "$CONSOLE_LOG" "$CONSOLE_MIRROR"; then
  echo "ERROR: console_latest.txt is not tracking the current console.log." >&2
  echo "  engine: $CONSOLE_LOG" >&2
  echo "  mirror: $CONSOLE_MIRROR" >&2
  exit 1
fi

printf '[PASS] console mirror watcher alive: PID %s\n' "$mirror_pid"
printf '[PASS] console_latest.txt matches current console.log\n'
printf '\nCurrent source evidence:\n'
for path in "$CONSOLE_LOG" "${SOURCES[@]}"; do
  stat -c '  %n | %s bytes | modified %y' "$path"
done

printf '\nMarker check: %s\n' "$MARKER"
for path in "${SOURCES[@]}"; do
  if grep -Fq -- "$MARKER" "$path"; then
    printf '  [PASS] %s\n' "$path"
  else
    printf '  [MISS] %s\n' "$path"
  fi
done

# The RPG summary and detailed session are the authoritative marker-bearing
# telemetry. Requiring both prevents an old RPG package from being mistaken for
# the current run even when the engine console itself is fresh.
if ! grep -Fq -- "$MARKER" "$RPG_SUMMARY" || ! grep -Fq -- "$MARKER" "$RPG_SESSION"; then
  echo >&2
  echo "ERROR: requested marker is absent from current RPG summary/session evidence." >&2
  echo "Do not repeat gameplay. If the completed run only lacks finalization, run this GMod console line:" >&2
  echo "  lod_deadeye_aim_status; lod_deadeye_aim_validate; lod_rpg_test_mark $MARKER; lod_rpg_validate; lod_rpg_test_finish $MARKER; lod_rpg_test_upload_status" >&2
  exit 1
fi

rm -rf -- "$TEMP_DIR"
mkdir -p -- "$TEMP_DIR"
trap 'rm -rf -- "$TEMP_DIR"' EXIT
for path in "${SOURCES[@]}"; do
  cp -- "$path" "$TEMP_DIR/$(basename "$path")"
done

mkdir -p -- "$(dirname "$DEST_DIR")"
rm -rf -- "$DEST_DIR"
mv -- "$TEMP_DIR" "$DEST_DIR"
trap - EXIT

printf '\n[PASS] exported current evidence to:\n  %s\n' "$DEST_DIR"
printf '\nExported files:\n'
for path in "$DEST_DIR"/*.txt; do
  stat -c '  %n | %s bytes | modified %y' "$path"
done

printf '\nAcceptance signatures found in exported console:\n'
grep -F -- '[LOD:DEADEYE]' "$DEST_DIR/console_latest.txt" | tail -n 5 || true
grep -F -- 'RPG_VALIDATE result=PASS' "$DEST_DIR/console_latest.txt" | tail -n 5 || true

if [[ "$OPEN_DOLPHIN" -eq 1 ]]; then
  if command -v dolphin >/dev/null 2>&1; then
    nohup dolphin "$DEST_DIR" >/dev/null 2>&1 &
  else
    echo "WARNING: --open requested, but Dolphin is not installed or not on PATH." >&2
  fi
fi
