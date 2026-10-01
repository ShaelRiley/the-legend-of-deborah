# Music System 2 — Surge-rendered phrases

The author's score remains eight Music Blocks, 48 arrangements, 1,402 curated phrases and 170,860 notes in D Dorian at 130 BPM. Project-owned patches in **Surge XT 1.3.4** render that score offline into bundled stereo Ogg Vorbis phrases. Garry's Mod chooses phrases, starts them on future boundaries and blends floor lanes. Players install ordinary game content; Surge is an external build dependency.

The existing server MusicDirector still owns permission, pressure, frozen physical-floor assignments, staging, bosses, accepted rescue/cash receipts and private new-block Die Logger announcements. `sv_music.lua` is unchanged. Server Music defaults Off. No soundtrack HTTP requests or audio transfers occur on the music metadata channel.

## Play and operate

Fully quit GMod, update/install this source, then start The Legend of Deborah on `gm_flatgrass`. Select **Player Menu → Options → Music**. For the listen-server host or superadmin, On enables the server master and saved local preference. The checkbox reflects both; opening Options changes neither. Other players control their saved preference within server permission. Off is personal. Zero volume also tears down playback.

The equivalent explicit command remains:

```text
lod_music_enabled 1; lod_music 1
```

Effects, dialogue and essential gameplay cues retain their own controls. Inspect music with:

```text
lod_music_status; lod_music_client_status
```

Healthy client playback reports `system=MS2`, `backend=surge-rendered`, catalog/render/patch revisions, floor targets, role, current/prepared clips, bridge, channels, pending opens, estimated PCM bytes, late skips/resyncs and errors. Composer statistics arrive asynchronously; a later status call includes the sample. `streamedBytes=0` excludes the initial game-content download.

| Operator control | Behavior |
| --- | --- |
| `lod_music_enabled 0/1` | Saved server master; default 0. |
| `lod_music_set all` or a catalog set ID | Eligible blocks for future dungeon plans. |
| `lod_music_universal_boss 0/1` | Block A's boss arrangement when enabled. |
| `lod_music_universal_victory 0/1` | Block A's fanfare when enabled. |
| `lod_music_universal_interlude 0/1` | Block A's Chill for dedicated interlude selection. |
| `lod_music_post_victory auto/interlude/off` | Next first-floor Chill / dedicated calm selection / current-block T0. |
| `lod_music_reload` | Revalidate the catalog for future plans. |
| `lod_music_status` | Catalog, configured/frozen settings, listeners and errors. |

Already offered/active plans remain frozen. Every core block supplies all six roles; missing roles in later libraries inherit Block A. Existing operator settings live under `legend_of_deborah/music2/`; player preference/volume names are unchanged.

## Musical contract

[MS2_CATALOG.md](MS2_CATALOG.md), [MS2_CATALOG.json](MS2_CATALOG.json) and [MS2_CLIPS.zip](MS2_CLIPS.zip) retain the original curation, cadence/energy graph, MIDI lineage and portable clips. The Surge builder reads the compiled notes directly. It preserves each onset, gate, logical instrument, pitch and velocity within one native 32-frame block (0.726 ms); open hats are choked by the next closed hat. Ordinary phrases last eight beats; accepted fanfare lasts twelve.

The composer retains six preferred successors, cadence/root and energy compatibility, source adjacency, recent-three exclusion where alternatives exist, and fresh presentation entropy after a genuine return. Procedural variety comes from authored phrase choice. Shared 130 BPM timing preserves reversible square-root floor blending. Role changes enter on a shared four-beat bar; natural release tails overlap. Missed boundaries beyond 60 ms are discarded and sequencing resumes at a future bar. Asynchronous callbacks never start a musical phrase.

Per-note swing, velocity/gate/timbre mutations, acid register inversion, synthetic fills, countdown +6% tempo slew and critical +22-cent pitch lift are superseded live-synth implementation details. Recent critical combat in T3/BOSS retains cheap +8% phrase gain. Server pressure still responds to the authoritative countdown and combat. Once-only victory and configured post-victory Chill remain intact.

## One custom workstation

Human-readable [patches.json](../tools/music/surge/patches.json) defines nine logical voices and ten physical patches. Factory patches/wavetables are not loaded.

| Part | Surge character |
| --- | --- |
| Acid | Mono saw/square, glide, resonant diode low-pass, strong envelope, velocity cutoff and continuous tempo-related cutoff LFO. |
| Industrial | Three detuned VA oscillators, dark low-pass and controlled soft saturation. |
| Strings | Detuned saw/unison, modest width; softer calm attack. |
| Brass | Synthetic saw/square stab with low-pass envelope. |
| Bass | Mono saw/square/sub foundation, low-pass and restrained glide/drive. |
| Tom | Electronic sine body with downward pitch envelope. |
| Snare | Noise plus pitched electronic body, short envelope. |
| Kick | Deep sine body, fast pitch drop and short transient. |
| Hat | High-pass synthetic noise/metal; separate closed/open envelopes, one logical lane. |

Fixed instrument gains plus restrained 27 Hz high-pass / 11.5 kHz low-pass master conditioning retain arrangement dynamics. No per-phrase loudness normalization or heavy compression is applied. Held Acid's spectral movement is measured by the authoring gate; subjective timbre remains a listening gate.

A hidden input-free DHTML panel runs only the ES5 composer/grid. Native `sound.PlayFile` with `noplay noblock` prepares validated local assets; a bounded `IGModAudioChannel` pool plays complete phrases. The runtime does no note synthesis, time stretch or pitch shift. Missing/failed assets produce diagnostics and a ten-second retry backoff. A single quiet Surge string D/A bridge may cover a real gap for at most eight seconds. Persistent failure stops playback. Legacy oscillator/tone engines are retired; a diagnostic and silence are the failure policy.

## Build and verify

Ordinary verification needs Python, Node and the existing Lua gate dependencies, **not Surge**:

```bash
python3 tools/music/build_ms2_audio.py  # package ES5 control plane
python3 tools/test_ms2_surge_bank.py
python3 tools/test_music_gate.py --output /tmp/ms2-gate
```

Actual decoding of all committed audio additionally requires ffmpeg and numpy:

```bash
node tools/test_music_audio.js
```

Full authoring is separate; see [the pinned build instructions and attribution](../tools/music/surge/README.md). Source MIDI recompilation is unnecessary for this timbre update. `build_ms2.py` remains the canonical curation/export tool when an explicitly authorized score change occurs.

[MS2_SURGE_BANK.json](MS2_SURGE_BANK.json) records every file, source-note hash, duration, levels, encoded hash, PCM hash and pinned renderer/patch/tool provenance. [MUSIC_PERFORMANCE.md](MUSIC_PERFORMANCE.md) records package and runtime bounds. [The Surge validation record](validation/MS2_SURGE.md) and [audition](validation/MS2_SURGE_AUDITION.ogg) establish offline evidence. Native GMod/Steam Deck/co-op musical timing, subjective sound and performance remain pending. Google Docs rejected the authorized amendment; [its exact unapplied text](validation/MS2_SURGE_GDD_AMENDMENTS.json) is preserved. No Workshop or VPS action is part of this checkpoint.
