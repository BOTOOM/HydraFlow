from pathlib import Path
import math
import wave
import subprocess
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "sounds"
OUT.mkdir(parents=True, exist_ok=True)
RATE = 44100

def tone(freq, seconds, decay=4, sweep=None):
    t = np.arange(int(RATE * seconds)) / RATE
    if sweep:
        phase = 2 * np.pi * (sweep[0] * t + (sweep[1] - sweep[0]) * t * t / (2 * seconds))
        wave_ = np.sin(phase)
    else:
        wave_ = np.sin(2 * np.pi * freq * t)
    return wave_ * np.exp(-decay * t)

def save_wav(name, samples):
    samples = np.clip(samples * .45, -1, 1)
    with wave.open(str(OUT / f"{name}.wav"), "wb") as f:
        f.setnchannels(1); f.setsampwidth(2); f.setframerate(RATE)
        f.writeframes((samples * 32767).astype(np.int16).tobytes())

def convert(name):
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(OUT / f"{name}.wav"), str(OUT / f"{name}.ogg")], check=True)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(OUT / f"{name}.wav"), "-ar", "44100", str(ROOT / "ios" / "Runner" / f"{name}.caf")], check=True)
    (ROOT / "android" / "app" / "src" / "main" / "res" / "raw" / f"{name}.ogg").write_bytes((OUT / f"{name}.ogg").read_bytes())

def overlay(*items):
    length = max(len(item) for item in items)
    result = np.zeros(length)
    for item in items:
        result[:len(item)] += item
    return result

sounds = {
    "gota": tone(0, .45, 7, (1200, 400)),
    "burbujas": np.concatenate([tone(550 + i * 120, .16, 14) for i in range(4)]),
    "vertido": np.random.default_rng(3).normal(0, .18, int(RATE * .8)) * np.linspace(0, 1, int(RATE * .8)),
    "campanita": overlay(tone(880, .65, 4), np.pad(tone(1320, .5, 5), (int(RATE * .12), 0))),
    "marimba": overlay(tone(523, .45, 5), np.pad(tone(659, .4, 5), (int(RATE * .16), 0)), np.pad(tone(784, .35, 5), (int(RATE * .3), 0))),
    "splash": tone(500, .25, 9, (900, 300)),
}
for name, data in sounds.items():
    save_wav(name, data)
    convert(name)
