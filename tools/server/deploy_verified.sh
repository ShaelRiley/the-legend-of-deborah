#!/usr/bin/env bash
# Run on the existing VPS, passing the FULL release SHA verified by the gate.
set -euo pipefail
umask 077
REVISION="${1:?Usage: bash tools/server/deploy_verified.sh FULL_VERIFIED_SHA}"
[[ "$REVISION" =~ ^[0-9a-f]{40}$ ]] || { echo 'A full commit SHA is required.' >&2; exit 1; }
REPO="${LOD_REPO_ROOT:-$HOME/the-legend-of-deborah}"
SERVER="${LOD_SERVER_ROOT:-$HOME/Servers/the-legend-of-deborah}"
SERVICE=legend-of-deborah.service
cd "$REPO"
[[ -z "$(git status --porcelain)" ]] || { echo 'Checkout has local work; preserve and reconcile it first.' >&2; exit 1; }
git fetch origin main
git cat-file -e "$REVISION^{commit}"
git merge-base --is-ancestor "$REVISION" origin/main
BEFORE="$(git rev-parse HEAD)"
git merge-base --is-ancestor "$BEFORE" "$REVISION" || { echo 'Target would discard/diverge from current checkout.' >&2; exit 1; }
[[ "$(systemctl show "$SERVICE" -p WorkingDirectory --value)" == "$REPO" ]] || { echo 'Service checkout differs; inspect deployment configuration.' >&2; exit 1; }
[[ -x "$SERVER/srcds_run" && -d "$SERVER/garrysmod" ]]
sudo -v
sudo systemctl is-active --quiet "$SERVICE"
BACKUP_PARENT="${LOD_RELEASE_BACKUP_ROOT:-$HOME/.local/state/legend_of_deborah/releases}"
mkdir -p "$BACKUP_PARENT"
BACKUP="$(mktemp -d "$BACKUP_PARENT/$(date -u +%Y%m%dT%H%M%SZ).XXXXXX")"
printf '%s\n' "$BEFORE" > "$BACKUP/previous-commit.txt"
printf '%s\n' "$REVISION" > "$BACKUP/target-commit.txt"
git symbolic-ref --quiet --short HEAD > "$BACKUP/previous-branch.txt" || true
STARTED="$(date -u '+%Y-%m-%d %H:%M:%S UTC')"
STOPPED=0
MOVED=0
rollback() {
    code=$?
    trap - EXIT
    if (( code != 0 && STOPPED )); then
        echo "Deployment failed; restoring previous source revision $BEFORE. Backup: $BACKUP" >&2
        sudo systemctl stop "$SERVICE" || true
        if (( MOVED )); then git switch --detach "$BEFORE" || exit "$code"; fi
        # Player data is never rolled back automatically: preserve any new writes.
        # Old launchers may rewrite config, so restore its saved bytes after start.
        sudo systemctl start "$SERVICE" || true
        if [[ -d "$BACKUP/cfg" ]]; then cp -a "$BACKUP/cfg/." "$SERVER/garrysmod/cfg/"; fi
        echo 'Rollback service requested; verify health before play.' >&2
    fi
    exit "$code"
}
trap rollback EXIT
sudo systemctl stop "$SERVICE"
STOPPED=1
# Copy after the process exits, so SQLite and file-backed records are consistent.
for item in data cfg sv.db sv.db-wal sv.db-shm; do
    if [[ -e "$SERVER/garrysmod/$item" ]]; then cp -a "$SERVER/garrysmod/$item" "$BACKUP/$item"; fi
done
if [[ -d "$SERVER/garrysmod/addons/the_legend_of_deborah" ]]; then
    cp -a "$SERVER/garrysmod/addons/the_legend_of_deborah" "$BACKUP/addon"
fi
# Configuration, including the private GSLT directory, remains in place.
git merge --ff-only "$REVISION"
MOVED=1
[[ "$(git rev-parse HEAD)" == "$REVISION" && -z "$(git status --porcelain)" ]]
sudo systemctl start "$SERVICE"
ready=0
for attempt in {1..30}; do
    if sudo systemctl is-active --quiet "$SERVICE" &&
       python3 "$REPO/tools/server/query_server.py" 127.0.0.1 > "$BACKUP/query.json" 2>/dev/null; then
        ready=1
        break
    fi
    sleep 2
done
(( ready == 1 ))
# Hold briefly to detect an immediate crash/restart rather than a momentary launch.
RESTARTS="$(systemctl show "$SERVICE" -p NRestarts --value)"
sleep 5
sudo systemctl is-active --quiet "$SERVICE"
[[ "$(systemctl show "$SERVICE" -p NRestarts --value)" == "$RESTARTS" ]]
[[ "$(cat "$SERVER/garrysmod/addons/the_legend_of_deborah/lod-build.txt")" == "$REVISION clean" ]]
sudo journalctl -u "$SERVICE" --since "$STARTED" --no-pager -o cat > "$BACKUP/startup-private.log"
# Never emit raw journal/process command lines: they can contain the Steam token.
python3 - "$BACKUP/startup-private.log" <<'PY'
import re, sys
text = open(sys.argv[1], errors='replace').read()
bad = re.findall(r'Lua Error|stack traceback|Segmentation fault|Segmentation violation|core dumped|Host_Error', text, re.I)
if bad:
    print('Startup error categories:', ', '.join(sorted(set(bad))))
    raise SystemExit(1)
print('Startup log: no matched fatal/Lua error signatures; native gameplay remains pending.')
print('Steam connectivity marker:', bool(re.search(r'Connection to Steam servers successful|VAC secure mode is activated', text, re.I)))
PY
STOPPED=0
trap - EXIT
printf 'DEPLOYED %s\nBACKUP %s\n' "$REVISION" "$BACKUP"
cat "$BACKUP/query.json"
echo 'Next: native smoke test in docs/validation/RELEASE_SAFETY.md; external listing/join remains pending.'
