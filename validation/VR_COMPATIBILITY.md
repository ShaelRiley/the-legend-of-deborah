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
At this first checkpoint the dependency was separately provisioned with
`tools/install_vrmod.py`; the server provisioning repair below supersedes that
installation path. No native module is packaged in this repository.

Native headset acceptance remains pending: staging/controller panels, tracked
weapons and spells, death and victory Tetris HUD, timeout/finale tracking,
desktop teammate coexistence and remote pose replication. At the first checkpoint, whole-view flicker remained unaccepted; the camera/HUD
changes alone did not prove the native OpenXR/Source rendering issue resolved.
The user subsequently reports the flashing fixed. No public server restart,
Workshop release or new live GDD amendment occurred.

Next runtime action: fully restart GMod and play staging → death → level clear
on `gm_flatgrass` in VR with a desktop teammate, retaining the standard evidence
from `docs/TEST_LOGGING.md`. See `docs/VR.md` for dependency setup and controls.


## Server provisioning repair — 2026-09-30

Base: current main `5b1b29166e03dfbc2faeca3634ddf379d0d84e6b`, which merged
this branch's first VR compatibility checkpoint. Publication remains `master`
as TheMemeticist, at the user's explicit direction. No live VPS deployment is
part of this checkpoint.

Failed live evidence retained: the client reported `[LOD VR] Server VRMod:
missing — install the server Lua addon` and `[LOD VR] Local tracking: inactive`.
The server had gamemode compatibility code but lacked the actual networking
addon. The complete, unchanged pinned ZIP and license are now bundled. Standard
server installation/startup installs it offline; repeated startup verifies its
bytes and rejects mismatched/duplicate unpacked installations. The upstream
loader delivers Lua; Deborah registers all eleven model/material files.

`python3 tools/test_vr_gate.py`: **13/13 selected checks pass**, plus syntax for
**816 Lua files**. Added evidence covers real bundled CLI installation, repeat
start without writes, preservation of operator modifications, missing server
channels/APIs/content, native client startup errors, server staging, and release
rollback when a desktop-healthy server does not confirm VR readiness. Existing
player data/config/token and native WeaponEquip settlement regressions pass.

An isolated native Linux x64 Garry's Mod dedicated process mounted the actual
Deborah and pinned VRMod addon on `gm_flatgrass`. All ten upstream subsystems
initialized. The first boot proved pose APIs/channels/content present but did
not publish readiness: three existing weapon-definition InitPostEntity hooks
returned success/failure values and stopped later lifecycle dispatch. Those
callbacks now discard their private setup result, retaining weapon capacities
and ammunition accounting. The production regression exercises all three with
both present and missing stored weapons.

A fresh native boot after that repair printed:

```text
[LOD VR] Server runtime ready: vrmod-x64 2bddbfb96dac7820bcf8e0bcb90a6d27fc3a0dcc, 5 channels, 11 content files
```

This proves loaded server VR networking/APIs/content and registration of the
client asset download list. The final fresh boot also confirmed the replicated
server readiness flag true and both `vrmod_weapon_swap` and
`vrmod_allow_teleport` false after late addon/config initialization. The same
gameplay policy is applied at final map startup as well as Initialize. It is not a headset join or gameplay acceptance.
The private fixture uses the locally installed client branch's dedicated binary,
LAN loopback, separate writable data and no public-server Steam token. Its log
also retains a missing stock `weapons/gmod_tool/shared.lua` AddCSLuaFile error,
shader warnings and an outdated-server notice; overall production deployment
health is not claimed from that fixture. Local evidence is retained under
`~/.local/share/gvrmod-setup/deborah-server-smoke/` (`native-private.log` before
repair, `native-fixed.log` after lifecycle repair and `native-final.log` with
final gameplay-policy enforcement).

Next: deploy the verified source and fully restart the real dedicated service;
its launcher installs the dependency automatically. Rejoin with WiVRn connected,
run `lod_vr_start`, then check `lod_vr_status` after VR starts. Confirm server
available, local tracking active and registration joined. Then perform the native multiplayer lifecycle
acceptance above. The user's flashing resolution is reported evidence; remote
pose replication, controller gameplay and coexistence still need the live test.
