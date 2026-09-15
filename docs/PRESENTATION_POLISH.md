# Equipment, Magic area and statue presentation checkpoint

Candidate: `astra/equipment-update`. Live design authority:
`1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`, normalized tabs 03/05/06,
with current author direction in LOD-UI-009. The subsequent user correction keeps
the face HUD exactly where it was; face, Magic and weapon readout code is unchanged.

Equipment has a dedicated sibling tab and frame. Open the Player Menu with P or I,
then select Equipment. It no longer depends on a Spellbook snapshot or toggle.
The existing body map, item grid, drag/drop and validation remain intact. Readying
an equipped potion or selecting a weapon closes the Equipment page itself. Late snapshots
cannot switch pages or reopen a closed page. Existing P/I/L destinations remain.
The potion/inventory instructions in the canonical manual use the new tab path.

Magic areas now use a common content-color/opacity policy: 255-alpha boundaries
at peak visibility, with 102-alpha interiors fading over existing effect lifetimes.
Blast fills every transmitted affected floor cell; projectile impacts fill their
actual-radius spheres. Sphere rendering uses a single inward shell from inside and
an outward shell from outside, using the engine’s [sphere-rendering contract](https://wiki.facepunch.com/gmod/render.DrawSphere). The legacy force-wave disc uses the same 40% fill.
Beam retains its cyan laser core, and point impacts remain point effects. Geometry
is depth-tested and does not change damage, targeting, range or network payloads.
The existing four-area/48-form-effect budgets remain; legacy waves are capped at
12, with trailing waves suppressed under reduced effects. Spheres use bounded
32×16 tessellation, reduced to 16×8 under reduced effects.

The statue is placed on the Hermit's side of the hut, 40 units inside the rear wall,
facing into the room. Its use prompt is drawn by the same gamemode hook, font,
colors, outline, anchor and current-key formatter as portal/manual interaction.
The old separate wallet prompt is removed; the legacy manual/portal hook defers
to the gamemode prompt. Server wallet range and line-of-sight checks are retained.

## Evidence and finite visual gate

All 75 integrated automated suites pass, including new independent-page lifecycle
checks, production Blast and sphere geometry, all Content opacity pairs, sphere
inside/outside views, reduced effects, wave expiry/budgets, statue position and
rebound Use-key prompts. Lua syntax and accepted mechanics regressions pass.

In Garry's Mod, check the new Equipment tab, the statue behind the Hermit, and a
Magic area cast. Confirm the translucent coverage is readable against the maze
while the perimeter remains clear. Source rendering and real-network play are
still human acceptance work; no FPS improvement or in-game acceptance is claimed.
