# Pulse-first music direction

This source update extends main `67cb7dbf7343d05cd52c3f429e33322a8fc30248`.
The author's clarified rule is **rhythmic state before loudness**. Live GDD
05 `LOD-MUSIC-CUES-001` and 07 `LOD-MUSIC-CUES-IMPL` record the amendment;
both were read back successfully. Existing pressure, floor, boss, victory,
server/player permission and plan-lifetime authorities remain in charge.

| Listener state | Entry and sustained behavior |
| --- | --- |
| Rising T1–T3 or BOSS | Enter a marked pulsed phrase, favoring stronger energy |
| Falling between active T1–T3/BOSS roles | Enter a gentler pulsed phrase; do not enter a beatless intro |
| T0 or INTERLUDE | Enter and renew quiet material until pressure actually changes |
| Prolonged active pressure | Crossfade back into another pulse entry before a quiet breakdown/outro |
| VICTORY | Authored beginning, one receipt, no cue loop or reseek |

The director cycles eligible entries within the required class. Energy ranks
within that class, never across it. One eligible entry necessarily repeats;
multiple entries reduce predictable restarts. It keeps compatible beat phase
when at least four useful seconds remain. It does not escalate the gameplay
pressure state merely because a recording is ending. Section changes do not
announce a new block in either Die Logger view.

## Offline preparation

`tools/music/section_cues.py` decodes each validated recording to bounded 11,025 Hz
mono PCM during authoring/import. Ten-millisecond RMS envelopes and positive
transients are grouped on the declared four-beat bar grid. A pulse bar needs
attacks in at least three beats and consistent attack phase (coherence ≥0.72);
its attack threshold is max(0.002, 0.18 × bar RMS). Contiguous classifications
form safe intervals; a beatless breakdown splits a pulse run. RMS below 0.003
is excluded as silence. Relative energy is secondary. This heuristic can mistake
complex rhythms or texture; **audition and authored overrides remain necessary
for musical judgment**. The declared tempo/phase must already be correct.

Each class has at most eight entries. Entries lie on the bar grid, last at least
four seconds, and normally have alternate entry points spaced by at least eight
seconds. Long recordings retain entries distributed across their extent. Pulse
and quiet intervals cannot overlap. A newly imported looping role without its
required class rejects with a curation message. A loud drone or isolated impact
does not qualify as a sustained pulse. VICTORY stays outside analysis.

```bash
tools/music/lod_music_upload "/path/to/block" --write-cues
# Audition the saved cues; set source to authored for deliberate overrides.
tools/music/lod_music_upload "/path/to/block" --validate-only
tools/music/lod_music_upload "/path/to/block"
```

Example for a 64-second, 120 BPM recording with phase zero:

```json
{"version":1,"source":"authored",
 "pulse":[{"start":16,"finish":48,"energy":0.9},
          {"start":24,"finish":48,"energy":0.8}],
 "quiet":[{"start":0,"finish":8,"energy":0.2},
          {"start":56,"finish":64,"energy":0.1}]}
```

This is per-asset metadata, not additional soundtrack audio or a client download
requirement. The upload archive includes generated cues without rewriting the
author's local manifest unless `--write-cues` was requested. Declared authored
cues are validated rather than silently replaced. The deterministic starter
score includes authored maps matching its known sparse and foreground-drum roles.

Existing catalogs without cues remain playable and explicitly report
`legacy-no-cues`; their old behavior does **not** gain section guarantees. Publish
a new immutable version through offline ingestion to prepare them. One-way cue
enrichment of a formerly cue-less content hash is allowed for future plans only.
Conflicting cue metadata on an already prepared hash rejects. No hosted catalog
or actual dance-track collection was available for reprocessing in this task.

## Runtime bounds and degraded conditions

Cue selection scans at most eight entries of one class. Playback-position checks
run at most every 0.2 seconds per desired voice. There is no FFT, waveform scan,
beat detection, external analyzer, extra server scan or gameplay-time generation.
Ordinary decoding, streaming and the existing gain mixer still have a cost;
zero CPU cost or measured Steam Deck performance is not claimed.

Eight seconds before a boundary, the director may prepare a same-file second
voice. It uses `noplay noblock`, checks buffered time and uses `SetTime(pos, true)`
to avoid decode-to-position. Starting 1.6 seconds before the boundary leaves
the existing 1.2-second fade plus two 0.2-second check intervals. Intentional
same-file overlap can require another native transfer; it is counted within
the existing four-channel/two-transfer caps. It is not a second mixer or a claim
of shared native decode buffers. Once a pair is buffered, the outgoing voice is
paused and reserved for the next renewal; repeated sections do not repeatedly
download the master. Reservations yield to foreground role/floor changes.
Stale pending requests still count until callback.

If the spare voice cannot be admitted/ready, a buffered cue in the required class
uses a 1.2-second fade down, fast reseek and fade up on the existing voice. This
bounded degraded path can briefly dip the music but avoids an arbitrary hard seek
or intentional drift into the wrong rhythmic class. The director may repeat its
current entry when a different entry is not yet buffered. A required new class
that is unavailable retains outgoing valid audio while loading, as before.
Partially buffered starts time out after 20 seconds without buffer progress.

The operator/client Off controls, stopped runs, role fallback, frozen plans,
staging/portal continuity and one-shot fanfare suppression remain enforced.
`lod_music_client_status` now includes `cueMode`, `cueEnd`, `cueSource`,
`cueFallbacks` and current playback position.

## Finite native gate

After provisioning prepared media, install the exact source locally and start a
new campaign on `gm_flatgrass`. Enable music using the existing operator gate:

```text
lod_music_reload; lod_music_enabled 1; lod_music_status; lod_music_client_status
```

Audition rising pressure, falling-but-active pressure, long calm, long combat,
boss continuity, two-floor transitions and rapid reversal. Confirm pulse/quiet
classification, intentional crossfades, no repeated intro habit, no quiet combat
outro, quiet interlude renewal, and no extra block announcement. Exercise slow
buffering, four occupied channels, Off with an outstanding renewal callback and
the one-shot rescue fanfare. Measure native seek latency, frame time and memory
on Steam Deck. Automatic section analysis and native seeking are not audibly
certified by the headless tests.

Restore server music Off unless the operator intentionally keeps it enabled.
Capture `console_latest.txt` + `rpg_summary_latest.txt`. Local acceptance precedes
Workshop parity and matching VPS deployment; this source update does not perform
those release operations.

Native contracts: [SetTime](https://wiki.facepunch.com/gmod/IGModAudioChannel:SetTime),
[GetBufferedTime](https://wiki.facepunch.com/gmod/IGModAudioChannel:GetBufferedTime),
[PlayURL](https://wiki.facepunch.com/gmod/sound.PlayURL).
