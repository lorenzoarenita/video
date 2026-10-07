# Synthesize every line with Kokoro (local), then pitch-shift / resample with sox.
import os, subprocess, soundfile as sf, numpy as np, sys
from kokoro_onnx import Kokoro
from lines import LINES, VOICES
OUT = os.path.join(os.path.dirname(__file__), "..", "build", "voice"); os.makedirs(OUT, exist_ok=True)
k = Kokoro("/opt/assets/kokoro/kokoro-v1.0.onnx", "/opt/assets/kokoro/voices-v1.0.bin")
only = set(sys.argv[1:])
for lid, shot, t, ch, text, fx in LINES:
    if only and lid not in only: continue
    voice, speed, semi, extra = VOICES[ch]
    parts = [p.strip() for p in text.split("...") if p.strip()]
    chunks = []
    for i, part in enumerate(parts):
        if i < len(parts) - 1 and part[-1] not in ".?!,": part = part + "..."
        a, sr = k.create(part, voice=voice, speed=speed, lang="es")
        a = np.trim_zeros(np.where(np.abs(a) < 2e-3, 0, a)) if False else a
        chunks.append(a)
        if i < len(parts) - 1: chunks.append(np.zeros(int(sr * 0.55 / speed)))
    s = np.concatenate(chunks)
    raw = f"{OUT}/{lid}_raw.wav"; sf.write(raw, s, sr)
    eff = ["pitch", str(int(semi * 100))] if abs(semi) > 0.01 else []
    if extra.get("tremolo"): eff += ["tremolo", "5", str(int(extra["tremolo"] * 100 * 3))]
    subprocess.run(["sox", raw, "-r", "48000", f"{OUT}/{lid}.wav"] + eff + ["rate", "-v", "48000", "silence", "1", "0.01", "0.2%", "reverse", "silence", "1", "0.01", "0.2%", "reverse"], check=True)
    d = sf.info(f"{OUT}/{lid}.wav").duration
    print(f"{lid} {ch:10s} {d:5.2f}s  {text}")
