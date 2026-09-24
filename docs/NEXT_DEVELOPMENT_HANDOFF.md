# Handoff — C3 company-brand front-face repair

Repository: ShaelRiley/the-legend-of-deborah; branch main. Last fetched baseline:
ccc6535e0db22943185fa4b1fb6ca50d1a880432. Resume from the published main commit
containing this handoff (verify with git fetch / git rev-parse origin/main), never
reset to the baseline. Final publication response records the exact new SHA.

Live GDD: 1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY. Read navigation00→01,
then only relevant05/07 LOD-CRATE-C3-001. Existing outward-face design governs;
this is a renderer correction, with no design/tuning or manual change.

Author approves shown restored hull, reports no sprays, and provides a native
status receipt: brand140 Atlas Tire Pyrolysis;716/1792 containers selected;
36 draws, zero skips, valid UnlitGeneric material and one loaded texture.
Investigation proves branding quads had the reverse of Source's front-face
vertex order. All428 inspected stock cargo VTX triangles and Facepunch's concrete
DrawQuad example establish the independent negative-cross convention. The old
static test incorrectly enforced the opposite. Only quad traversal is reversed;
UVs, anchors, selection, materials, depth/culling, hull, concrete and gates stay
unchanged. Diagnostic renderer receipt: source-front-face-20260924.

Fresh corrected regression failed before the fix, then passed2048 brand/side/yaw
cases plus unmirrored/upright UV assertions. All256 original assets/fit pass.
Fresh canonical integration:221 suites passed, zero failures. Log, tested blob
identities and full failed/native evidence are in
validation/GREAT_CRATE_C3.md. Static success is not native visual acceptance.

Next finite action: fully quit GMod, pull/install published main, inspect sprays
in the maze and return one screenshot showing a complete company composition.
If still absent, return lod_container_brand_status from that view; check the
renderer receipt above. Do not request unrelated attachments or full logs.

Preserve all incomplete C3 exits in its reconciliation table: broader hull/tint
sampling, brand visibility/offset/mips/legibility, stock gate appearance,
concrete/grate traversal/cover/rails, reset/rejoin and dense successive-seed native
frame-time/residency. This explicit author-requested defect repair does not
silently add another feature pass. Next permitted optimization checkpoint after
this boundary: measure production branding placement/rebuild cost with fixed
representative/dense manifests and exact output-equivalence gates before any
optimization. Do not claim native FPS from headless measurements.

Roadmap: Great Crate → low-end PC optimization → focused fatal/game-breaking
safety → native playtest. Deferred September28–October4,2026:
Big Loot → Events → comprehensive systems audit. Preserve all unfinished scope.
Validate, commit, non-force-push and verify each small coherent result before
adding scope. No VPS deployment or Steam Workshop publication.
