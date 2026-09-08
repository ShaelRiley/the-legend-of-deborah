#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'USAGE'
Usage: ./tools/dev/make_antigravity_bundle.sh TASK_ID [VALIDATION_LOG] [AGENT_REPORT]

Creates an ignored audit bundle under antigravity_bundle/ for review by Sol/Astra.
Run from the repository while checked out on hybrid/antigravity.

Optional environment variables:
  LOD_GMOD_DIR              Override Garry's Mod root directory.
  LOD_RUNTIME_SCREENSHOT    Path to one screenshot to copy into the bundle.
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

TASK_ID="${1:-}"
VALIDATION_LOG="${2:-}"
AGENT_REPORT="${3:-}"

if [[ -z "$TASK_ID" ]]; then
  usage >&2
  exit 64
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "ERROR: not inside a Git repository." >&2
  exit 2
}
cd "$REPO_ROOT"

BRANCH="$(git branch --show-current)"
if [[ "$BRANCH" != "hybrid/antigravity" ]]; then
  echo "ERROR: audit bundles may only be generated on hybrid/antigravity; current branch is '$BRANCH'." >&2
  exit 3
fi

SAFE_TASK="$(printf '%s' "$TASK_ID" | tr -cs 'A-Za-z0-9._-' '_' | sed 's/^_*//; s/_*$//')"
[[ -n "$SAFE_TASK" ]] || SAFE_TASK="AG-UNSPECIFIED"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BUNDLE_ROOT="$REPO_ROOT/antigravity_bundle"
BUNDLE="$BUNDLE_ROOT/${SAFE_TASK}_${STAMP}"
mkdir -p "$BUNDLE"

FETCH_STATUS="PASS"
if ! git fetch origin main --quiet; then
  FETCH_STATUS="WARN: git fetch origin main failed; using existing origin/main if present"
fi

MAIN_REF="origin/main"
if ! git rev-parse --verify "$MAIN_REF" >/dev/null 2>&1; then
  MAIN_REF="main"
fi

HEAD_SHA="$(git rev-parse HEAD)"
MAIN_SHA="$(git rev-parse "$MAIN_REF")"
MERGE_BASE="$(git merge-base "$MAIN_REF" HEAD)"
AHEAD_BEHIND="$(git rev-list --left-right --count "$MAIN_REF"...HEAD)"
BEHIND="$(awk '{print $1}' <<<"$AHEAD_BEHIND")"
AHEAD="$(awk '{print $2}' <<<"$AHEAD_BEHIND")"

{
  echo "THE LEGEND OF DEBORAH — ANTIGRAVITY STATE"
  echo "task_id=$TASK_ID"
  echo "generated_utc=$STAMP"
  echo "repository=$REPO_ROOT"
  echo "branch=$BRANCH"
  echo "head=$HEAD_SHA"
  echo "main_ref=$MAIN_REF"
  echo "main_sha=$MAIN_SHA"
  echo "merge_base=$MERGE_BASE"
  echo "ahead_of_main=$AHEAD"
  echo "behind_main=$BEHIND"
  echo "fetch_main=$FETCH_STATUS"
  echo
  echo "== git status --short --branch =="
  git status --short --branch
  echo
  echo "== recent commits =="
  git log --oneline --decorate -5
} > "$BUNDLE/01_state.txt"

{
  echo "THE LEGEND OF DEBORAH — ANTIGRAVITY CHANGES"
  echo "task_id=$TASK_ID"
  echo "baseline=$MAIN_REF ($MAIN_SHA)"
  echo "head=$HEAD_SHA"
  echo
  echo "== diff stat: $MAIN_REF...HEAD =="
  git diff --stat "$MAIN_REF"...HEAD
  echo
  echo "== name/status: $MAIN_REF...HEAD =="
  git diff --name-status "$MAIN_REF"...HEAD
  echo
  echo "== current commit =="
  git show --no-ext-diff --stat --oneline --decorate --no-renames HEAD
  echo
  echo "== current commit name/status =="
  git show --no-ext-diff --format= --name-status --no-renames HEAD
} > "$BUNDLE/02_changes.txt"

VALIDATION_RESULT="PASS"
{
  echo "THE LEGEND OF DEBORAH — ANTIGRAVITY VALIDATION"
  echo "task_id=$TASK_ID"
  echo "head=$HEAD_SHA"
  echo
  echo "== git diff --check $MAIN_REF...HEAD =="
  if git diff --check "$MAIN_REF"...HEAD; then
    echo "[PASS] git diff --check"
  else
    echo "[FAIL] git diff --check"
    VALIDATION_RESULT="FAIL"
  fi

  echo
  echo "== changed shell-script syntax =="
  mapfile -t CHANGED_SH < <(git diff --name-only "$MAIN_REF"...HEAD -- '*.sh')
  if ((${#CHANGED_SH[@]} == 0)); then
    echo "[SKIP] no changed .sh files"
  else
    for path in "${CHANGED_SH[@]}"; do
      if [[ -f "$path" ]]; then
        if bash -n "$path"; then
          echo "[PASS] bash -n $path"
        else
          echo "[FAIL] bash -n $path"
          VALIDATION_RESULT="FAIL"
        fi
      fi
    done
  fi

  if [[ -n "$VALIDATION_LOG" ]]; then
    echo
    echo "== agent-supplied validation log: $VALIDATION_LOG =="
    if [[ -f "$VALIDATION_LOG" ]]; then
      cat "$VALIDATION_LOG"
    else
      echo "[FAIL] requested validation log does not exist"
      VALIDATION_RESULT="FAIL"
    fi
  fi

  echo
  echo "overall_static_validation=$VALIDATION_RESULT"
} > "$BUNDLE/03_validation.txt"

TEMPLATE="$REPO_ROOT/tools/dev/antigravity_report_template.md"
if [[ -n "$AGENT_REPORT" && -f "$AGENT_REPORT" ]]; then
  cp "$AGENT_REPORT" "$BUNDLE/04_agent_report.md"
elif [[ -f "$TEMPLATE" ]]; then
  sed \
    -e "s/{{TASK_ID}}/$SAFE_TASK/g" \
    -e "s/{{HEAD_SHA}}/$HEAD_SHA/g" \
    "$TEMPLATE" > "$BUNDLE/04_agent_report.md"
else
  cat > "$BUNDLE/04_agent_report.md" <<REPORT
# Antigravity Batch Report

Task ID: $TASK_ID
Ending SHA: $HEAD_SHA

ERROR: report template unavailable. Fill this report manually before submission.
REPORT
fi

GMOD_DIR="${LOD_GMOD_DIR:-$HOME/.local/share/Steam/steamapps/common/GarrysMod/garrysmod}"
RUNTIME_DIR="$GMOD_DIR/data/legend_of_deborah"
RUNTIME_COPIED=0
for name in console_latest.txt rpg_summary_latest.txt rpg_session_latest.txt; do
  src="$RUNTIME_DIR/$name"
  if [[ -f "$src" ]]; then
    cp "$src" "$BUNDLE/$name"
    RUNTIME_COPIED=$((RUNTIME_COPIED + 1))
  fi
done

if [[ -n "${LOD_RUNTIME_SCREENSHOT:-}" ]]; then
  if [[ -f "$LOD_RUNTIME_SCREENSHOT" ]]; then
    ext="${LOD_RUNTIME_SCREENSHOT##*.}"
    cp "$LOD_RUNTIME_SCREENSHOT" "$BUNDLE/runtime_screenshot.$ext"
  else
    printf 'Requested screenshot not found: %s\n' "$LOD_RUNTIME_SCREENSHOT" > "$BUNDLE/runtime_screenshot_missing.txt"
  fi
fi

{
  echo "THE LEGEND OF DEBORAH — ANTIGRAVITY BUNDLE MANIFEST"
  echo "task_id=$TASK_ID"
  echo "head=$HEAD_SHA"
  echo "runtime_files_copied=$RUNTIME_COPIED"
  echo "runtime_source=$RUNTIME_DIR"
  echo
  find "$BUNDLE" -maxdepth 1 -type f -printf '%f\n' | sort
} > "$BUNDLE/00_manifest.txt"

printf '%s\n' "$BUNDLE"
