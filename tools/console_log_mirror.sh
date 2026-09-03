#!/usr/bin/env bash
set -u

SOURCE_LOG="${1:-}"
DEST_LOG="${2:-}"

if [[ -z "$SOURCE_LOG" || -z "$DEST_LOG" ]]; then
  echo "usage: console_log_mirror.sh <garrysmod-console.log> <data-destination>" >&2
  exit 2
fi

mkdir -p "$(dirname "$DEST_LOG")"
last_signature=""

while true; do
  if [[ -f "$SOURCE_LOG" ]]; then
    signature="$(stat -c '%i:%s:%y' "$SOURCE_LOG" 2>/dev/null || true)"
    if [[ -n "$signature" ]] && { [[ "$signature" != "$last_signature" ]] || ! cmp -s -- "$SOURCE_LOG" "$DEST_LOG" 2>/dev/null; }; then
      tmp="${DEST_LOG}.tmp.$$"
      if cp -- "$SOURCE_LOG" "$tmp" 2>/dev/null; then
        mv -f -- "$tmp" "$DEST_LOG"
        last_signature="$signature"
      else
        rm -f -- "$tmp"
      fi
    fi
  fi
  sleep 0.5
done
