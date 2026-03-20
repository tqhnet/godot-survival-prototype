#!/usr/bin/env python3
"""生成占位 WAV（正弦/噪声），供 Godot 导入。运行: python3 tools/gen_placeholder_audio.py"""
from __future__ import annotations

import math
import os
import struct
import wave

OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "audio")
SAMPLE_RATE = 22050


def _clip_i16(x: float) -> int:
    return int(max(-32768, min(32767, x)))


def write_mono(path: str, samples: list[int]) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        for s in samples:
            w.writeframes(struct.pack("<h", s))


def gen_shoot() -> list[int]:
    # 短促高频 + 衰减噪声
    dur = 0.055
    n = int(SAMPLE_RATE * dur)
    out: list[int] = []
    for i in range(n):
        t = i / SAMPLE_RATE
        e = math.exp(-t * 55.0)
        s = 0.0
        s += math.sin(2 * math.pi * 920 * t) * 0.55
        s += math.sin(2 * math.pi * 1840 * t) * 0.22
        # 伪随机噪声
        s += math.sin(2 * math.pi * 133.7 * t) * math.sin(2 * math.pi * 9911 * t) * 0.15
        out.append(_clip_i16(s * e * 0.42 * 32767))
    return out


def gen_enemy_shoot() -> list[int]:
    dur = 0.07
    n = int(SAMPLE_RATE * dur)
    out: list[int] = []
    for i in range(n):
        t = i / SAMPLE_RATE
        e = math.exp(-t * 38.0)
        s = math.sin(2 * math.pi * 420 * t) * 0.55 + math.sin(2 * math.pi * 210 * t) * 0.25
        out.append(_clip_i16(s * e * 0.38 * 32767))
    return out


def gen_hurt() -> list[int]:
    dur = 0.14
    n = int(SAMPLE_RATE * dur)
    out: list[int] = []
    for i in range(n):
        t = i / SAMPLE_RATE
        e = math.exp(-t * 18.0)
        f = 180.0 - 90.0 * (i / n)
        s = math.sin(2 * math.pi * f * t) * 0.7 + math.sin(2 * math.pi * f * 1.5 * t) * 0.2
        out.append(_clip_i16(s * e * 0.45 * 32767))
    return out


def gen_hit() -> list[int]:
    dur = 0.07
    n = int(SAMPLE_RATE * dur)
    out: list[int] = []
    for i in range(n):
        t = i / SAMPLE_RATE
        e = math.exp(-t * 45.0)
        s = math.sin(2 * math.pi * 660 * t) * 0.55
        s += math.sin(2 * math.pi * 1320 * t) * 0.22
        s += (math.sin(2 * math.pi * 77 * t * 77) % 1.0 - 0.5) * 0.35
        out.append(_clip_i16(s * e * 0.4 * 32767))
    return out


def gen_bgm_loop() -> list[int]:
    # ~3.2s 可循环氛围（首尾淡入淡出减轻接缝）
    dur = 3.2
    n = int(SAMPLE_RATE * dur)
    out: list[int] = []
    # A2 附近 + 五度 + 泛音
    freqs = [110.0, 164.81, 220.0, 277.18]
    amps = [0.12, 0.1, 0.08, 0.06]
    for i in range(n):
        t = i / SAMPLE_RATE
        s = 0.0
        for fi, ai in zip(freqs, amps):
            # 慢 LFO
            lfo = 0.85 + 0.15 * math.sin(2 * math.pi * 0.25 * t)
            s += ai * lfo * math.sin(2 * math.pi * fi * t + math.sin(2 * math.pi * 0.08 * t) * 0.4)
        # 淡入淡出
        edge = min(i, n - 1 - i) / (SAMPLE_RATE * 0.12)
        edge = min(1.0, edge)
        s *= edge
        out.append(_clip_i16(s * 0.55 * 32767))
    return out


def main() -> None:
    base = os.path.abspath(OUT_DIR)
    write_mono(os.path.join(base, "sfx_player_shoot.wav"), gen_shoot())
    write_mono(os.path.join(base, "sfx_enemy_shoot.wav"), gen_enemy_shoot())
    write_mono(os.path.join(base, "sfx_player_hurt.wav"), gen_hurt())
    write_mono(os.path.join(base, "sfx_enemy_hit.wav"), gen_hit())
    write_mono(os.path.join(base, "bgm_loop.wav"), gen_bgm_loop())
    print("Wrote WAV files to", base)


if __name__ == "__main__":
    main()
