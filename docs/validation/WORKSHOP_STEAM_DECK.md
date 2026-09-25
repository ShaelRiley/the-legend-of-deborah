# Steam Deck Workshop tool repair — September 24, 2026

Baseline: `c615e0c5c3a00ab7377dae6c2af2542710fcfa29`.
Shael's local pull and exact-revision check succeeded. The build then stopped with
`Could not find Garry's Mod gmad`; no package or upload was produced by that attempt.

The scripts searched only native Linux tools. The established Deck workflow uses
GarrysMod/bin/win64/gmad.exe and gmpublish.exe via Proton Experimental, the existing
Steam compatdata/4000 prefix and SteamAppId/SteamGameId 4000.

The shared workshop_tools.sh now discovers native tools or Windows tools, launches
the latter through Proton, and converts only path arguments to Windows Z-drive
paths. Change notes remain verbatim. Explicit GMAD/GMPUBLISH overrides remain
supported; LOD_GMOD_DIR selects a nonstandard game install and LOD_PROTON selects
an installed Proton launcher. Native execution retains its library search paths.
The publisher resolves its executable before packaging and reports success only
after a successful tool exit. Build content and Workshop item 3791535712 are unchanged.

Validation: `python3 tools/test_workshop_tools.py` passes isolated real-shell
build/publish flows with native/Proton doubles, paths containing spaces, explicit
overrides, app/prefix identity, HTML exclusion, failed creation/upload and missing
tools. `bash -n tools/workshop/*.sh` and `git diff --check` pass. Tests do not contact
Steam and are not evidence of native publishing success.

No gamemodes/, lua/ or addon.json bytes changed. The prior 221-suite gameplay result
and scoped solo acceptance are inherited unchanged; the gameplay matrix was not
repeated for shell-only tooling. Actual Deck execution, Workshop publication and
downloaded-package verification remain pending. VPS deployment/restart follows
verified Workshop publication of this exact release; it has not occurred.
