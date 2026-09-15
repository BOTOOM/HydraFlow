from pathlib import Path
import math
import subprocess
import wave as wave_module

import numpy as np


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "sounds"
ANDROID_OUT = ROOT / "android" / "app" / "src" / "main" / "res" / "raw"
IOS_OUT = ROOT / "ios" / "Runner"
RATE = 44_100
TAU = 2 * math.pi
RNG = np.random.default_rng(20250915)


def _biquad(signal, b0, b1, b2, a1, a2):
    output = np.empty_like(signal, dtype=np.float64)
    x1 = x2 = y1 = y2 = 0.0
    for index, sample in enumerate(signal):
        value = b0 * sample + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        output[index] = value
        x2, x1 = x1, sample
        y2, y1 = y1, value
    return output


def _filter_coefficients(kind, frequency, q=0.707):
    omega = TAU * frequency / RATE
    sine = math.sin(omega)
    cosine = math.cos(omega)
    alpha = sine / (2 * q)
    if kind == "lowpass":
        b0, b1, b2 = (1 - cosine) / 2, 1 - cosine, (1 - cosine) / 2
    elif kind == "highpass":
        b0, b1, b2 = (1 + cosine) / 2, -(1 + cosine), (1 + cosine) / 2
    elif kind == "bandpass":
        b0, b1, b2 = sine / 2, 0.0, -sine / 2
    else:
        raise ValueError(f"unknown filter kind: {kind}")
    a0, a1, a2 = 1 + alpha, -2 * cosine, 1 - alpha
    return tuple(value / a0 for value in (b0, b1, b2, a1, a2))


def lowpass(signal, frequency, q=0.707):
    return _biquad(signal, *_filter_coefficients("lowpass", frequency, q))


def highpass(signal, frequency, q=0.707):
    return _biquad(signal, *_filter_coefficients("highpass", frequency, q))


def bandpass(signal, frequency, q=1.2):
    return _biquad(signal, *_filter_coefficients("bandpass", frequency, q))


def envelope(length, attack=0.02, release=0.02):
    result = np.ones(length)
    attack_samples = min(length // 2, int(RATE * attack))
    release_samples = min(length // 2, int(RATE * release))
    if attack_samples:
        result[:attack_samples] = np.linspace(0, 1, attack_samples)
    if release_samples:
        result[-release_samples:] = np.linspace(1, 0, release_samples)
    return result


def chirp(start_hz, end_hz, seconds, decay=0.0):
    length = max(1, int(RATE * seconds))
    time = np.arange(length) / RATE
    phase = TAU * (start_hz * time + (end_hz - start_hz) * time * time / (2 * seconds))
    result = np.sin(phase)
    if decay:
        result *= np.exp(-decay * time)
    return result


def delayed_reverb(signal, delays=(0.065, 0.135, 0.225), gains=(0.2, 0.12, 0.07)):
    result = np.array(signal, dtype=np.float64, copy=True)
    for delay, gain in zip(delays, gains):
        samples = int(RATE * delay)
        result[samples:] += signal[:-samples] * gain
    return result


def finish(signal, attack=0.02, release=0.02, reverb=True):
    signal = np.asarray(signal, dtype=np.float64)
    if reverb:
        signal = delayed_reverb(signal)
    signal *= envelope(len(signal), attack, release)
    peak = np.max(np.abs(signal))
    if peak:
        signal *= 0.8 / peak
    return signal


def insert(target, source, start):
    start = int(start)
    if start >= len(target):
        return
    end = min(len(target), start + len(source))
    target[start:end] += source[: end - start]


def variable_bandpass(signal, starts, ends=None, q=7.0, block_seconds=0.08):
    output = np.zeros_like(signal)
    block = max(1, int(RATE * block_seconds))
    if ends is None:
        centers = np.asarray(starts)
    else:
        centers = np.linspace(starts, ends, len(signal))
    for start in range(0, len(signal), block):
        end = min(len(signal), start + block)
        center = centers[min(start, len(centers) - 1)]
        output[start:end] = bandpass(signal[start:end], center, q)
    return output


def rain():
    seconds = 2.4
    length = int(RATE * seconds)
    white = RNG.normal(0, 1, length)
    bed = 0.7 * lowpass(white, 4000) + 0.3 * lowpass(RNG.normal(0, 1, length), 900)
    result = bed * (0.13 + 0.05 * np.sin(np.pi * np.arange(length) / length))
    count = int(RNG.integers(int(60 * seconds), int(120 * seconds) + 1))
    for _ in range(count):
        start = int(RNG.integers(0, length - int(RATE * 0.015)))
        drop_length = int(RNG.uniform(0.005, 0.015) * RATE)
        drop = bandpass(RNG.normal(0, 1, drop_length), RNG.uniform(2000, 6000), 1.5)
        drop *= np.exp(-np.linspace(0, 6, drop_length))
        insert(result, drop * RNG.uniform(0.18, 0.42), start)
    return finish(result, 0.02, 0.08)


def faucet():
    seconds = 1.8
    length = int(RATE * seconds)
    time = np.arange(length) / RATE
    stream = bandpass(RNG.normal(0, 1, length), 1900, 0.8)
    lfo_rate = RNG.uniform(6, 9)
    turbulence = 0.72 + 0.22 * np.sin(TAU * lfo_rate * time + RNG.uniform(0, TAU))
    turbulence += lowpass(RNG.normal(0, 1, length), 12) * 0.05
    hiss = lowpass(highpass(RNG.normal(0, 1, length), 4000, 0.8), 7500)
    result = stream * turbulence * 0.22 + hiss * 0.02
    return finish(result, 0.15, 0.07)


def pouring():
    seconds = 2.1
    length = int(RATE * seconds)
    time = np.arange(length) / RATE
    stream = bandpass(RNG.normal(0, 1, length), 1700, 0.85)
    turbulence = 0.68 + 0.2 * np.sin(TAU * 7.2 * time)
    resonance = variable_bandpass(RNG.normal(0, 1, length), 400, 1400, q=5.5)
    result = stream * turbulence * 0.13 + resonance * (0.06 + 0.08 * time / seconds)
    for _ in range(10):
        start = int(RNG.uniform(0.1, seconds - 0.12) * RATE)
        bubble = chirp(RNG.uniform(260, 420), RNG.uniform(700, 1100), RNG.uniform(0.035, 0.08), 12)
        insert(result, bubble * RNG.uniform(0.035, 0.07), start)
    return finish(result, 0.15, 0.08)


def drops():
    seconds = 1.9
    length = int(RATE * seconds)
    result = np.zeros(length)
    for start in sorted(RNG.uniform(0.12, seconds - 0.35, int(RNG.integers(3, 5)))):
        start_index = int(start * RATE)
        click = chirp(RNG.uniform(1800, 2300), RNG.uniform(450, 650), 0.06, 4)
        click *= envelope(len(click), 0.002, 0.02)
        bloop = chirp(RNG.uniform(350, 450), RNG.uniform(520, 650), 0.15, 12)
        bloop *= envelope(len(bloop), 0.004, 0.08)
        tiny_length = int(RATE * 0.006)
        tiny_click = RNG.normal(0, 1, tiny_length) * np.exp(-np.linspace(0, 8, tiny_length))
        insert(result, click * 0.3, start_index)
        insert(result, bloop * 0.5, start_index + int(RATE * 0.035))
        insert(result, tiny_click * 0.08, start_index)
    return finish(result, 0.02, 0.12)


def bubbles():
    seconds = 1.7
    length = int(RATE * seconds)
    result = lowpass(RNG.normal(0, 1, length), 850) * 0.018
    for _ in range(int(RNG.integers(8, 13))):
        start = int(RNG.uniform(0, seconds - 0.09) * RATE)
        duration = RNG.uniform(0.04, 0.09)
        bubble = chirp(RNG.uniform(300, 900), RNG.uniform(700, 1800), duration, 18)
        bubble *= envelope(len(bubble), 0.005, 0.015)
        insert(result, bubble * RNG.uniform(0.08, 0.17), start)
    return finish(result, 0.02, 0.08)


def brook():
    seconds = 2.3
    length = int(RATE * seconds)
    time = np.arange(length) / RATE
    result = np.zeros(length)
    for center, amount in ((600, 0.1), (1200, 0.08), (2400, 0.055)):
        wandering = center * (1 + 0.09 * np.sin(TAU * RNG.uniform(0.18, 0.42) * time + RNG.uniform(0, TAU)))
        filtered = variable_bandpass(RNG.normal(0, 1, length), wandering, q=1.5)
        result += filtered * amount
    result += lowpass(RNG.normal(0, 1, length), 420) * 0.035
    for _ in range(8):
        start = int(RNG.uniform(0.1, seconds - 0.1) * RATE)
        gurgle = chirp(RNG.uniform(180, 300), RNG.uniform(350, 650), RNG.uniform(0.06, 0.13), 10)
        insert(result, gurgle * RNG.uniform(0.025, 0.06), start)
    return finish(result, 0.04, 0.1)


def wave():
    seconds = 2.2
    length = int(RATE * seconds)
    time = np.arange(length) / RATE
    swell = np.sin(np.pi * time / seconds) ** 0.72
    body = lowpass(RNG.normal(0, 1, length), 1100) * 0.17 * swell
    crest = lowpass(highpass(RNG.normal(0, 1, length), 2200), 6000) * 0.05
    crest *= np.exp(-((time - seconds * 0.47) / 0.23) ** 2)
    return finish(body + crest, 0.02, 0.14)


def bell():
    length = int(RATE * 1.9)
    result = np.zeros(length)
    base = 620
    partials = ((1.0, 1.0, 3.0), (2.0, 0.52, 3.8), (2.76, 0.31, 4.5), (3.9, 0.2, 5.2), (5.4, 0.11, 6.1))
    for strike, amplitude in ((0.0, 1.0), (0.54, 0.6)):
        time = np.arange(length - int(strike * RATE)) / RATE
        note = np.zeros_like(time)
        for multiple, partial_amplitude, decay in partials:
            note += partial_amplitude * np.sin(TAU * base * multiple * time) * np.exp(-decay * time)
        insert(result, note * amplitude, int(strike * RATE))
    return finish(result, 0.008, 0.22)


def marimba():
    length = int(RATE * 2.0)
    result = np.zeros(length)
    for start, frequency in zip((0.0, 0.52, 1.02), (523, 659, 784)):
        duration = 0.7
        time = np.arange(int(duration * RATE)) / RATE
        note = (
            np.sin(TAU * frequency * time) * np.exp(-4.6 * time)
            + np.sin(TAU * frequency * 4 * time) * 0.22 * np.exp(-7.5 * time)
        )
        mallet = highpass(RNG.normal(0, 1, len(time)), 2500) * 0.06 * np.exp(-35 * time)
        insert(result, note + mallet, int(start * RATE))
    return finish(result, 0.006, 0.22)


def splash():
    length = int(RATE * 0.4)
    time = np.arange(length) / RATE
    plop = chirp(420, 180, 0.18, 8) * 0.5
    hiss = highpass(RNG.normal(0, 1, length), 3200) * 0.16 * np.exp(-8 * time)
    result = hiss
    insert(result, plop, int(0.015 * RATE))
    return finish(result, 0.008, 0.08)


def save_and_convert(name, samples):
    wav_path = OUT / f"{name}.wav"
    ogg_path = OUT / f"{name}.ogg"
    caf_path = IOS_OUT / f"{name}.caf"
    samples = np.asarray(samples, dtype=np.float64)
    with wave_module.open(str(wav_path), "wb") as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(RATE)
        wav_file.writeframes((np.clip(samples, -1, 1) * 32767).astype(np.int16).tobytes())
    subprocess.run(
        ["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav_path), "-ac", "1", "-ar", str(RATE), str(ogg_path)],
        check=True,
    )
    subprocess.run(
        ["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav_path), "-ac", "1", "-ar", str(RATE), str(caf_path)],
        check=True,
    )
    (ANDROID_OUT / f"{name}.ogg").write_bytes(ogg_path.read_bytes())
    wav_path.unlink()


def print_metrics(name, samples):
    rms = float(np.sqrt(np.mean(np.square(samples))))
    spectrum = np.abs(np.fft.rfft(samples))
    frequencies = np.fft.rfftfreq(len(samples), 1 / RATE)
    centroid = float(np.sum(frequencies * spectrum) / max(np.sum(spectrum), 1e-12))
    print(f"{name:10s} duration={len(samples) / RATE:.3f}s rms={rms:.4f} centroid={centroid:.1f}Hz")


for stale in ("gota", "vertido"):
    for path in (OUT / f"{stale}.ogg", ANDROID_OUT / f"{stale}.ogg", IOS_OUT / f"{stale}.caf"):
        path.unlink(missing_ok=True)

sounds = {
    "lluvia": rain(),
    "grifo": faucet(),
    "chorro": pouring(),
    "gotas": drops(),
    "burbujas": bubbles(),
    "arroyo": brook(),
    "ola": wave(),
    "campanita": bell(),
    "marimba": marimba(),
    "splash": splash(),
}

for sound_name, samples in sounds.items():
    save_and_convert(sound_name, samples)
    print_metrics(sound_name, samples)
