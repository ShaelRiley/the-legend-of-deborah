# Bundled VRMod runtime

Source: https://github.com/Abyss-c0re/vrmod-x64

Revision: `2bddbfb96dac7820bcf8e0bcb90a6d27fc3a0dcc`

Archive SHA256: `bc6077185fe7fb84aa5be8f853633e5c86210cf12e9a55f05342fb0c32f73367`

`upstream.zip` is the complete, unmodified GitHub archive of this revision,
including upstream Lua, models, materials, documentation and license. The
license is also reproduced in `LICENSE`. The source link above preserves the
upstream cubechain attribution required by that license.

The dedicated-server launcher verifies and installs this bundled dependency
before starting Source. No GitHub/Workshop download is needed at server startup.
Joining clients receive the addon Lua and registered model/material content;
headset clients still use their locally installed native module. Native client
modules are deliberately absent from a dedicated-server installation.

Use `python3 tools/install_vrmod.py --garrysmod /path/to/garrysmod --ensure`
on a stopped game/server to perform the same installation or verify an existing
copy. Existing mismatched copies are left intact and reported as an error.
