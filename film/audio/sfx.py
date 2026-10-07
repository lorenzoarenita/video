# Synthesized sound design. Every function returns a stereo float32 array at 48 kHz.
import numpy as np
from scipy import signal
SR = 48000
rng = np.random.default_rng(7)

def secs(d): return int(d * SR)
def st(a, w=0.0):
    """mono -> stereo with optional decorrelation"""
    if a.ndim == 2: return a
    if w <= 0: return np.stack([a, a], 1).astype(np.float32)
    d = int(w * SR / 1000)
    b = np.concatenate([np.zeros(d), a[:-d]]) if d > 0 else a
    return np.stack([a, b], 1).astype(np.float32)
def noise(d): return rng.standard_normal(secs(d)).astype(np.float32)
def pink(d):
    w = noise(d); b, a = signal.butter(1, 400 / (SR / 2)); return signal.lfilter(b, a, w) * 3 + w * .1
def brown(d):
    w = noise(d); x = np.cumsum(w); x -= signal.savgol_filter(x, 4801, 1) if len(x) > 4801 else x.mean(); return x / (np.abs(x).max() + 1e-9)
def lp(a, f, o=2): b, c = signal.butter(o, min(f / (SR / 2), .99)); return signal.lfilter(b, c, a, axis=0)
def hp(a, f, o=2): b, c = signal.butter(o, f / (SR / 2), "high"); return signal.lfilter(b, c, a, axis=0)
def bp(a, f1, f2, o=2): b, c = signal.butter(o, [f1 / (SR / 2), min(f2 / (SR / 2), .99)], "band"); return signal.lfilter(b, c, a, axis=0)
def norm(a, peak=1.): return (a / (np.abs(a).max() + 1e-9) * peak).astype(np.float32)
def env_ad(n, a, d): e = np.ones(n); na = int(a * SR); nd = int(d * SR); e[:na] = np.linspace(0, 1, na) if na else 1;
def fade(a, fi=.05, fo=.05):
    a = a.copy(); n = len(a); ni = min(int(fi * SR), n); no = min(int(fo * SR), n)
    if ni: a[:ni] *= np.linspace(0, 1, ni)[:, None] if a.ndim == 2 else np.linspace(0, 1, ni)
    if no: a[-no:] *= np.linspace(1, 0, no)[:, None] if a.ndim == 2 else np.linspace(1, 0, no)
    return a
def t_(d): return np.arange(secs(d)) / SR

# ---- body --------------------------------------------------------------------
def thump(f0=55, d=.18, drop=.6):
    t = t_(d); f = f0 * (1 + drop * np.exp(-t * 30)); ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(ph) * np.exp(-t * 22) * (1 - np.exp(-t * 400))
def heartbeat(dur, bpm=72, muffle=180, gain=1., bpm_end=None, stop_at=None):
    out = np.zeros(secs(dur)); t = 0.
    while t < dur:
        b = bpm if bpm_end is None else bpm + (bpm_end - bpm) * (t / dur)
        if stop_at and t > stop_at: break
        i = secs(t)
        for off, g, f in [(0, 1, 52), (.28 * 72 / max(b, 30), .65, 62)]:
            s = thump(f) * g; j = i + secs(off)
            if j + len(s) < len(out): out[j:j + len(s)] += s
        t += 60 / b
    out = lp(out, muffle, 3)
    return st(norm(out, gain))
def womb(dur):
    w = lp(brown(dur), 300, 2) * .5
    t = t_(dur); swish = (0.6 + 0.4 * np.sin(2 * np.pi * t * 72 / 60)) ** 2
    s = lp(noise(dur), 500, 2) * swish * .3
    return st(norm(w + s, .5), .4)
def gasp():
    d = 1.2; t = t_(d)
    n = bp(noise(d), 600, 3500, 2) * np.exp(-((t - .35) / .22) ** 2) * 1.2
    n += bp(noise(d), 300, 1200, 2) * np.exp(-((t - .9) / .18) ** 2) * .6
    return st(norm(n, .6), .3)
def breaths(dur, rate=.25, gain=.3, old=False):
    out = np.zeros(secs(dur)); t = .5
    while t < dur - 3:
        per = 1 / rate * (1 + .15 * rng.standard_normal())
        for k, (c, w, lo, hi, g) in enumerate([(.0, .9, 400, 2200, 1.), (1.4, 1.2, 250, 1500, .7)]):
            n = bp(noise(w * 2.5), lo, hi, 2) * np.hanning(secs(w * 2.5)) * g
            if old: n *= 1 + .5 * np.sin(np.arange(len(n)) / SR * 2 * np.pi * 9) * .5
            i = secs(t + c)
            if i + len(n) < len(out): out[i:i + len(n)] += n
        t += per
    return st(norm(out, gain), .2)

# ---- nature ------------------------------------------------------------------
def room(dur, gain=.03): return st(norm(lp(pink(dur), 900, 2), gain), .7)
def wind(dur, gain=.2, bright=900, gust=.08):
    n = noise(dur); t = t_(dur)
    m = 0.6 + 0.4 * np.sin(2 * np.pi * gust * t + 1) * np.sin(2 * np.pi * gust * 1.7 * t)
    a = lp(n, bright, 2) * m
    return st(norm(a, gain), .9)
def leaves(dur, gain=.12):
    n = hp(noise(dur), 1500); t = t_(dur)
    flutter = lp(np.abs(noise(dur)), 12, 2); flutter = flutter / flutter.max()
    m = (0.5 + 0.5 * np.sin(2 * np.pi * .07 * t)) * flutter
    return st(norm(lp(n, 7000) * m, gain), .8)
def chirp_bird(kind=0):
    if kind == 0:  # little warble
        d = .09 + rng.random() * .1; t = t_(d)
        f = 3200 + 1600 * np.sin(2 * np.pi * (8 + rng.random() * 8) * t) + rng.random() * 1500
    else:          # descending whistle
        d = .25; t = t_(d); f = 4200 - 1800 * t / d
    ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(ph) * np.hanning(len(t)) * (.6 + .4 * rng.random())
def birds(dur, density=1.2, gain=.08):
    out = np.zeros(secs(dur)); t = rng.random()
    while t < dur - 1:
        # a phrase of a few chirps
        k = int(rng.random() < .3); n = 2 + int(rng.random() * 5)
        for j in range(n):
            c = chirp_bird(k); i = secs(t + j * (.11 + rng.random() * .05))
            if i + len(c) < len(out): out[i:i + len(c)] += c * (.4 + .6 * rng.random())
        t += rng.exponential(1 / density) + .3
    o = st(out); pan = rng.random()
    o[:, 0] *= .6 + .4 * pan; o[:, 1] *= 1 - .4 * pan
    return norm(o, gain)
def crickets(dur, gain=.05):
    t = t_(dur); out = np.zeros(len(t))
    for k in range(3):
        f = 4300 + k * 350; rate = 14 + k * 3; ph = rng.random() * 6
        pulse = (np.sin(2 * np.pi * rate * t + ph) > .3).astype(float) * (np.sin(2 * np.pi * (.5 + k * .13) * t + ph) > -.2)
        out += np.sin(2 * np.pi * f * t) * lp(pulse, 200, 1) * (.6 + .4 * k / 2)
    return st(norm(out, gain), .5)
def cicadas(dur, gain=.04):
    t = t_(dur); n = bp(noise(dur), 5000, 8000, 2) * (0.6 + 0.4 * np.sin(2 * np.pi * 40 * t)) * (0.7 + 0.3 * np.sin(2 * np.pi * .1 * t))
    return st(norm(n, gain), .4)
def waves(dur, period=7.5, gain=.5):
    t = t_(dur); n = noise(dur); out = np.zeros(len(t))
    ph = (t % period) / period
    swell = np.clip(np.sin(np.pi * ph) ** 2, 0, 1)
    crash = np.exp(-((ph - .55) / .06) ** 2) + .4 * np.exp(-((ph - .62) / .12) ** 2)
    low = lp(n, 400, 2) * swell
    high = bp(n, 800, 6000, 2) * crash * .8
    hiss = hp(n, 2000) * np.exp(-((ph - .75) / .15) ** 2) * .25  # foam withdrawing
    out = low + high + hiss + lp(n, 150, 2) * .5
    return st(norm(out, gain), 1.2)
def gulls(dur, gain=.04):
    out = np.zeros(secs(dur)); t = 1.
    while t < dur - 2:
        d = .5; tt = t_(d); f = 1500 + 900 * np.exp(-tt * 6) - 400 * tt
        s = signal.sawtooth(2 * np.pi * np.cumsum(f) / SR) * np.hanning(len(tt))
        s = bp(s, 900, 3500)
        i = secs(t); out[i:i + len(s)] += s; t += 2 + rng.random() * 5
    return st(norm(out, gain), .6)
def rain(dur, gain=.25, window=True):
    n = noise(dur); bed = bp(n, 300, 6000, 2) * .25
    out = np.zeros(len(n)); k = int(dur * 70)
    for _ in range(k):
        i = rng.integers(0, len(out) - 2000); f = 1800 + rng.random() * 4500; d = 600
        tick = np.sin(2 * np.pi * f * np.arange(d) / SR) * np.exp(-np.arange(d) / 90) * rng.random()
        out[i:i + d] += tick
    if window: out = lp(out, 5000)
    return st(norm(bed + out * .6, gain), 1.)
def thunder_far(gain=.3):
    d = 6; t = t_(d); n = lp(brown(d), 120, 2) * np.exp(-t * .6) * (1 - np.exp(-t * 4))
    return st(norm(n, gain), 2.)

# ---- objects -------------------------------------------------------------------
def shutter():
    d = .25; t = t_(d); n = noise(d)
    c1 = hp(n, 2000) * np.exp(-t * 300)
    c2 = np.zeros_like(c1); j = secs(.065); c2[j:] = (hp(n, 1200) * np.exp(-t * 200))[:len(c2) - j]
    body = np.sin(2 * np.pi * 900 * t) * np.exp(-t * 80) * .3
    return st(norm(c1 + c2 * .8 + body, .7), .1)
def door_slam():
    d = 1.6; t = t_(d); n = noise(d)
    hit = lp(n, 900, 2) * np.exp(-t * 18) + np.sin(2 * np.pi * 60 * t) * np.exp(-t * 10) * 1.2
    rattle = bp(n, 1500, 5000) * np.exp(-((t - .08) / .05) ** 2) * .3
    return st(norm(hit + rattle, .9), .5)
def clock(dur, gain=.05, bpm=60):
    out = np.zeros(secs(dur)); t = 0; k = 0
    while t < dur:
        d = 400; tick = hp(noise(.01), 2500)[:d] * np.exp(-np.arange(d) / 60) * (1 if k % 2 == 0 else .7)
        i = secs(t); out[i:i + d] += tick; t += 60 / bpm; k += 1
    return st(norm(out, gain), .1)
def buzz_phone(dur, period=.625, on=.5, gain=.3, start=0., stop=None):
    t = t_(dur); ph = ((t + 1e-9) % period) / period
    gate = (ph > on).astype(float)
    if stop is not None: gate *= (t >= start) * (t < stop)
    gate = lp(gate, 80, 1)
    b = signal.square(2 * np.pi * 165 * t) * .5 + np.sin(2 * np.pi * 330 * t)
    rattle = bp(noise(dur), 2000, 6000) * .2
    return st(norm(lp(b + rattle, 3000) * gate, gain))
def fluor_hum(dur, gain=.04, flicker=None):
    t = t_(dur); h = sum(np.sin(2 * np.pi * 100 * k * t) / k for k in range(1, 6)) + bp(noise(dur), 2000, 5000) * .1
    return st(norm(h, gain), .3)
def ventilation(dur, gain=.05): return st(norm(lp(pink(dur), 500), gain), .8)
def slosh(dur, gain=.08):
    t = t_(dur); n = bp(noise(dur), 300, 2500); m = (np.sin(2 * np.pi * .95 * t) * .5 + .5) ** 3
    return st(norm(n * m, gain), .4)
def engine(dur, gain=.2, f=38):
    t = t_(dur); s = signal.sawtooth(2 * np.pi * (f + 2 * np.sin(2 * np.pi * .1 * t)) * t)
    return st(norm(lp(s, 180, 2) + lp(noise(dur), 300) * .5, gain), .4)
def beat_music(dur, bpm=96, gain=.25, muffle=1400):
    t = t_(dur); out = np.zeros(len(t)); b = 60 / bpm
    kick = thump(70, .25, 1.5) * 1.2; snare = hp(noise(.2), 900) * np.exp(-t_(.2) * 25); hat = hp(noise(.05), 6000) * np.exp(-t_(.05) * 80) * .4
    n = 0; tt = 0.
    bassline = [41, 41, 44, 39]
    while tt < dur - 1:
        i = secs(tt)
        if n % 4 in (0, 2) or (n % 8 == 7): out[i:i + len(kick)] += kick
        if n % 4 in (1, 3): out[i:i + len(snare)] += snare
        for h in (0, .5): j = secs(tt + h * b); out[j:j + len(hat)] += hat
        f = 440 * 2 ** ((bassline[(n // 4) % 4] - 69 - 12) / 12); bd = secs(b * .9)
        out[i:i + bd] += signal.sawtooth(2 * np.pi * f * np.arange(bd) / SR) * np.exp(-np.arange(bd) / SR * 3) * .3
        # a synth chord stab
        if n % 2 == 0:
            for semi in (0, 3, 7):
                ff = 440 * 2 ** ((bassline[(n // 4) % 4] - 69 + 12 + semi) / 12); cd = secs(b * .4)
                out[i:i + cd] += signal.square(2 * np.pi * ff * np.arange(cd) / SR) * np.exp(-np.arange(cd) / SR * 8) * .06
        tt += b; n += 1
    return st(norm(lp(out, muffle, 2), gain), .3)
def city(dur, gain=.12):
    t = t_(dur); hum = lp(pink(dur), 300) * (1 + .2 * np.sin(2 * np.pi * .05 * t))
    out = hum
    for k in range(3):  # far cars passing
        c = 2 + rng.random() * (dur - 6); w = 3 + rng.random() * 3
        out = out + bp(noise(dur), 200, 1200) * np.exp(-((t - c) / w) ** 2) * .4
    # a far siren
    s0 = rng.random() * dur * .5; sd = 6; m = (t > s0) & (t < s0 + sd)
    f = 700 + 250 * np.sin(2 * np.pi * .4 * (t - s0))
    sir = np.sin(2 * np.pi * np.cumsum(f) / SR) * m * np.sin(np.pi * np.clip((t - s0) / sd, 0, 1)) * .05
    return st(norm(out + lp(sir, 1500), gain), 1.)
def train_depart(dur=18, gain=.6):
    t = t_(dur); n = noise(dur)
    speed = np.clip((t - 1) / 12, 0, 1) ** 1.5
    rumble = (lp(n, 120, 2) * (1 - speed) + lp(n, 420, 2) * speed) * (0.3 + speed) * np.clip(1.3 - (t - 12) / 6, 0, 1)
    out = rumble
    # wheel clacks over joints, accelerating, then receding
    pos = np.cumsum(speed) / SR * 9
    cl = np.floor(pos * 3); clack_idx = np.nonzero(np.diff(cl) > 0)[0]
    for i in clack_idx:
        d = 1500; c = bp(noise(d / SR), 300, 3000)[:d] * np.exp(-np.arange(d) / 300)
        g = np.clip(1.3 - (i / SR - 12) / 6, 0, 1)
        if i + d < len(out): out[i:i + d] += c * .5 * g;
        j = i + 400
        if j + d < len(out): out[j:j + d] += c * .35 * g
    whine = np.sin(2 * np.pi * np.cumsum(200 + 900 * speed) / SR) * speed * .04 * np.clip(1.3 - (t - 12) / 6, 0, 1)
    return st(norm(out + whine, gain), 1.)
def station_hum(dur, gain=.05): return st(norm(lp(pink(dur), 250) + fluor_hum(dur, 1.)[:, 0] * .2, gain), .6)
def babble(dur, voices, gain=.12):
    """unintelligible crowd made of many reversed, overlapped, filtered voice snippets"""
    out = np.zeros(secs(dur));
    for k in range(int(dur * 3)):
        v = voices[rng.integers(len(voices))]
        a = v[::-1] if rng.random() < .6 else v
        a = a * (.3 + .7 * rng.random()); i = rng.integers(0, max(1, len(out) - len(a)))
        out[i:i + len(a)] += a[:len(out) - i]
    out = bp(out, 200, 2500)
    return st(norm(out, gain), 8.)
def applause(dur=6, gain=.3, n=40):
    out = np.zeros(secs(dur)); t = t_(dur)
    swell = np.clip(t / .8, 0, 1) * np.clip((dur - t) / 2.5, 0, 1)
    for p in range(n):
        rate = 3.5 + rng.random() * 2; ph = rng.random()
        tt = ph / rate
        while tt < dur:
            d = 500; c = bp(noise(d / SR), 800 + rng.random() * 1500, 6000)[:d] * np.exp(-np.arange(d) / 70)
            i = secs(tt);
            if i + d < len(out): out[i:i + d] += c * (.5 + .5 * rng.random()) * swell[i]
            tt += 1 / rate * (1 + .1 * rng.standard_normal())
    return st(norm(out, gain), 3.)
def clink():
    d = 1.2; t = t_(d); s = sum(np.sin(2 * np.pi * f * t) * np.exp(-t * dcy) for f, dcy in [(2900, 6), (4100, 9), (5600, 12), (7300, 15)])
    return st(norm(s * (1 - np.exp(-t * 2000)), .2), .2)
def candle(dur, gain=.02):
    out = np.zeros(secs(dur))
    for _ in range(int(dur * 4)):
        i = rng.integers(0, len(out) - 300); out[i:i + 300] += hp(noise(300 / SR), 3000)[:300] * np.exp(-np.arange(300) / 40) * rng.random()
    return st(norm(lp(pink(dur), 200) * .3 + out, gain), .2)
def phone_beep():
    t = t_(.35); return st(norm(np.sin(2 * np.pi * 1000 * t) * (t < .3), .15))
def line_hiss(dur, gain=.02): return st(norm(bp(noise(dur), 400, 3000), gain))
def kettle_far(dur, gain=.02): return st(norm(bp(noise(dur), 3000, 5000) * np.linspace(0, 1, secs(dur)), gain))

# ---- reverbs -------------------------------------------------------------------
def ir(rt=1.5, pre=.01, bright=6000, wet_stereo=True):
    d = rt * 1.2; t = t_(d)
    e = np.exp(-6.9 * t / rt)
    L = lp(noise(d), bright) * e; R = lp(noise(d), bright) * e
    L[:secs(pre)] = 0; R[:secs(pre)] = 0
    a = np.stack([L, R], 1); return a / np.sqrt((a ** 2).sum()) * 1.0
def reverb(a, rt=1.5, wet=.3, bright=6000, pre=.015):
    h = ir(rt, pre, bright)
    if a.ndim == 1: a = st(a)
    w = np.stack([signal.fftconvolve(a[:, c], h[:, c])[:len(a)] for c in range(2)], 1)
    return ((1 - wet) * a + wet * w * 3.).astype(np.float32)
