# Bundled VRMod runtime

Source: https://github.com/Abyss-c0re/vrmod-x64

Revision: `2bddbfb96dac7820bcf8e0bcb90a6d27fc3a0dcc`

Archive SHA256: `bc6077185fe7fb84aa5be8f853633e5c86210cf12e9a55f05342fb0c32f73367`

`upstream.zip` is the complete, unmodified GitHub archive of this revision,
including upstream Lua, models, materials, documentation and license. The
license is also reproduced in `LICENSE`. The source link above preserves the
upstream cubechain attribution required by that license.

The installer applies the separately retained `deborah/patch.py` overlay and
`deborah/idle.lua` lifecycle, version `deborah-vr-idle-20261007-r2`. The upstream ZIP,
license, models, materials and other content remain byte-for-byte unchanged.
The overlay scopes addon hook/timer registrations without replacing the global
engine APIs. Idle runtime callbacks/timers and shared desktop method overrides
are suspended; join/start resumes them and the last exit/disconnect suspends them.
Canonical hand drops release departing players' held physics, retire the empty
motion controller and preserve world props and other VR players' holdings.
Owned collision proxies also retire after invalid disconnects; queued creation
cannot outlive its owner. Explicit diagnostics include both native resource owners.
Native modules load only on an explicit local headset start. A finite exit
cleanup finishes before the status reports idle. Passive presence messages and
bounded map initialization remain available so a headset can join without a restart.

The dedicated-server launcher verifies and installs this bundled dependency
before starting Source. No GitHub/Workshop download is needed at server startup.
Joining clients receive the addon Lua and registered model/material content;
headset clients still use their locally installed native module. Native client
modules are deliberately absent from a dedicated-server installation.

Use `python3 tools/install_vrmod.py --garrysmod /path/to/garrysmod --ensure`
on a stopped game/server to perform the same installation or verify an existing
copy. A pristine copy of the original pinned archive or the exact published
`deborah-vr-idle-20261007` overlay migrates atomically to this overlay; modified copies, additional operator files and duplicates are left
intact and reported as errors. Repeat verification does not rewrite runtime or
source-receipt bytes. The installer records all 139 mounted addon Lua hashes and
the two gamemode bridge hashes for the finite native capture's independent check.

The optional Sandbox pickup-list tool is retained at
`lua/vrmod/optional_sandbox/vrmod_pickup_list.lua`, outside the weapon loader.
Deborah derives from the base gamemode and provides no Sandbox toolgun. Keeping
the tool under `lua/weapons/gmod_tool/` makes Source request a missing toolgun
`shared.lua` during startup. This relocation leaves headset pickup support and
its ordinary configuration intact. The installer removes the obsolete toolgun
directory only while atomically replacing an independently verified predecessor.
