# Music folders and ZIP imports

Each immediate subfolder is one Music Block. The first folder in natural name
order supplies defaults for the entire library. Use `01-foundations`,
`02-labyrinth`, `03-nightfall` to make that order explicit. Numeric sorting also
handles `1`, `2`, `10` correctly. This chooses the default block; it does not
turn procedural floor assignment into a playlist.

## Prepare the recordings

Export **Ogg Vorbis (`.ogg`), stereo, 44,100 Hz, approximately 128 kb/s**. An Ogg
container containing Opus is not Vorbis and is rejected. Each file is at most
4 MiB; loops are at most 180 seconds. Master clean seamless loops with headroom
for effects/dialogue. The four custom tension versions within each block must
have the same duration, tempo and starting downbeat, using complete four-beat
bars. Boss may have its own tempo/length. Fanfare is a **nonlooping 5–12 second
recording**, ideally a 5–7 second main phrase with a short tail.

Convert an already edited/mastered WAV without changing its length:

```bash
ffmpeg -i chill.wav -vn -ac 2 -ar 44100 -c:a libvorbis -b:a 128k chill.ogg
```

Encoding does not align compositions or create seamless edits. Import checks
actual decoding, duration and rhythmic/quiet suitability. Keep WAV/FLAC masters
separately; put only named `.ogg` recordings in the upload.

| Filename | Playback | Compatibility key |
| --- | --- | --- |
| `chill.ogg` | **Chill = Tension 1**, staging and post-fanfare | T0 / INTERLUDE |
| `tension2.ogg` | Tension 2 | T1 |
| `tension3.ogg` | Tension 3 | T2 |
| `tension4.ogg` | Tension 4 | T3 |
| `boss.ogg` | Boss encounter loop | BOSS |
| `fanfare.ogg` | One shot after accepted rescue/cash recovery | VICTORY |

The first block needs all six. Later blocks can omit any or all recordings:
each omission inherits the **matching role** from block one. Chill also serves
staging/interlude; no seventh file is needed. Independent universal boss,
fanfare and interlude switches use the first block's matching recording.

Accepted aliases: `tension1.ogg` / `attention1.ogg` for Chill,
`attention2.ogg` / `attention3.ogg` / `attention4.ogg`, legacy `t0.ogg`–`t3.ogg`,
and `victory.ogg`. Use **one filename per role**. Names are lowercase. Block
folder IDs use lowercase letters, digits, underscores and hyphens, begin with
a letter/digit and are at most 64 characters. Optional display titles may use spaces.

## ZIP layout

Example paths **inside the ZIP**:

```text
music/01-foundations/chill.ogg
music/01-foundations/tension2.ogg
music/01-foundations/tension3.ogg
music/01-foundations/tension4.ogg
music/01-foundations/boss.ogg
music/01-foundations/fanfare.ogg
music/02-labyrinth/chill.ogg
music/02-labyrinth/tension2.ogg
music/02-labyrinth/tension3.ogg
music/02-labyrinth/tension4.ogg
```

Here, Labyrinth borrows Foundations' boss/fanfare and uses its own Chill in
staging and after fanfares. From the parent directory on your computer:

```bash
zip -r music.zip music
scp music.zip ubuntu@40.160.86.240:~/music.zip
```

Block folders directly at the ZIP root also work, as does a direct folder path.
No manifest is required. Include the **whole library** on each import; it becomes
the new procedural pool. Unchanged folders reuse prepared metadata. Removed
folders leave future selection; old media remains for frozen plans. If a saved
Music Block Set references a removed folder, update its membership first.

Exclude masters, artwork, nested folders, OS sidecars and unrelated files.
Limits: 1 GiB compressed and expanded; 256 blocks. Paths, links, duplicate names
and member sizes are checked before extraction. Preparation handles one recording
at a time.

## One-time VPS setup

After source publication, run in the VPS shell:

```bash
ssh ubuntu@40.160.86.240
cd ~/the-legend-of-deborah
git pull --ff-only origin main
sudo apt-get update
sudo apt-get install -y ffmpeg python3-numpy
sudo install -d -o ubuntu -g ubuntu /srv/lod-music
python3 tools/music/lod_music_catalog.py setup --origin https://YOUR-MUSIC-HOST
```

**Replace `https://YOUR-MUSIC-HOST` with a real public HTTPS origin.** Setup saves
paths; it does not create DNS, certificates or a web server. No live music origin
was deployed by this source update. Before playback, serve `/srv/lod-music/music/`
at `/music/` with a valid public TLS certificate, no login/redirects, and access
from players' computers. Use the static locations/rate limits in
[`nginx.example.conf`](../tools/music/nginx.example.conf), replacing its hostname
and certificate paths. Permit HTTPS traffic in the VPS firewall when provisioning
the host. The `/v1/` proxy and token service are unnecessary for SCP/ZIP imports.

| Saved setting | Default VPS path |
| --- | --- |
| Published media/catalog | `/srv/lod-music` |
| GMod catalog mirror | `/home/ubuntu/Servers/the-legend-of-deborah/garrysmod/data/legend_of_deborah/music` |
| Operator configuration | `/home/ubuntu/.config/legend_of_deborah/music-catalog.json` |

`setup` accepts `--root` and `--game-data` for other installations. Import as
ubuntu, not root. Provision/import **before launching the first music-enabled
campaign**. Installing/restarting the game follows the normal local acceptance →
Workshop → matching VPS release sequence.

## Routine upload

After copying the ZIP to the VPS, run:

```bash
cd ~/the-legend-of-deborah
nice -n 10 python3 tools/music/lod_music_catalog.py import ~/music.zip
python3 tools/music/lod_music_catalog.py status
```

Import hashes/decodes recordings, infers timing, analyzes pulse/quiet sections,
generates manifests and immutable versions, prepares 16 KiB download chunks,
validates the entire batch, then publishes the catalog and game-data mirror.
A future-plan reload receipt is queued. Failed preparation preserves the working
catalog. Interrupted publication may leave unused immutable files, never a
catalog pointing to partial media; reimport is safe. Status reports the default
block and any assets missing cues/delivery preparation.

Once hosting is reachable, use the **GMod server console**, not the SSH shell:

```text
lod_music_reload; lod_music_enabled 1; lod_music_status
```

For persistent opt-in, put `lod_music_enabled 1` in the server's normal persistent
configuration. Code defaults to Off; player Off and zero volume remain effective.
Import never enables playback automatically.

Already active/offered plans stay frozen, including an empty plan created before
the first import. Start a **new campaign** after initial setup. Subsequent imports
apply to newly planned dungeons. Reload reads prepared metadata only; it never
analyzes audio, scans source folders or reshuffles a current dungeon.

## Rebuild or inspect cues

Recompute analyzed cues from the same complete library:

```bash
nice -n 10 python3 tools/music/lod_music_catalog.py rebuild-cues ~/music.zip
```

This bypasses the unchanged-block cache, retains authored overrides and publishes
only if results differ. A folder path can replace the ZIP. Validate without
publishing with:

```bash
python3 tools/music/lod_music_catalog.py check ~/music.zip
```

Inspect generated cues in `/srv/lod-music/music/blocks/<id>/<version>/manifest.json`.
Do not edit those immutable copies. For corrections, add optional `block.json`
to a **source** block folder, then import/rebuild. Example:

```json
{"title":"Labyrinth","credits":"Shael Riley","bpm":120,"boss_bpm":120}
```

`bpm` applies to custom tension siblings; `boss_bpm` applies to Boss. Both are
optional, 40–240 BPM. Automatic inference is an offline heuristic with possible
half/double-time ambiguity; explicit tempo is preferable when known. A quiet
drone cannot qualify as a combat track merely by being loud. Invalid recordings
report the block/role rather than receiving fabricated rhythmic cues.

For manual maps, add `cues` keyed by `chill`, `tension2`, `tension3`, `tension4`
or `boss` to `block.json`. Copy a generated cue object, set `source` to `authored`,
and edit its `pulse`/`quiet` intervals. Boundaries must align to bars, sections
must last at least four seconds, classes cannot overlap, and each class has at
most eight entries. Chill requires quiet; combat/boss requires pulse. Fanfare
starts at zero once and has no looping cue map. See
[section direction](MUSIC_SECTION_DIRECTION.md).

Legacy manifest uploads still work in legacy catalogs. Whole-folder import
replaces their active profile defaults with block one. Thereafter use this
whole-library command; profile selection and single-block imports cannot bypass
the new default contract. Sets survive when their members remain. Old files stay
available for frozen plans.

## Verification boundary

Automated checks use real Vorbis files, the production Lua validator, every-role
fallback, staging aliases, finite fanfare policy, malicious archives, atomic
failed preparation, idempotent imports and cue rebuilds. Native listening, public
hosting, concurrent cold-client bandwidth and Steam Deck performance need an
installed candidate and actual recordings. Test a new campaign through Chill
staging → deployment → stairs → boss → rescue fanfare → Chill. Inspect readable
roles, source provenance and cue state with `lod_music_client_status`.

Technical contracts: [Facepunch PlayFile](https://wiki.facepunch.com/gmod/sound.PlayFile),
[channel looping](https://wiki.facepunch.com/gmod/IGModAudioChannel:EnableLooping),
[FFprobe](https://ffmpeg.org/ffprobe.html).
