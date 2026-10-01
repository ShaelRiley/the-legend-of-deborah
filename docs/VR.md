# VR play

Deborah supports optional VRMod clients alongside ordinary desktop players.
The repository includes the complete pinned VRMod Lua/content addon. The
standard dedicated-server installer and launcher install it automatically;
every launch verifies the installed files before Source starts. Joining clients
receive the addon Lua and registered models/materials. Each headset client also
needs its local native VR module and a connected VR runtime.

A GitHub push still needs to be deployed to the VPS and the server process
fully restarted. A map change does not run the dependency installer.

## Dedicated server deployment

Deploy the verified commit using the existing service and
`tools/server/deploy_verified.sh`. Its release branch defaults to `main`; if
testing the explicitly requested `master` branch before merging, set
`LOD_RELEASE_BRANCH=master`. The service must run
`tools/server/run_public_server.sh` from that updated checkout. That launcher
installs the bundled addon into `garrysmod/addons/vrmod-x64` with no network
download, then stages Deborah and starts Source.

At map initialization the gamemode checks all five VR network channels,
server pose APIs and eleven content files. Successful startup logs:

```text
[LOD VR] Server runtime ready: vrmod-x64 2bddbfb96dac7820bcf8e0bcb90a6d27fc3a0dcc, 5 channels, 11 content files
```

The deployment health gate requires this confirmation and rolls back a release
that lacks it, even when ordinary server queries succeed. Dependency bytes are
backed up and restored with the source; player records are retained. Operator
configuration and the private Steam token remain in place.

For a server that uses another launcher, run the installer below on the stopped
server before starting Source. Keep one VRMod copy, including Workshop copies.
An existing mismatched or modified unpacked addon is reported and left intact;
reconcile that installation before restarting.

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
python3 tools/install_vrmod.py --garrysmod "/path/to/GarrysMod/garrysmod" --ensure
```

The installer verifies the archive's SHA256, preserves upstream license/source
information and verifies an existing identical addon without rewriting it.
It installs Lua and content only; native headset modules remain a separate
client installation. The archive is bundled, so installation works offline.
Keep only one VRMod copy, including Workshop copies. Restart the entire
game/server after installation. Select **The Legend of Deborah** on
`gm_flatgrass`, or reconnect to the updated multiplayer server. With WiVRn
connected, run `lod_vr_start`, then `lod_vr_status`. The status should report
server VRMod available, local tracking active and server VR registration joined.
If startup fails, the command reports the exact missing prerequisite or native
runtime error. A working singleplayer setup needs no new headset module for
this server repair.

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
cameras, map access, movement, spell input, manual parity, real offline dependency
installation, server staging and deployment rollback.
Headless checks do not prove stereo stability, WiVRn frame delivery, controller
panel legibility or multiplayer pose replication.

Native acceptance: fully restart GMod, then play from staging through a death
and a level clear on `gm_flatgrass` in VR, with a desktop teammate. Confirm the
Player Menu and Team Menu can be operated with controllers, spells and firearms
follow tracked aim, Tetris is visible and playable, and cinematic events leave
head tracking responsive. Use the evidence paths in [TEST_LOGGING.md](TEST_LOGGING.md).
The user reports the earlier whole-view flickering resolved. Multiplayer headset
acceptance remains pending after this server dependency repair.
