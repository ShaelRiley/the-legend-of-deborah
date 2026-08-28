#!/usr/bin/env bash
set -euo pipefail

SERVER_ROOT="${LOD_SERVER_ROOT:-$HOME/Servers/the-legend-of-deborah}"
STEAMCMD_ROOT="${LOD_STEAMCMD_ROOT:-$HOME/.local/share/legend_of_deborah/steamcmd}"
STEAMCMD_URL="https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"

find_steamcmd() {
    if command -v steamcmd >/dev/null 2>&1; then
        command -v steamcmd
        return 0
    fi
    if [[ -x "$STEAMCMD_ROOT/steamcmd.sh" ]]; then
        printf '%s\n' "$STEAMCMD_ROOT/steamcmd.sh"
        return 0
    fi
    return 1
}

STEAMCMD_BIN="$(find_steamcmd || true)"
if [[ -z "$STEAMCMD_BIN" ]]; then
    echo "SteamCMD not found; installing a private copy under:"
    echo "  $STEAMCMD_ROOT"
    mkdir -p "$STEAMCMD_ROOT"

    TMP_ARCHIVE="$(mktemp --suffix=.tar.gz)"
    trap 'rm -f "$TMP_ARCHIVE"' EXIT

    if command -v curl >/dev/null 2>&1; then
        curl -fL "$STEAMCMD_URL" -o "$TMP_ARCHIVE"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$TMP_ARCHIVE" "$STEAMCMD_URL"
    else
        echo "Neither curl nor wget is available to download SteamCMD." >&2
        exit 1
    fi

    tar -xzf "$TMP_ARCHIVE" -C "$STEAMCMD_ROOT"
    STEAMCMD_BIN="$STEAMCMD_ROOT/steamcmd.sh"
fi

mkdir -p "$SERVER_ROOT"

echo "Installing/updating Garry's Mod Dedicated Server (Steam app 4020)..."
echo "Server directory: $SERVER_ROOT"
"$STEAMCMD_BIN" \
    +force_install_dir "$SERVER_ROOT" \
    +login anonymous \
    +app_update 4020 validate \
    +quit

if [[ ! -x "$SERVER_ROOT/srcds_run" ]]; then
    echo "Installation finished, but srcds_run was not found at $SERVER_ROOT/srcds_run" >&2
    exit 1
fi

echo
echo "Dedicated server installed successfully."
echo "Next: bash tools/server/configure_gslt.sh"
