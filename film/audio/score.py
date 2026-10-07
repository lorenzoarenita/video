# The score. One theme, a lullaby in D major, carried through a life.
import sys, os, numpy as np, soundfile as sf
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from sampler import Track, midi, SR
import edit

T = edit.total() + 6
tracks = {k: Track(T) for k in ["piano", "strings", "winds", "harp", "solo"]}
P, S, W, H, V = (tracks[k] for k in ["piano", "strings", "winds", "harp", "solo"])
at = edit.start_of

# --- material ---------------------------------------------------------------
# melody: (beat offset, note, beats) over 8 bars of 3/4
MEL = [(0, "A4", 1), (1, "D5", 1), (2, "E5", 1),
       (3, "F#5", 2), (5, "E5", 1),
       (6, "D5", 1), (7, "B4", 1), (8, "A4", 1),
       (9, "B4", 3),
       (12, "G4", 1), (13, "B4", 1), (14, "D5", 1),
       (15, "E5", 2), (17, "D5", 1),
       (18, "C#5", 1), (19, "D5", 1), (20, "E5", 1),
       (21, "D5", 3)]
# second phrase (answer), used in fuller statements
MEL2 = [(0, "F#5", 1), (1, "A5", 1), (2, "G5", 1),
        (3, "F#5", 2), (5, "D5", 1),
        (6, "E5", 1), (7, "F#5", 1), (8, "G5", 1),
        (9, "A5", 3),
        (12, "B5", 1), (13, "A5", 1), (14, "F#5", 1),
        (15, "E5", 2), (17, "D5", 1),
        (18, "B4", 1), (19, "C#5", 1), (20, "E5", 1),
        (21, "D5", 3)]
# chords per bar (bass, chord tones)
MAJ = [("D2", ["D3", "A3", "F#4"]), ("C#2", ["A3", "E4", "A4"]), ("B1", ["F#3", "B3", "D4"]), ("G1", ["D3", "G3", "B3"]),
       ("E2", ["B3", "E4", "G4"]), ("A1", ["E3", "A3", "C#4"]), ("A1", ["G3", "C#4", "E4"]), ("D2", ["A3", "D4", "F#4"])]
MAJ2 = [("D2", ["A3", "D4", "F#4"]), ("F#2", ["A3", "D4", "F#4"]), ("G2", ["B3", "D4", "G4"]), ("D2", ["A3", "D4", "F#4"]),
        ("G2", ["B3", "D4", "G4"]), ("A1", ["E3", "A3", "C#4"]), ("A1", ["G3", "C#4", "E4"]), ("D2", ["A3", "D4", "F#4"])]
MIN = [("B1", ["F#3", "B3", "D4"]), ("F#2", ["A3", "C#4", "F#4"]), ("G1", ["D3", "G3", "B3"]), ("E2", ["B3", "E4", "G4"]),
       ("E2", ["G3", "B3", "E4"]), ("F#2", ["A#3", "C#4", "F#4"]), ("F#2", ["A#3", "C#4", "E4"]), ("B1", ["F#3", "B3", "D4"])]

def m(n, sh=0): return midi(n) + sh

def melody(tr, inst, t0, bpm, mel=MEL, sh=0, vel=.5, bars=None, legato=1.05, gain=1., pan=0., rub=0.0, **kw):
    b = 60 / bpm
    for i, (beat, n, d) in enumerate(mel):
        bar = beat // 3
        if bars and bar not in bars: continue
        off = (bars[0] * 3 if bars else 0)
        jitter = rub * np.sin(i * 1.7)
        tr.play(t0 + (beat - off) * b + jitter, inst, m(n, sh), vel * (0.9 + 0.2 * (d > 1)), d * b * legato, gain=gain, pan=pan, **kw)
    return t0 + (len(bars) if bars else 8) * 3 * b

def arps(tr, t0, bpm, chords, vel=.3, inst="piano", pattern=(0, 1, 2, 1, 2, 1), sh=0, gain=1., bars=None, pedal=True):
    b = 60 / bpm
    for bi, (bass, ch) in enumerate(chords):
        if bars and bi not in bars: continue
        tb = t0 + ((bi - (bars[0] if bars else 0)) * 3) * b
        tr.play(tb, inst, m(bass, sh + 12), vel * 1.1, 3 * b * (1.4 if pedal else .9), gain=gain, pan=-.2)
        for k, idx in enumerate(pattern):
            tr.play(tb + k * b / 2, inst, m(ch[idx], sh), vel * (0.85 + 0.15 * (k == 0)), (3 - k / 2) * b if pedal else b / 2, gain=gain * .8, pan=.15)

def pads(tr, t0, bpm, chords, insts=("violins", "violas", "celli"), vel=.3, sh=0, gain=1., bars=None, octave=(12, 0, -12)):
    b = 60 / bpm
    for bi, (bass, ch) in enumerate(chords):
        if bars and bi not in bars: continue
        tb = t0 + ((bi - (bars[0] if bars else 0)) * 3) * b
        d = 3 * b * 1.08
        if "celli" in insts: tr.play(tb, "celli", m(bass, sh + 12), vel, d, gain=gain, pan=-.3)
        if "bass" in insts: tr.play(tb, "bass", m(bass, sh), vel, d, gain=gain * .8, pan=-.1)
        if "violas" in insts: tr.play(tb, "violas", m(ch[0], sh), vel * .9, d, gain=gain * .8, pan=.1)
        if "violins" in insts:
            tr.play(tb, "violins", m(ch[1], sh + 12), vel * .8, d, gain=gain * .7, pan=.35)
            tr.play(tb, "violins", m(ch[2], sh), vel * .8, d, gain=gain * .6, pan=-.35)

def single(tr, t, inst, n, vel, dur, gain=1., pan=0., **kw): tr.play(t, inst, m(n), vel, dur, gain=gain, pan=pan, **kw)

# --- cues ---------------------------------------------------------------------
# Birth: after "Ya estás aquí" a few notes of the theme, solo piano, very soft
t = at("s01") + 19.5
melody(P, "piano", t, 60, vel=.28, bars=[0, 1], rub=.03)
arps(P, t, 60, MAJ, vel=.16, bars=[0, 1], pattern=(0, 1, 2))
# Title: the theme's answer, bars 2-3, then a held chord
t = at("title") + .5
melody(P, "piano", t, 60, vel=.3, bars=[2, 3], rub=.03)
arps(P, t, 60, MAJ, vel=.16, bars=[2, 3], pattern=(0, 1, 2))
pads(S, t, 60, MAJ, vel=.15, bars=[2, 3], gain=.6, insts=("violas", "celli"))

# Ceiling / moon / words: harp music-box, theme an octave up
t = at("s02") + 1.0
melody(H, "harp", t, 66, sh=12, vel=.45, bars=[0, 1, 2, 3], gain=.8)
arps(P, t, 66, MAJ, vel=.12, bars=[0, 1, 2, 3], pattern=(0, 2), sh=12)
t = at("s03") + 2.5
melody(H, "harp", t, 60, sh=12, vel=.4, bars=[4, 5, 6, 7], gain=.7)
pads(S, t, 60, MAJ, vel=.12, bars=[4, 5, 6, 7], gain=.5, insts=("violins", "violas"))
for i, nm in enumerate(["s04a", "s04b", "s04c"]):
    tt = at(nm) + 2.6
    single(H, tt, "harp", ["A5", "D6", "F#6"][i], .5, 3., gain=.7)
    single(H, tt + .25, "harp", ["D5", "A5", "D6"][i], .4, 3., gain=.5)

# Garden with grandfather: clarinet carries the theme, warm strings
def garden(t0, vel=.35):
    pads(S, t0, 56, MAJ, vel=.18, gain=.55, insts=("violins", "violas", "celli"))
    melody(W, "clarinet", t0 + 60 / 56 * 6, 56, sh=-12, vel=vel, bars=[2, 3, 4, 5, 6, 7], gain=.9)
    arps(H, t0, 56, MAJ, vel=.25, inst="harp", pattern=(0, 1, 2), gain=.5)
garden(at("s05") + 1.0)

# Sea: full, brighter, rising when she runs
t = at("s06") + .5
arps(P, t, 72, MAJ2, vel=.28)
pads(S, t, 72, MAJ2, vel=.22, gain=.7, insts=("violins", "violas", "celli", "bass"))
melody(V, "violins", t + 60 / 72 * 12, 72, mel=MEL2, sh=0, vel=.45, bars=[4, 5, 6, 7], gain=.8, attack=.2)
melody(W, "flute", t + 60 / 72 * 12, 72, mel=MEL2, sh=0, vel=.4, bars=[4, 5, 6, 7], gain=.5)

# Rain: the theme in B minor, piano alone, slow
t = at("s07") + 1.0
arps(P, t, 50, MIN, vel=.13, bars=[0, 1, 2, 3], pattern=(0, 1, 2))
melody(P, "piano", t, 50, vel=.24, bars=[0, 1, 2, 3], rub=.05)
pads(S, t + 6, 50, MIN, vel=.12, gain=.5, bars=[2, 3], insts=("celli",))

# Camera: two light bars
t = at("s08") + 9.0
melody(P, "piano", t, 72, vel=.3, bars=[0, 1], sh=12)
arps(P, t, 72, MAJ, vel=.15, bars=[0, 1], pattern=(0, 1, 2), sh=12)

# Rooftop, alone: solo violin long notes over a minor pad
t = at("s10b") + 2.0
pads(S, t, 40, MIN, vel=.12, gain=.5, bars=[0, 1, 2], insts=("violas", "celli"))
melody(V, "solovln", t + 3, 40, vel=.3, bars=[0, 1], gain=.7)

# Love: strings statement, piano arpeggios; continues into the fair
t = at("s11") + 2.0
arps(P, t, 64, MAJ, vel=.2)
pads(S, t, 64, MAJ, vel=.18, gain=.6, insts=("violas", "celli"))
melody(V, "violins", t + 60 / 64 * 24, 64, mel=MEL, vel=.4, gain=.8, bars=[0, 1, 2, 3, 4, 5, 6, 7], attack=.25)
t2 = t + 60 / 64 * 24
arps(P, t2, 64, MAJ2, vel=.22)
pads(S, t2, 64, MAJ2, vel=.22, gain=.7, insts=("violins", "violas", "celli", "bass"))
t3 = t2 + 60 / 64 * 24
melody(V, "violins", t3, 64, mel=MEL2, vel=.45, gain=.8, bars=[0, 1, 2, 3], attack=.25)
arps(P, t3, 64, MAJ2, vel=.2, bars=[0, 1, 2, 3])
pads(S, t3, 64, MAJ2, vel=.2, gain=.6, bars=[0, 1, 2, 3])

# Platform: a low cello note; after the train, three piano notes
single(S, at("s13") + 1.0, "celli", "D2", .25, 16, gain=.6)
for i, n in enumerate(["F#4", "E4", "D4"]):
    single(P, at("s13") + 20.5 + i * 1.6, "piano", n, .22, 3.)

# Struggle: ostinato in D minor, darkroom -> desk
def ostinato(t0, bars, bpm=84, vel=.18):
    b = 60 / bpm
    pat = ["D3", "F3", "A3", "F3", "D3", "A3"]
    for bi in range(bars):
        for k, n in enumerate(pat):
            P.play(t0 + (bi * 3 + k / 2) * b, "piano", m(n), vel * (1.1 if k == 0 else .9), b * .9)
    return t0 + bars * 3 * b
t = at("s14") + 1.0
e = ostinato(t, 14)
pads(S, t + 8, 84, [("D2", ["A3", "D4", "F4"])] * 4 + [("A#1", ["F3", "A#3", "D4"])] * 4, vel=.12, gain=.45, insts=("violas", "celli"))
ostinato(e, 10, vel=.12)

# After the voicemail: one low note
single(P, at("s16") + 16.5, "piano", "D2", .3, 8)
single(S, at("s16") + 16.5, "celli", "D2", .15, 8, gain=.5)

# Gallery: solo violin theme over pad, bittersweet
t = at("s17") + 1.5
pads(S, t, 58, MAJ, vel=.16, gain=.55, bars=[0, 1, 2, 3, 4, 5, 6], insts=("violins", "violas", "celli"))
melody(V, "solovln", t, 58, vel=.3, bars=[0, 1, 2, 3, 4, 5], gain=.6)

# Kitchen: flute and harp, gentle
t = at("s18") + 1.0
arps(H, t, 66, MAJ2, vel=.25, inst="harp", pattern=(0, 1, 2, 1), gain=.5, bars=[0, 1, 2, 3, 4, 5, 6, 7])
melody(W, "flute", t + 60 / 66 * 6, 66, mel=MEL2, vel=.3, bars=[2, 3, 4, 5, 6, 7], gain=.5)

# Newborn: the same piano as her birth, then strings join
t = at("s19") + 11.0
melody(P, "piano", t, 60, vel=.3, rub=.03)
arps(P, t, 60, MAJ, vel=.16, pattern=(0, 1, 2))
pads(S, t + 12, 60, MAJ, vel=.15, gain=.55, bars=[4, 5, 6, 7], insts=("violins", "violas", "celli"))

# Seasons montage: flowing, full; drops out at the teenager's outburst
t = at("s20") + .5
bpm = 84; b = 60 / bpm
arps(H, t, bpm, MAJ2, vel=.3, inst="harp", pattern=(0, 1, 2, 1, 2, 1), gain=.6)
pads(S, t, bpm, MAJ2, vel=.2, gain=.6, insts=("violins", "violas", "celli", "bass"))
melody(V, "violins", t, bpm, mel=MEL, vel=.4, gain=.7, attack=.15)
melody(W, "flute", t + 24 * b, bpm, mel=MEL2, vel=.35, gain=.5, bars=[0, 1, 2])
pads(S, at("s20") + 24.5, 50, [("E2", ["B3", "E4", "G4"])], vel=.15, gain=.5, insts=("celli",))

# Phone call: piano, minor resolving to major on "Yo ya lo sabía"
t = at("s21") + 1.0
arps(P, t, 54, MIN, vel=.14, bars=[0, 1, 2], pattern=(0, 1, 2))
t = at("s21") + 13.5
arps(P, t, 54, MAJ, vel=.16, bars=[7], pattern=(0, 1, 2))
single(S, t, "violins", "F#4", .15, 6, gain=.5)
single(S, t, "violas", "A3", .15, 6, gain=.5)

# Snow: cello pad, sparse harp
t = at("s22") + 1.0
pads(S, t, 40, MIN, vel=.12, gain=.5, bars=[0, 1, 2], insts=("celli", "violas"))
for i, n in enumerate(["B4", "D5", "F#5", "E5", "D5"]):
    single(H, t + 2 + i * 3.1, "harp", n, .3, 4, gain=.5)

# Two cups: clarinet fragment
t = at("s23") + 2.0
melody(W, "clarinet", t, 48, sh=-12, vel=.25, bars=[0, 1, 2, 3], gain=.7)
pads(S, t, 48, MAJ, vel=.1, gain=.4, bars=[0, 1, 2, 3], insts=("violas", "celli"))

# Old Lucía planting: the same garden music as with her grandfather
garden(at("s24") + 1.0, vel=.32)

# What she learned alone: the full theme, strings and piano, the emotional summit
t = at("s25") + 1.0
bpm = 56; b = 60 / bpm
arps(P, t, bpm, MAJ, vel=.2)
pads(S, t, bpm, MAJ, vel=.2, gain=.65, insts=("violins", "violas", "celli", "bass"))
melody(V, "violins", t + 12 * b, bpm, mel=MEL, vel=.4, gain=.75, bars=[4, 5, 6, 7], attack=.3)
melody(W, "clarinet", t + 12 * b, bpm, mel=MEL, sh=-12, vel=.3, gain=.5, bars=[4, 5, 6, 7])

# The last day: the theme, one note at a time, slower than a heartbeat
t = at("s26") + 4.0
melody(P, "piano", t, 40, vel=.22, bars=[0, 1, 2, 3], rub=.08, legato=1.6)
single(S, at("s26") + 30, "violins", "D5", .12, 12, gain=.5, attack=3.)
single(S, at("s26") + 30, "violins", "A4", .12, 12, gain=.4, attack=3.)
single(S, at("s26") + 30, "violas", "F#4", .12, 12, gain=.4, attack=3.)

# Epilogue and end titles: the theme, bright, everyone
t = at("s27") + 12.0
melody(H, "harp", t, 72, sh=12, vel=.4, bars=[0, 1], gain=.6)
arps(P, t, 72, MAJ, vel=.15, bars=[0, 1], pattern=(0, 1, 2), sh=12)
t = at("end") + .5
bpm = 60
arps(P, t, bpm, MAJ, vel=.2)
pads(S, t, bpm, MAJ, vel=.18, gain=.6)
melody(P, "piano", t, bpm, vel=.32, rub=.02)

for k, tr in tracks.items():
    sf.write(os.path.join(edit.ROOT, "build", f"mus_{k}.wav"), tr.buf, SR, subtype="FLOAT")
print("score rendered", T)
