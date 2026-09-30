# Optional VRMod compatibility — 2026-09-30

Base: main `df2d8f04ac5daa32f853330c38d2642af9d22dd7`.
Publication branch: `master`, explicitly requested by the current user.
GitHub SSH account and commit identity: TheMemeticist.

Authority navigation used the live GDD export on this date: 00 AI Entry Point,
01 AI Rule Index, relevant 06 UI/lifecycle and 07 shared/server authority rules,
plus the exact Special Move keyboard restriction. The current user authorizes
optional VR compatibility; the implementation retains existing mechanics.

`python3 tools/test_vr_gate.py`: **11/11 selected checks pass**, plus syntax for
**816 Lua files**. This is a finite regression gate, not the complete systems
matrix or native acceptance.

- Optional dependency detection, six nonduplicated quick-menu entries, HUD
  preference restoration and input routing.
- Real death/victory Tetris client handlers: mandatory wait, eliminated-player
  rejection, stick centering, UI suppression, hard drop and desktop F/bind paths.
- Existing server death/Tetris lifecycle, campaign clock/timeout reset, finale
  presentation/resources, Player Options movement and 78 Magic dispatch casts.
- Actual desktop and VR map-toggle seam, ownership and cached-map reopening.
- Canonical manual generation/transport parity, offline reader and release wiring.
- Installer checksum rejection, atomic extraction, license preservation,
  refusal to replace existing addons and failed-install cleanup.

The upstream pinned ZIP was downloaded and verified locally: revision
`2bddbfb96dac7820bcf8e0bcb90a6d27fc3a0dcc`, SHA256
`bc6077185fe7fb84aa5be8f853633e5c86210cf12e9a55f05342fb0c32f73367`.
The installed dependency remains an upstream addon, separately provisioned
with `tools/install_vrmod.py`; no native module is packaged in this repository.

Native headset acceptance remains pending: staging/controller panels, tracked
weapons and spells, death and victory Tetris HUD, timeout/finale tracking,
desktop teammate coexistence and remote pose replication. The previously
reported whole-view flicker is unaccepted; the camera/HUD changes do not prove
the native OpenXR/Source rendering issue resolved. No public server restart,
Workshop release or new live GDD amendment occurred.

Next runtime action: fully restart GMod and play staging → death → level clear
on `gm_flatgrass` in VR with a desktop teammate, retaining the standard evidence
from `docs/TEST_LOGGING.md`. See `docs/VR.md` for dependency setup and controls.
