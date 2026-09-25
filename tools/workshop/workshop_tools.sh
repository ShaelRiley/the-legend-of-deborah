#!/usr/bin/env bash
# Shared native/Proton launcher for the GMod Workshop command-line tools.
# Sourced by build_workshop.sh and publish_workshop.sh.
lod_workshop_find_tool() {
    local env_name="$1" name="$2" candidate base
    local override="${!env_name:-}"
    if [[ -n "$override" ]]; then
        if [[ -f "$override" && ( -x "$override" || "$override" == *.exe ) ]]; then
            readlink -f -- "$override"
            return 0
        fi
        echo "$env_name does not identify a usable tool: $override" >&2
        return 1
    fi
    local bases=()
    if [[ -n "${LOD_GMOD_DIR:-}" ]]; then
        bases+=("$LOD_GMOD_DIR")
    else
        bases+=(
            "$HOME/.local/share/Steam/steamapps/common/GarrysMod"
            "$HOME/.steam/steam/steamapps/common/GarrysMod"
        )
    fi
    for base in "${bases[@]}"; do
        for candidate in "$base/bin/linux64/$name" "$base/bin/linux64/${name}_linux" "$base/bin/${name}_linux"; do
            if [[ -x "$candidate" ]]; then readlink -f -- "$candidate"; return 0; fi
        done
    done
    for base in "${bases[@]}"; do
        for candidate in "$base/bin/win64/$name.exe" "$base/bin/$name.exe"; do
            if [[ -f "$candidate" ]]; then readlink -f -- "$candidate"; return 0; fi
        done
    done
    echo "Could not find $name (native or Windows). Set $env_name=/full/path/to/the/tool." >&2
    return 1
}

lod_workshop_run_tool() (
    local tool="$1"; shift
    local bin_dir parent_dir proton candidate arg path_next=0
    bin_dir="$(dirname "$tool")"
    parent_dir="$(dirname "$bin_dir")"
    if [[ "$tool" != *.exe ]]; then
        export LD_LIBRARY_PATH="$bin_dir:$parent_dir:${LD_LIBRARY_PATH:-}"
        cd "$bin_dir"
        "$tool" "$@"
        exit $?
    fi

    proton="${LOD_PROTON:-}"
    if [[ -z "$proton" ]]; then
        for candidate in \
            "$HOME/.steam/steam/steamapps/common/Proton - Experimental/proton" \
            "$HOME/.local/share/Steam/steamapps/common/Proton - Experimental/proton"; do
            if [[ -x "$candidate" ]]; then proton="$candidate"; break; fi
        done
    fi
    if [[ ! -x "$proton" ]]; then
        echo "Windows Workshop tools found, but Proton Experimental is unavailable. Set LOD_PROTON=/full/path/to/proton." >&2
        exit 1
    fi
    proton="$(readlink -f -- "$proton")"
    export STEAM_COMPAT_CLIENT_INSTALL_PATH="${STEAM_COMPAT_CLIENT_INSTALL_PATH:-$HOME/.local/share/Steam}"
    export STEAM_COMPAT_DATA_PATH="${STEAM_COMPAT_DATA_PATH:-$STEAM_COMPAT_CLIENT_INSTALL_PATH/steamapps/compatdata/4000}"
    export SteamAppId=4000 SteamGameId=4000
    export WINEDEBUG="${WINEDEBUG:--all}"

    # Convert only path-valued arguments; preserve change notes verbatim.
    local args=()
    for arg in "$@"; do
        if (( path_next )); then
            if [[ "$arg" == /* ]]; then arg="Z:${arg//\//\\}"; fi
            path_next=0
        else
            case "$arg" in -folder|-out|-addon|-icon) path_next=1 ;; esac
        fi
        args+=("$arg")
    done
    echo "Using Proton Workshop tool: $tool"
    cd "$bin_dir"
    "$proton" run "$tool" "${args[@]}"
)
