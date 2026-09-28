"""Offline pulse-first cue analysis. Never imported by the game runtime.

The declared tempo/phase supplies the grid; this is a conservative transient
heuristic, not a tempo estimator or a semantic music classifier. Authors can
replace its output with auditioned cues. Only compact intervals reach GMod.
"""
import math
import subprocess

MAX_CUES = 8
MIN_SECTION = 4.0


def mode_for_role(role):
    return 'quiet' if role in ('T0', 'INTERLUDE') else 'pulse'


def validate_cues(cues, duration, bpm, phase):
    def need(ok):
        if not ok:
            raise ValueError('invalid section cues: use finite bar-aligned intervals of at least four seconds')
    need(isinstance(cues, dict) and set(cues) == {'version', 'source', 'pulse', 'quiet'})
    need(cues['version'] == 1 and cues['source'] in ('analyzed-v1', 'authored'))
    bar = 240 / bpm
    for mode in ('pulse', 'quiet'):
        items = cues[mode]
        need(isinstance(items, list) and len(items) <= MAX_CUES)
        previous = -1
        for item in items:
            need(isinstance(item, dict) and set(item) == {'start', 'finish', 'energy'})
            start, finish, energy = (item[k] for k in ('start', 'finish', 'energy'))
            need(all(type(v) in (int, float) and math.isfinite(v) for v in (start, finish, energy)))
            need(0 <= start < finish <= duration + .001 and finish - start >= MIN_SECTION - .001 and 0 <= energy <= 1)
            need(start > previous)
            need(abs((start - phase) / bar - round((start - phase) / bar)) < .001)
            need(abs((finish - phase) / bar - round((finish - phase) / bar)) < .001)
            previous = start
    need(bool(cues['pulse'] or cues['quiet']))
    # Contradictory classifications cannot describe the same audio interval.
    for pulse in cues['pulse']:
        for quiet in cues['quiet']:
            need(min(pulse['finish'], quiet['finish']) <= max(pulse['start'], quiet['start']) + .001)
    return cues


def analyze_samples(samples, sample_rate, duration, bpm, phase=0):
    import numpy as np
    samples = np.asarray(samples, dtype=np.float64)
    if not np.isfinite(samples).all() or not len(samples):
        raise ValueError('nonfinite/empty audio')
    hop = max(1, round(sample_rate * .01))
    usable = len(samples) // hop * hop
    envelope = np.sqrt(np.mean(samples[:usable].reshape(-1, hop) ** 2, axis=1))
    attack = np.maximum(0, np.diff(envelope, prepend=envelope[0]))
    step = hop / sample_rate
    beat, bar = 60 / bpm, 240 / bpm
    rows = []
    for i in range(max(0, int((duration - phase + .001) / bar))):
        start, finish = phase + i * bar, phase + (i + 1) * bar
        lo, hi = round(start / step), min(len(envelope), round(finish / step))
        env = envelope[lo:hi]
        if not len(env):
            continue
        rms = float(np.sqrt(np.mean(env ** 2)))
        # A loud continuous pad has no regular attacks. A single impact cannot
        # qualify a bar: at least three of its four beats need an audible onset.
        offsets = []
        for j in range(4):
            a = max(0, round((start + j * beat - .03) / step))
            b = min(len(attack), round((start + (j + 1) * beat - .03) / step))
            if b > a and float(np.max(attack[a:b])) > max(.002, rms * .18):
                onset = a + int(np.argmax(attack[a:b]))
                offsets.append(((onset * step - start) / beat) % 1)
        # Random impacts/noise distributed through every beat-sized window do
        # not establish a musical pulse: attacks must recur at a stable phase.
        coherence = abs(sum(np.exp(2j*np.pi*v) for v in offsets) / len(offsets)) if offsets else 0
        classification = len(offsets) >= 3 and coherence >= .72
        rows.append((start, finish, rms, classification if rms >= .003 else None))
    if not rows or max(row[2] for row in rows) < .003:
        raise ValueError('no useful audible sections; supply auditioned authored cues')
    peak = max(row[2] for row in rows)
    result = dict(version=1, source='analyzed-v1', pulse=[], quiet=[])
    index = 0
    while index < len(rows):
        end = index + 1
        while end < len(rows) and rows[end][3] == rows[index][3]:
            end += 1
        if rows[index][3] is None:
            index = end
            continue
        mode = 'pulse' if rows[index][3] else 'quiet'
        # Keep each entire contiguous safe run; provide alternate interior entry
        # points without crossing even a one-bar rhythmic dropout.
        stride = max(1, math.ceil(8 / bar))
        starts = list(range(index, end, stride))
        if mode == 'pulse' and end - index > stride:
            starts = list(range(index + 1, end, stride))
        for k in starts:
            if rows[end - 1][1] - rows[k][0] < MIN_SECTION - .001:
                continue
            result[mode].append(dict(start=round(rows[k][0], 6), finish=round(rows[end - 1][1], 6),
                                     energy=round(sum(r[2] for r in rows[k:end]) / (end - k) / peak, 6)))
        index = end
    for mode in ('pulse', 'quiet'):
        entries = result[mode]
        if len(entries) > MAX_CUES:
            # Spread entries through the whole recording, including its outro.
            result[mode] = [entries[round(i * (len(entries) - 1) / (MAX_CUES - 1))] for i in range(MAX_CUES)]
    return validate_cues(result, duration, bpm, phase)


def analyze_file(path, duration, bpm, phase=0):
    import numpy as np
    # Bounded by the already-validated 180-second master. Low-rate mono PCM is
    # transient author/ingestion memory, never a client payload or cache.
    raw = subprocess.check_output(['ffmpeg', '-v', 'error', '-xerror', '-i', str(path),
        '-t', str(duration), '-ac', '1', '-ar', '11025', '-f', 'f32le', '-'], timeout=30)
    return analyze_samples(np.frombuffer(raw, dtype='<f4'), 11025, duration, bpm, phase)
