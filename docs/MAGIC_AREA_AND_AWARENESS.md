# Magic area readability and Spatial Awareness

Continues `695978d8bab756c4f0d92ffd467be538123f3b34` on `hybrid/antigravity`.

Shael clarified that explosive **Bomb and Missile** areas were unclear, reported
white bomb rendering, and explicitly extended Spatial Awareness to either side
at half the rear range, rounded up, with a clear sound and directional light.

- Bomb/Missile impact packets now carry the **same center and radius** used by
  server damage targeting. A brief fixed spherical outline and center mark show
  reach; a separate inner pulse supplies motion. World depth remains enabled;
  line-of-sight restrictions still apply. Reduced effects removes the inner pulse.
- Blast uses maze connectivity rather than a sphere. Its existing target traversal
  also supplies the affected cells, shown by thin floor marks inset from container
  walls. Removed the old unrelated fixed-size circular range impression. Damage,
  obstruction, Magic cost, Wisdom/Astral scaling and attack budgets are unchanged.
- Area geometry uses the existing FX packet: one float for explosive radius, or
  three bytes per reachable Blast cell plus grid metadata. No new scan/packet per
  rendered cell. At most four area effects coexist and expire after 1.15 seconds;
  cleanup clears them. The previous reliable-channel repair remains intact.
- Bomb body and fuse now use explicit vertex-color materials instead of debugwhite.
  Black iron, a pale yellow fuse, amber ember/sparks and cosmetic burn-down retain
  the existing bomb silhouette and lob/impact mechanics. One quiet attached hiss
  starts when rendered and stops when the projectile is removed. No dynamic light,
  trail entity or extra networking is added for the fuse.
- Spatial Awareness preserves the cardinal, three-cell-wide rear strip with
  `rear=max(1,WIS_MOD)`. It adds single-cell-wide left/right rays of
  `ceil(rear/2)` cells. Same-floor and ordinary obstruction rules remain; Astral
  Reach does not extend awareness. Its description now states the new behavior.
- Awareness retains its selected qualifying monster; when it stops qualifying,
  deterministic selection chooses a replacement. Fixed absolute-lateral tie order,
  missing monster-type text and stale selection across death/role/level changes.
  Uses the existing hostile registry instead of scanning all world entities.
- The private logger event supplies the named LEFT/RIGHT/BEHIND YOU notice and a
  detection-time position. Its already-deduplicated receipt drives one violet light
  near the corresponding screen edge and the shared sound policy's distinct alert.
  History and telemetry retain the event. The light lasts 1.25 seconds, rotates
  with the viewer's facing toward that fixed position, and never tracks an enemy,
  adds a world silhouette or persists as a radar. Awareness can preempt the ordinary
  sound cooldown while retaining its own 0.8-second sound spacing.

## Design reconciliation and validation

Live GDD: `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY` via AI navigation
00/01 → 03/04/06/07 and exact HUMAN row `WIS_SPATIAL_AWARENESS`.
The targeted HUMAN effect text was updated in place and verified at revision
`ANLCKQmY4d8FQ0np0TDKJqTewiNXqFyyuDPrSLM3OOwGX_6GUHcVCfqIgeYjwWCL2nEYtL6iSlfP2bBsY0GRVWemgkqABv831NqVtF7MkA`.
The normalized feat tab directs exact definitions to that row. The audit fixture
records this row's revision separately; unrelated historical row evidence remains.

Integrated static gate: **53/53 suites**, including Lua syntax/diff check, 150-entry
feat inventory with zero blank descriptions, exact Spatial Awareness description
equality, real server impact-to-client radius rendering, Blast traversal/closed-gate
footprint, bomb material/color/audio lifecycle, production awareness rear/side
geometry and rounding, LOS, selection/respawn/level reset, directional HUD,
logger/history/position transport, priority sound and duplicate suppression.

Source/OpenGL appearance and audible balance still require Shael's retest. Fully
quit GMod before installing the exact new candidate. On gm_flatgrass, throw a Bomb
and guide a Missile into groups near open floor and walls; compare visible impact
extent with actual victims and the die log. Check black body, lit fuse and hiss.
With Spatial Awareness, expose monsters behind, directly left/right, just beyond
side reach, and behind a closed wall. Expect named/private violet directional
notifications only for eligible acquisitions, with no repeated alert while the
same monster remains qualified. Confirm death/respawn and ordinary combat remain
stable. Export console_latest.txt and rpg_summary_latest.txt after the session.

No main promotion, public-server deployment or Workshop publication.
