#!/usr/bin/env python3
"""Generate Deborah's original Hero of Legend launch cue.

The sound is synthesized from oscillators and deterministic noise. It contains
no samples from the gameplay reference or any other recording.
"""

from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path


SAMPLE_RATE = 44_100
DURATION = 0.64
SEED = 0xDEB0A4


def clamp(value: float) -> float:
    return max(-0.98, min(0.98, value))


def envelope(time: float) -> float:
    if time < 0.012:
        return time / 0.012
    if time < 0.12:
        return 1.0 - 0.28 * ((time - 0.012) / 0.108)
    if time < 0.19:
        return 0.72 - 0.54 * ((time - 0.12) / 0.07)
    if time < 0.25:
        return 0.18 + 0.64 * ((time - 0.19) / 0.06)
    return 0.82 * math.exp(-5.2 * (time - 0.25))


def synthesize() -> list[int]:
    rng = random.Random(SEED)
    samples: list[int] = []
    phase_a = phase_b = phase_c = 0.0
    previous_noise = 0.0

    for index in range(round(SAMPLE_RATE * DURATION)):
        time = index / SAMPLE_RATE
        progress = time / DURATION
        # A fast upward spark becomes a descending, lightly warbling magical arc.
        frequency_a = 2140.0 - 1120.0 * progress + 105.0 * math.sin(2 * math.pi * 13 * time)
        frequency_b = 1060.0 + 520.0 * math.exp(-7.0 * time)
        frequency_c = 3280.0 - 1760.0 * progress
        phase_a += 2 * math.pi * frequency_a / SAMPLE_RATE
        phase_b += 2 * math.pi * frequency_b / SAMPLE_RATE
        phase_c += 2 * math.pi * frequency_c / SAMPLE_RATE

        raw_noise = rng.uniform(-1.0, 1.0)
        bright_noise = raw_noise - 0.72 * previous_noise
        previous_noise = raw_noise
        attack_noise = bright_noise * math.exp(-32.0 * time)
        metallic = math.sin(phase_a) + 0.42 * math.sin(phase_c)
        chime = math.sin(phase_b) * (0.58 + 0.42 * math.sin(2 * math.pi * 24 * time))
        value = envelope(time) * (0.43 * metallic + 0.24 * chime + 0.25 * attack_noise)
        samples.append(round(clamp(value) * 32767))
    return samples


def main() -> None:
    repo = Path(__file__).resolve().parents[2]
    destination = repo / "gamemodes/legend_of_deborah/content/sound/lod/hero_of_legend_launch.wav"
    destination.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(destination), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(SAMPLE_RATE)
        output.writeframes(b"".join(struct.pack("<h", sample) for sample in synthesize()))
    print(destination)


if __name__ == "__main__":
    main()
