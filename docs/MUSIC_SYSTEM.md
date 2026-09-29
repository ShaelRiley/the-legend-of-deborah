# Streamed Music System

**Current author workflow:** [music folders and ZIP imports](MUSIC_FOLDER_IMPORT.md).
Chill is Tension 1; the other roles are Tension 2, Tension 3, Tension 4, Boss and
Fanfare. Folder catalogs use block one for every missing-role default and alias
Chill for staging/post-fanfare. Import prepares manifests, cues and chunks before
gameplay. The legacy manifest/profile workflow below still applies to catalogs
that have not moved to folder imports.

Source implementation; native Garry’s Mod audio acceptance and hosted deployment
remain pending. See [Chill staging and performance](MUSIC_PERFORMANCE.md) for the
current delivery, cache, resource-priority and migration contract. The server starts with **`lod_music_enabled 0`**. The default
client preference is On, but cannot override the server. No media request,
prefetch, fallback or music-only sting bypasses either Off switch. Gameplay
sound effects, voices and ambience retain their existing behavior.

## Player and operator controls

Options is available from the existing Player Menu. It saves Music On/Off,
music volume and Always Run. Always Run reverses only the locomotion speed
choice; the physical sprint modifier, modified Use, Soldier limits, statuses,
Dodge speed thresholds and existing legal speed caps remain authoritative.

| Server console / superadmin command | Behavior |
| --- | --- |
| `lod_music_enabled 0` / `1` | Immediate master permission; archived, default 0 |
| `lod_music_set all` / `<set_id>` | Full catalog or one named set, for future plans |
| `lod_music_profile <profile_id>` | Server role defaults, for future plans |
| `lod_music_universal_boss 0` / `1` | Force server/project BOSS source; default 0 |
| `lod_music_universal_victory 0` / `1` | Force server/project VICTORY source; default 0 |
| `lod_music_universal_interlude 0` / `1` | Force server/project INTERLUDE source; default 0 |
| `lod_music_post_victory auto` / `interlude` / `off` | Padding policy; default auto |
| `lod_music_reload` | Validate the locally registered catalog; keep frozen plans |
| `lod_music_import <staged_upload_id>` | Load the companion service’s validated import receipt |
| `lod_music_status` | Current/configured selection, listeners, roles and validation errors |

Client console equivalents are `lod_music 0/1`, `lod_music_volume 0..1`,
`lod_always_run 0/1` and `lod_music_client_status`. A set can overlap others;
`all` remains unrestricted. Unknown/empty selections are rejected. Named settings
are saved in `data/legend_of_deborah/music/settings.json`.

## Architecture and limits

`sh_music.lua` owns schema validation, role resolution, deterministic floor plans,
pressure hysteresis and built-stair projection. `sv_music.lua` reads existing
RunManager, CampaignTimeout, Warden/Hector and damage authorities; it sends
frozen plan metadata and compact listener state. `cl_music.lua` owns all streamed
playback through `sound.PlayFile(..., "noplay noblock", ...)`. Its
`cl_music_media.lua` helper fetches paced immutable chunks into a bounded cache;
media never travels through game net messages.

Each plan reserves the maximum four physical floors from a dedicated music seed
stream. Actual geometry uses only its existing floors. Same-dungeon rebuilds,
portal arrival, reconnect, set edits and hot imports cannot reroll a plan. Even
an empty offered plan stays empty; register media before starting a new campaign
when first testing. A successful clear reserves the next plan early.

T0/T1/T2/T3 are four looping arrangements. BOSS binds the arena-entry floor’s
logical block through phases, clones and the Gordon-to-Hector handoff. Final
boss defeat returns to T0; only accepted rescue/cash completion creates the
single nonlooping VICTORY receipt. Staging resolves Chill/INTERLUDE with T0 fallback. AUTO takes ready next-floor Chill directly,
otherwise uses the outgoing INTERLUDE; INTERLUDE policy retains padding until
staging; OFF skips outgoing padding and uses T0 until the next staging Chill is ready. Unavailable interludes fall back to calm audio/ambience.
No transition delays the real clock, build, ready portal or intermission.

Role sources resolve custom → server default → project default. Universal switches
skip custom sources for that role. Explicitly inherited roles are valid;
incorrectly declared files are rejected. Asset hashes deduplicate native channels,
including a shared source across blocks. Failures advance only through that
role’s finite candidates. A started/failed fanfare never replays another source.

The mixer waits for a buffered, suitable section before fast-seeking. For
cue-prepared assets, pulse/quiet class takes precedence over loudness or a
corresponding position in another track; compatible beat phase is retained when
it fits safely inside that section. Legacy cue-less assets retain their earlier
corresponding-phase/authored-start behavior and report `legacy-no-cues`.
It retains outgoing
valid audio while waiting, reconciles stair reversals, and fades obsolete voices
before admitting work beyond its ceiling. No sample-accurate native claim is made.

See [pulse-first section direction](MUSIC_SECTION_DIRECTION.md) for offline
analysis, authored overrides, entry rotation, sustained pulse/quiet renewal and
the bounded fallback when a second voice cannot be buffered in time. No musical
analysis runs during gameplay. Section checks use the existing 0.2-second cadence;
gain envelopes run at most 30 Hz and skip unchanged volume writes. Same-file
section overlaps read the cache within the four-channel/64 MiB declared PCM
admission limits. There is only one paced HTTP request at a time.

| Provisional implementation parameter | Value |
| --- | --- |
| Listener sample / gain fade / maximum gain updates | 0.2 s / 1.2 s / 30 Hz |
| Escalation / relaxation / minimum dwell | 0.8 s / 6 s / 4 s |
| Recent confirmed combat/damage | 5 s; three received hits can request Danger |
| Danger / urgent survival | HP ≤40% / ≤20%; effective clock ≤180 s / ≤60 s |
| Buffered lead / stalled channel timeout | 0.3 s / 8 s |
| Unbuffered channel timeout | 20 s; ready prefetched tracks remain available |
| Score slots / pending native opens / HTTP requests | 4 / 2 / 1 |
| Media chunk / scheduled body rate | 16 KiB / up to 32 KiB/s |
| Declared float-PCM admission estimate | 64 MiB |
| Per file | ≤4 MiB encoded, ≤180 s, stereo 44.1 kHz Vorbis |
| Catalog / compressed plan / plan piece | ≤2 MiB / ≤60,000 bytes / 1 KiB |
| Catalog counts | ≤256 blocks, ≤1,792 assets, ≤64 profiles, ≤128 sets |
| Upload / staged bundles | ≤30 MiB / ≤16 |
| Completed disk cache / partial media | 32 MiB and 64 files / one file ≤4 MiB |

Off stops native playback, pending media work and that listener's music-only
plan/state service. A native HTTP callback cannot be cancelled, but on the prepared
host only one 16 KiB chunk can remain in flight; it is discarded when stale.
The governor pauses downloads/new opens during resource pressure and releases the
score during severe sustained client overload. See `MUSIC_PERFORMANCE.md` for
thresholds, recovery, server budgets and the limits of application-level QoS.
The PCM admission estimate is not a native-memory measurement. Cold assets must
finish downloading and verify before playback; warm assets incur no HTTP traffic.

`Now playing: <title>` is confirmed only when a logical block actually enters the
audible mix. The server validates its assignment and emits private
`MUSIC_BLOCK_START` through the canonical CombatRolls live/history record path.
Role changes, prefetch, loops, source fallback, buffering recovery and Off/On do
not create extra starts. A genuine later return can announce again.

## Hosting and initial defaults

No public music origin was deployed by this implementation. The default audio
bundle is delivered separately and is excluded from required Workshop content.
`tools/music/generate_defaults.py` reproducibly produces the original D-Dorian
Foundations starter profile: four 16-second tension loops, a distinct 16-second
boss loop, a 6.5-second victory phrase and a 16-second interlude. It is an initial
profile for audition/native acceptance, not the planned 32-composition album.

On the operator host, provision Python 3, ffmpeg/ffprobe, a dedicated media root,
and HTTPS. Offline cue analysis and the generator require numpy. Use the actual HTTPS origin and
the actual Garry’s Mod DATA directory in place of these examples:

```bash
python3 tools/music/generate_defaults.py /srv/lod-music-sources
python3 tools/music/catalog_service.py --root /srv/lod-music --origin https://music.example.org --game-data /srv/gmod/garrysmod/data/legend_of_deborah/music --import-folder /srv/lod-music-sources/deborah-defaults-v1
python3 tools/music/catalog_service.py --root /srv/lod-music --origin https://music.example.org --game-data /srv/gmod/garrysmod/data/legend_of_deborah/music --import-folder /srv/lod-music-sources/deborah-foundations-v1
python3 tools/music/catalog_service.py --root /srv/lod-music --origin https://music.example.org --game-data /srv/gmod/garrysmod/data/legend_of_deborah/music --configure /srv/lod-music-sources/defaults.json
```

For uploads, run the same service without `--import-folder`/`--configure` behind
the authenticated HTTPS proxy. Its listener binds **127.0.0.1:8787** only. Supply
`MUSIC_UPLOAD_TOKEN` (at least 32 random characters) in a protected environment
file, outside the repository. Only public audio paths reach game state; no token
or private upload URL does. See `tools/music/nginx.example.conf`. Restrict process
permissions to its music root and the one game-data music directory.

Keep immutable `/music/blocks/<id>/<version>/<file>.ogg` masters on the host. New
clients fetch bounded static `/music/chunks/<sha256>/<index>.dat` objects with
immutable cache headers. New imports create them automatically; existing media
requires the offline `--prepare-delivery` command described in `MUSIC_PERFORMANCE.md`. Keep redirects off,
use per-connection transfer limits, and protect gameplay traffic at the host/network
level. The supplied proxy example limits to four media connections per IP and
32 KiB/s per connection with eight aggregate active responses; shared-NAT clients
can encounter slower buffering. Application caps do not establish router-level QoS.
Measure concurrent play before production approval.

## Author upload

Add the repository’s `tools/music` directory to the author terminal’s PATH, or
run its `lod_music_upload` script directly. With `LOD_MUSIC_UPLOAD_ORIGIN` and
`MUSIC_UPLOAD_TOKEN` supplied securely:

```bash
lod_music_upload "/path/to/local-block-folder"
# Local validation only:
lod_music_upload "/path/to/local-block-folder" --validate-only
```

The uploader validates with ffprobe/ffmpeg, uploads only the manifest and declared
files over authenticated HTTPS, then requests import. It never asks sandboxed
GMod Lua to read desktop files. The service rejects unsafe ZIP members, links,
undeclared assets, malformed metadata, hash/size failures, incompatible custom
T0–T3 grids, undecodable media and incorrect loop roles. It publishes a complete
immutable directory before atomically replacing the catalog. Aborted validation
leaves the published catalog intact. Old immutable versions remain for frozen
plans. A new version is mandatory for edits. Operators should prune abandoned
staging folders when the finite staging limit is reached.

The optional `--game-data` mirror queues an explicit catalog reload, consumed
before the next new music plan; no recurring directory scans or automatic HTTP
catalog polling occur. `lod_music_reload` offers immediate catalog refresh without
changing active/offered plans. With the mirror omitted, copy the generated catalog
and import receipts into the game-data music directory and run the reload command.

Use the delivered manifest as the schema example. `kind` is `block` or `profile`;
profiles map roles to assets but never become procedural selections. Each role
is `"inherit"` or an asset containing file, SHA-256, bytes, codec/rate/channels,
duration, loop boundaries, bpm/beats/grid/phase, envelope handoff, gain/headroom,
credits and source lineage. Omitted roles normalize to inheritance. Only declared
custom files accompany a block. Legacy four/six-file blocks migrate with an
explicit new manifest/version; no old bytes are overwritten.

Looping roles now acquire compact `cues` during offline validation/upload when
omitted. Use `lod_music_upload "/path/to/block" --write-cues` to save the analysis
for audition/editing before uploading. It performs no upload. Mark auditioned
manual replacements `source: "authored"`; each interval identifies `start`,
`finish` and relative `energy` in either `pulse` or `quiet`. T1–T3/BOSS must have a
pulse section; T0/INTERLUDE must have a quiet section. VICTORY cannot have cues.
The uploader rejects a role without the required class and never fabricates a
beat from loudness. New immutable versions can enrich older cue-less asset hashes
for future plans; existing plans keep their original metadata. A change to an
already registered cue map for identical bytes still rejects as conflicting
metadata. Author a new master/version when changing that established map.

Operator metadata passed to `--configure` can select `projectDefault` and replace
`sets`, for example:

```json
{"projectDefault":"deborah-defaults","sets":{"friday":{"title":"Friday","revision":"v1","members":["deborah-foundations"]}}}
```

The project-default profile must cover all seven roles. Missing coverage is
reported by `lod_music_status`; gameplay still works.

## Finite native acceptance

After hosted media is reachable and the exact source build is installed locally,
start a new campaign and use the server console line:

```text
lod_music_reload; lod_music_enabled 1; lod_music_status
```

Verify Chill staging → same block with active-role crossfade, all tension roles, stair
ascent/descent/reversal with a concurrent tension change, warp/fall/backtracking,
separated listeners, boss/Hector continuity, actual rescue-only fanfare, interlude
policies, next staging continuity and one matching live/retained block-name entry.
Test late join, server/player Off during a pending request and during the fanfare,
re-enable, failure/reset, slow/offline media and cold-cache simultaneous clients.
Listen for seams/clicks; measure memory, ingress/egress, frame time and gameplay
latency on Windows/Linux/Steam Deck. Use `lod_music_client_status` plus the normal
`console_latest.txt` and `rpg_summary_latest.txt` evidence.

Then restore `lod_music_enabled 0` until the operator intentionally enables the
feature. Local acceptance → Workshop publication/parity → matching VPS remains
the release sequence. This source delivery does not establish those later gates.

## Design synchronization and API references

The live GDD was read through 00 → 01 → relevant 05/06/07 music rules and the named
Options anchor. The author's subsequent express amendment request is now applied
and read-back verified: default Off is corrected in normalized and HUMAN rules,
implemented controls and Options are identified, and provisional tuning and
remaining hosting/native gates are recorded. Big Loot, Event and Skeleton
amendments were reconciled in the same update. See
`validation/GDD_SYNC_20260928.md`. Initial `FAILED_PRECONDITION` attempts and the
original `validation/MUSIC_GDD_AMENDMENTS.json` payload remain historical evidence;
they are no longer an outstanding synchronization blocker.

Native API contracts consulted: [sound.PlayFile](https://wiki.facepunch.com/gmod/sound.PlayFile),
[GetBufferedTime](https://wiki.facepunch.com/gmod/IGModAudioChannel:GetBufferedTime),
[EnableLooping](https://wiki.facepunch.com/gmod/IGModAudioChannel:EnableLooping).
