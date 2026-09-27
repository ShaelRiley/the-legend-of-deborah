# LoD stalled-cleanup recovery — verified source delivery

September 27, 2026. Repository: `ShaelRiley/the-legend-of-deborah`.

## Published source identity

Main was non-force fast-forwarded to, and read back at:
`5b529968ad1a8a59030b4560c6414398f06568fb`.

- Actual upstream parent: `aa102cc31951d34937ebaa106314cfcfdb855a2f`.
- Exact tested source tree: `ded2c87cd303d3eb1aa4fcf51798d7175c1ae7d2`.
- Exact source-manifest SHA256:
  `17499468edcf5c2c49369568834dcaa147043ac0ef341bcb6db441d821b66803`.
- Reconstructed patch SHA256:
  `e257dba33665b8bc8c5bbdc7cda8535f1a91aa6b1f470297265873bb2d066348`.

This closeout adds only this receipt after source verification. The full-matrix
claims apply to the source commit/tree above; this documentation-only closeout
is not a separately rerun gameplay matrix. Control-branch workflows and encoded
patch transport are not part of the published gameplay tree.

## Actual validation, including the failed attempt

Local final run: **264/264 registered headless suites passed**, with **767 Lua
syntax files**, no source changes, and identical before/after source digests.
All 262 previous suite names and commands remain; two production-executing suites
add 20 campaign/loot/party and 58 lifecycle/jump assertions. Existing Hermit,
warp and catalog assertions were also strengthened.

Independent full Actions run **36350793930** completed **263/264**. Its only
failure was `Great Crate Stock Hull Assets`: the CI image lacked NumPy. This
run remains recorded as failed; it is not retroactively called a green full run.
Artifact: **10941963920**. Artifact SHA256:
`0db47794d55215fb814b783361c4bebb1f54b673dc4f97c5d783b21d497b39df`.

Dependency-corrected Actions run **36351451820** reverified the exact frozen tree,
all prior suite names/commands and output hashes, then reran the failed Crate
suite successfully. No gameplay or test source changed. Combined independent
coverage is **264/264: 263 original passes plus one targeted rerun**, not a second
full-matrix run. Artifact: **10941998967**. Artifact SHA256:
`0e147db872d8da13b99f8e49432eae9e011765b9f3d9c684ad588b87317f1769`.

All **505 shipping Lua files** additionally passed Lua 5.1 syntax validation
locally and independently. Local/full-independent/rerun source manifests match
exactly. The independent archived source and published commit have the same
verified parent and tree. Source identity was checked before the non-forced
main update and read back afterward.

## Repairs and preservation

See `CLEANUP_RECOVERY_20260927.md` for the complete finite scope. Repairs cover
static loot expiry, false custom-seed reasons, repeat-hut announcement ownership,
voluntary-spectator difficulty scaling, duplicate/stale Spring Heel impulses,
Hero/Soldier death callbacks affecting replacement lives, and success-with-error
warp diagnostics. Three unbooted Bribe modules were moved byte-for-byte into
`tools/fixtures/retired_bribe/`, outside shipping content, with compatibility
readers and historical test coverage preserved.

The previous thread's missing working tree was not recovered. Its source archive
matched the actual upstream baseline; the missing repairs were reconstructed
and freshly tested. Prior fixture/invocation failures and the intentionally
stopped first local full run remain in the downloadable evidence, not counted
as passes. No gameplay tuning or live GDD law was changed.

## Next gate: native local acceptance, not deployment

Fully quit Garry's Mod before updating the local development installation:

```sh
cd ~/Downloads/the-legend-of-deborah && git fetch origin main && git switch main && git pull --ff-only origin main && bash tools/install_dev.sh
```

On the updated build, use `gm_flatgrass`. Check ordinary/chained jumps and a
new life after death, Hero/Soldier return, repeated staging introduction and gift
collection, and a cooperative party containing a voluntary spectator. Static
owned loot should survive beyond the ordinary 60-second dropped-loot expiry;
normal drops should still expire and level cleanup must still remove old loot.
Preserve the prior stairs, stomp/arrow-input, Soldier/Reckless, SPOT01–17,
B28/B29 opening/population and Great Crate regression checks during ordinary play.

Collect `console_latest.txt` and `rpg_summary_latest.txt` from that same session.
Headless checks do not certify native Source physics, presentation or networking.
No native acceptance, Workshop publication, VPS deployment or service restart was
performed. Release order remains local acceptance → Workshop package/revision
parity → matching VPS deployment. Deferred roadmap features remain untouched.
