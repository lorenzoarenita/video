# A small multi-sample instrument player: Salamander Grand Piano + VSCO-2 Community Edition.
import os, re, glob, numpy as np, soundfile as sf
from functools import lru_cache
SR = 48000
NOTE = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5, "F#": 6, "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11}
def midi(name):
    m = re.match(r"([A-G]#?)(-?\d)", name); return NOTE[m.group(1)] + 12 * (int(m.group(2)) + 1)

SAL = "/opt/assets/SalamanderGrandPiano/Samples"
VS = "/opt/assets/VSCO-2-CE"
INSTR = {
    # name: (glob, regex for note & layer, attack, release, gain)
    "piano":   (SAL + "/*v*.flac", r"/([A-G]#?\d)v(\d+)\.flac$", 0.0, 0.5, 1.0),
    "violins": (VS + "/Strings/Violin Section/susVib/*.wav", r"_([A-G]#?\d)_v(\d)", 0.35, 1.2, 0.8),
    "violas":  (VS + "/Strings/Viola Section/susvib/*.wav", r"_([A-G]#?\d)_v(\d)", 0.35, 1.2, 0.8),
    "celli":   (VS + "/Strings/Cello Section/susvib/*.wav", r"_([A-G]#?\d)_v(\d)", 0.3, 1.2, 0.9),
    "bass":    (VS + "/Strings/Solo Contrabass/SusVib/*.wav", r"_([A-G]#?\d)_v(\d)", 0.25, 1.0, 0.9),
    "flute":   (VS + "/Woodwinds/Flute/susvib/*.wav", r"_([A-G]#?\d)_v(\d)", 0.12, 0.6, 0.7),
    "clarinet":(VS + "/Woodwinds/Clarinet/susLong/*.wav", r"_([A-G]#?\d)_v(\d)", 0.1, 0.5, 0.7),
    "harp":    (VS + "/Strings/Harp/*.wav", r"_([A-G]#?\d)_(mf|f|mp|p)", 0.0, 2.0, 0.7),
    "solovln": (VS + "/Strings/Solo Violin/Arco Vib/*.wav", r"_([A-G]#?\d)_(f|p)", 0.25, 0.8, 0.6),
}
LAYER = {"p": 1, "mp": 2, "mf": 3, "f": 4}
# VSCO-2 names sustained samples one octave below sounding pitch (measured)
OCT = {"violins": 12, "violas": 12, "celli": 12, "bass": 12, "flute": 12, "clarinet": 12}

@lru_cache(None)
def index(inst):
    g, rx, *_ = INSTR[inst]
    out = {}
    for f in glob.glob(g):
        m = re.search(rx, f)
        if not m: continue
        n = midi(m.group(1)) + OCT.get(inst, 0); lay = m.group(2)
        lay = LAYER.get(lay, None) or int(lay)
        out.setdefault(n, []).append((lay, f))
    for n in out: out[n].sort()
    return out

@lru_cache(512)
def load(f):
    a, sr = sf.read(f, dtype="float32", always_2d=True)
    if sr != SR:
        x = np.arange(0, len(a), sr / SR)
        a = np.stack([np.interp(x, np.arange(len(a)), a[:, c]) for c in range(a.shape[1])], 1).astype(np.float32)
    if a.shape[1] == 1: a = np.repeat(a, 2, 1)
    return a

def pick(inst, n, vel):
    idx = index(inst)
    keys = np.array(sorted(idx))
    k = keys[np.argmin(np.abs(keys - n) + (keys > n) * 0.1)]
    layers = idx[k]
    i = min(int(vel * len(layers)), len(layers) - 1)
    return k, layers[i][1]

def note(inst, n, vel, dur, attack=None, release=None):
    """Render one note -> stereo float32 array of length dur+release."""
    _, _, att, rel, gain = INSTR[inst]
    att = att if attack is None else attack
    rel = rel if release is None else release
    k, f = pick(inst, n, vel)
    a = load(f)
    ratio = 2 ** ((n - k) / 12)
    L = int((dur + rel) * SR)
    need = L * ratio
    src = a
    if need > len(a) - 10 and inst != "piano" and inst != "harp":
        # loop sustained samples with crossfades from 30% to 85% of the sample
        lo, hi = int(len(a) * .3), int(len(a) * .85); xf = int(.25 * SR)
        seg = a[lo:hi]; out = [a[:hi]]
        while sum(len(o) for o in out) < need + SR:
            prev = out[-1]
            fade = np.linspace(0, 1, xf)[:, None]
            prev[-xf:] = prev[-xf:] * (1 - fade) + seg[:xf] * fade
            out.append(seg[xf:].copy())
        src = np.concatenate(out)
    x = np.arange(L) * ratio
    x = x[x < len(src) - 1]
    i0 = x.astype(int); fr = (x - i0)[:, None]
    y = src[i0] * (1 - fr) + src[i0 + 1] * fr
    env = np.ones(len(y), np.float32)
    na = int(att * SR)
    if na > 0: env[:na] = np.linspace(0, 1, na) ** 1.5
    nd = int(dur * SR); nr = len(y) - nd
    if nr > 0: env[nd:] *= np.exp(-np.linspace(0, 6, nr))
    gv = (0.25 + 0.75 * vel) if inst != "piano" else 1.0
    return (y * env[:, None] * gain * gv).astype(np.float32)

class Track:
    def __init__(self, seconds):
        self.buf = np.zeros((int(seconds * SR) + SR * 4, 2), np.float32)
    def add(self, t, a, gain=1.0, pan=0.0):
        i = int(t * SR)
        if i < 0: a = a[-i:]; i = 0
        j = min(i + len(a), len(self.buf))
        if j <= i: return
        g = np.array([np.cos((pan + 1) * np.pi / 4), np.sin((pan + 1) * np.pi / 4)]) * np.sqrt(2) * gain
        self.buf[i:j] += a[: j - i] * g[None, :]
    def play(self, t, inst, n, vel, dur, gain=1.0, pan=0.0, **kw):
        if isinstance(n, str): n = midi(n)
        self.add(t, note(inst, n, vel, dur, **kw), gain, pan)
