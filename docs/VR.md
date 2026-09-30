# VR play

Deborah supports optional VRMod clients alongside ordinary desktop players.
The server must load the VRMod Lua addon, and each headset client needs the
matching addon plus the native VR module. A source push alone does not install
the dependency or update a running multiplayer server.

## Quest 3 / Quest 3S through WiVRn on Linux

Use native Garry's Mod's `x86-64` Steam branch and
[gVRMod](https://github.com/Abyss-c0re/gVRMod)'s OpenXR module. Connect the headset
to WiVRn first, then launch GMod with WiVRn's OpenXR runtime available to Steam.
Use one VRMod Lua addon installation. Windows/OpenVR users can use their
compatible VRMod runtime; Deborah does not depend on a particular headset.

The pinned Lua addon is Abyss-c0re/vrmod-x64 at
`2bddbfb96dac7820bcf8e0bcb90a6d27fc3a0dcc`, matching the gVRMod setup used for
this integration. To install it on a **stopped** server or client:

```sh
python3 tools/install_vrmod.py --garrysmod "/path/to/GarrysMod/garrysmod"
```

The installer verifies the archive's SHA256, preserves upstream license/source
information and refuses to replace an existing addon. It installs Lua and
content only; native headset modules remain a separate client installation.
Keep only one VRMod copy, including Workshop copies. Restart the entire
game/server after installation. Select **The Legend of Deborah** on
`gm_flatgrass`, start VR, then run `lod_vr_status` if tracking is unavailable.

## Controller access

VRMod owns tracking, tracked weapon aim, locomotion, use, reload and weapon
selection. Right trigger fires; left trigger uses the selected RMB spell or
the held throwable's secondary action. Select another Form in the Spellbook
to bind it to that trigger. Menus remain live multiplayer interfaces.

Open VRMod's quick menu and select **Deborah Player Menu**. The same Character,
Spellbook, Equipment, Die Log, Manual, Wallet and Options pages are available
through controller-pointed Derma panels. A controller binding to VRMod's
`boolean_menucontext` action also toggles the Player Menu. Separate quick-menu
entries reach the Team Menu, Map, Haste and GPS through their existing ownership
and cost checks.

VRMod's **use** action performs the ordinary contextual F action during death
or victory: pay respects/enter Tetris, finish eligible death Tetris, or start
victory Tetris. The **Deborah: Pay respects / Tetris** quick-menu entry does the
same. For death without Tetris, primary fire requests respawn once the mandatory
wait ends. Neither path bypasses server eligibility. Use requests a campaign
restart only when the existing failure/timeout rules allow it.

During Tetris, move the locomotion stick left/right to move a piece, forward to
rotate, back to drop, and press jump to hard-drop. Center the stick between
presses. Chat and menus suppress these inputs. Equipment Special Moves retain
their authored physical-keyboard recipes; the Tetris stick never issues Special
Move tokens. Auxiliary mouse-button spell bindings retain their desktop controls.

Deborah temporarily enables VRMod's gamemode HUD capture and restores the saved
values on VR exit. Victory/finale and TIME OVER camera cuts yield to headset
tracking. Desktop cameras and server timing still follow their ordinary paths.
The gamemode disables the pinned addon's weapon replacement and teleportation
to preserve procedural item state and legal dungeon movement.

## Validation

Run `python3 tools/test_vr_gate.py` for the finite static gate. It exercises
production VR input, desktop life controls, Tetris lifecycle, timeout/finale
cameras, map access, movement, spell input, manual parity and dependency installation.
Headless checks do not prove stereo stability, WiVRn frame delivery, controller
panel legibility or multiplayer pose replication.

Native acceptance: fully restart GMod, then play from staging through a death
and a level clear on `gm_flatgrass` in VR, with a desktop teammate. Confirm the
Player Menu and Team Menu can be operated with controllers, spells and firearms
follow tracked aim, Tetris is visible and playable, and cinematic events leave
head tracking responsive. Use the evidence paths in [TEST_LOGGING.md](TEST_LOGGING.md).
The earlier whole-view flickering report remains an open runtime issue until
the headset test confirms it is resolved; this integration does not certify a
render-runtime fix.
