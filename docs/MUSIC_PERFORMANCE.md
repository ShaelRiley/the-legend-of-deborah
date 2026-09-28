# Chill staging and gameplay-first music

Staging plays the offered Floor-1 block's **Chill / INTERLUDE**, using the same
role resolver and universal override as the post-fanfare interlude. Missing
interludes fall back to that block's resolved T0. AUTO now hands off to the next
staging Chill; entering the maze crossfades to its active role while retaining
the block. Reusing the same asset and rhythmic class preserves transport.

## Resource behavior

- Music Off, server Off or zero volume releases audio and stops new downloads.
  Explicit client demand suspends that listener's plan/state service, target
  selection and pressure calculations. Off clients discard queued metadata before
  decompression. Essential effects, voices and gameplay remain independent.
- Audio stays on a separate HTTPS service. The client admits one immutable
  **16 KiB chunk** at a time, paced at up to **32 KiB/s** of body data, with no
  accumulated burst credit. A correctly configured origin can finish at most
  that one uncancellable chunk after Off; the callback is discarded.
- Completed recordings are SHA-256 verified and cached on demand. The cache
  holds at most **32 MiB / 64 files**, evicts the oldest unpinned entries, and
  allows one partial file of at most 4 MiB. Startup inspection is lazy, only when
  music is enabled and resources permit. Warm reuse requires no HTTP request,
  repeat hash scan or repeat directory scan. The full library is never fetched.
- Native playback opens verified local files with `noplay noblock`. Section
  crossfades share the cached recording, so a second voice does not download it
  again. At most four native slots and two pending native opens are admitted.
  A conservative **64 MiB declared float-PCM estimate** also limits admission;
  this is an estimate, not measured native memory. Longer tracks may need a faded
  handoff instead of simultaneous decoding. Optional prefetch occupies no decoder.
- Periodic selection, readiness and section reconciliation run at 5 Hz, with
  bounded state/load-event wakeups; gain envelopes
  run at most 30 Hz and skip unchanged native volume writes. Music never performs
  waveform analysis in gameplay. The existing offline cue rules remain intact.
- The governor pauses downloads, cache verification, new decoder opens and
  prefetch when smoothed real frame time exceeds 35 ms, ping exceeds 180 ms or
  rises 80 ms over its baseline, or the connection is timing out. Server-observed
  packet loss of at least 2% or server frame overruns also suspend music delivery.
  Five healthy seconds are required before recovery. Cached playback can continue
  with at most two voices under ordinary client pressure. Frame time over 80 ms
  sustained for two seconds releases the score and its subscription; recovery
  resubscribes without replaying a missed fanfare.
- The server caches compressed playback plans once per immutable plan, omits
  operator-only selection inventory, and sends 1 KiB plan pieces. Its music pass
  has a 4 KiB aggregate metadata allowance and a 0.5 ms scheduling budget every
  0.2 seconds, with round-robin fairness. The time budget is checked between
  listeners; an individual synchronous operation cannot be preempted. Unchanged
  state requires neither JSON serialization nor packets. Stair weights enter
  state in 5% increments and the client smooths gains.

These are application-level scheduling and shedding rules. They do not control
a player's router or preempt unrelated engine work. The HTTPS example also caps
aggregate active media responses and connection rates. On a constrained shared
uplink, reserve capacity for game traffic with host/router QoS or put media on a
separate host/CDN. Native contention testing remains necessary before deployment.

## Prepare an existing media host

New imports automatically publish immutable chunk objects at
`/music/chunks/<sha256>/<index>.dat` before registering delivery version 1.
For an existing catalog, run this offline on the operator host with its actual
origin and paths:

```bash
python3 tools/music/catalog_service.py --root /srv/lod-music --origin https://music.example.org --game-data /srv/gmod/garrysmod/data/legend_of_deborah/music --prepare-delivery
```

Serve the new static path using the updated `tools/music/nginx.example.conf`.
Chunk preparation preserves the original recordings, hashes, role sources and
cue maps. Existing active/offered plans stay frozen; reload and start a new
campaign for the enriched metadata. A legacy asset without prepared delivery
fails quietly with a diagnostic; there is no uncontrolled whole-file URL fallback.
Offline preparation may leave unreferenced immutable chunk files after an
interrupted import; it never registers a partially prepared asset.

A cold recording must finish downloading and verify before it starts. For a
large track or poor connection this can take time; cached music or gameplay
ambience continues. No gameplay event waits. This source change does not deploy
the media service, alter a public server, or update the Workshop.

## Finite native acceptance

After preparing the host, installing the exact source and starting a new
campaign on `gm_flatgrass`, use:

```text
lod_music_reload; lod_music_enabled 1; lod_music_status; lod_music_client_status
```

Listen to first staging, post-fanfare → next staging and portal deployment.
Confirm Chill continuity, pulse/quiet renewal and one-shot fanfare behavior.
With two clients, turn one client's music Off (also test zero volume): its media
access log must stop after at most one outstanding chunk, while the other client
continues. Re-enable on a warm cache and confirm zero repeat media requests.
Exercise a slow/lossy connection and a client slowdown: gameplay continues while
music downloads suspend; severe overload releases playback and then recovers.
Include cold simultaneous joins, stairs, role changes, Off during requests,
server Off, failure/reset, unavailable chunks and an unprepared legacy catalog.

Record frame time, gameplay latency, packet loss, memory, media ingress/egress
and `lod_music_client_status` diagnostics on Steam Deck. Headless operation
counts prove scheduling/bounds, not FPS, audio seams or real-network QoS.
Capture `console_latest.txt` + `rpg_summary_latest.txt`. Keep the release order:
local native acceptance → Workshop parity → matching VPS.

Native contracts: [PlayFile](https://wiki.facepunch.com/gmod/sound.PlayFile),
[HTTP](https://wiki.facepunch.com/gmod/Global.HTTP),
[buffered time](https://wiki.facepunch.com/gmod/IGModAudioChannel:GetBufferedTime),
[real frame time](https://wiki.facepunch.com/gmod/engine.AbsoluteFrameTime),
[server-observed packet loss](https://wiki.facepunch.com/gmod/Player:PacketLoss).
