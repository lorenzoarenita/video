# Mix: dialogue + sound design + score -> build/mix.wav. Also writes build/lines_timed.json for subtitles.
import sys, os, json, numpy as np, soundfile as sf
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
import edit
from sfx import *
from lines import LINES

B = os.path.join(edit.ROOT, "build")
T = edit.total() + 4
N = secs(T)
at = edit.start_of
bus = {k: np.zeros((N, 2), np.float32) for k in ["dia", "amb", "fx", "mus"]}

def put(busname, t, a, gain=1., pan=0.):
    i = secs(t)
    if i < 0: a = a[-i:]; i = 0
    j = min(N, i + len(a))
    if j <= i: return
    g = np.array([np.cos((pan + 1) * np.pi / 4), np.sin((pan + 1) * np.pi / 4)]) * np.sqrt(2)
    bus[busname][i:j] += a[: j - i] * g[None] * gain

def amb(shot, gen, gain=1., t0=0., dur=None, fi=1.5, fo=1.5, extra=0.):
    """ambience covering a shot (plus `extra` seconds on each side for dissolves)"""
    s = at(shot) + t0 - extra
    sd = {e["name"]: e["dur"] for e in edit.timeline()}[shot]
    d = (dur if dur is not None else sd - t0) + 2 * extra
    a = gen(d) if callable(gen) else gen
    put("amb", s, fade(a, fi, fo), gain)

# ---- dialogue ------------------------------------------------------------------
timed = []
for lid, shot, t, ch, text, fx in LINES:
    a, sr = sf.read(f"{B}/voice/{lid}.wav", dtype="float32")
    if a.ndim == 2: a = a.mean(1)
    a = a / (np.sqrt((a ** 2).mean()) + 1e-9) * 0.07
    pan = 0.
    if fx == "womb":   a = lp(a, 380, 3) * 2.2; a = reverb(a, .5, .3, 900); g = .9
    elif fx == "room": a = reverb(lp(a, 9000), .7, .22, 5000); g = 1.
    elif fx == "dry":  a = reverb(a, .45, .1, 6000); g = 1.
    elif fx == "far":  a = reverb(lp(a, 4500), 1.3, .35, 4000); g = .85
    elif fx == "hall": a = reverb(lp(a, 8000), 1.0, .3, 4500); g = .95
    elif fx in ("phone", "voicemail"):
        a = np.tanh(bp(a, 320, 3300, 3) * 3.) * .5; a = reverb(a, .2, .05); g = .95
    elif fx == "memory":
        a = reverb(lp(a, 5000), 2.6, .5, 3500); g = .65; pan = [-.4, .35, -.1][int(lid[-1]) % 3]
    else: a = st(a); g = 1.
    gs = at(shot) + t if not shot.startswith("black") else at(shot) + t
    if fx == "voicemail" and lid == "l31": put("fx", gs - 1.2, phone_beep(), .8)
    put("dia", gs, a, g, pan)
    timed.append(dict(id=lid, start=gs, end=gs + len(a) / SR + .5, text=text, ch=ch))
json.dump(timed, open(f"{B}/lines_timed.json", "w"), ensure_ascii=False, indent=1)

# voices for the babble (crowds)
vox = []
for lid, *_ in LINES:
    a, _ = sf.read(f"{B}/voice/{lid}.wav", dtype="float32"); vox.append(a if a.ndim == 1 else a.mean(1))

# ---- ambiences & effects, shot by shot ---------------------------------------------
# prologue: inside, the heartbeat; then silence; then the first breath
put("amb", at("black0") + 0, fade(womb(7.2), 2, .02), .4)
put("fx", at("black0") + 0, fade(heartbeat(7.2, 76, 160, .9), 2, .02), .5)
put("fx", at("s01") + .25, gasp(), .9)
amb("s01", lambda d: room(d, .04), 1, t0=.6, fo=1)
amb("s01", lambda d: babble(d, vox, .02), 1, t0=4)            # the room, people far away
put("fx", at("s01") + 2.0, heartbeat(20, 132, 900, .06), .5)  # her own heart, fast, tiny
# title: silence and the theme
amb("s02", lambda d: birds(d, .8, .05), 1, extra=1); amb("s02", lambda d: leaves(d, .05), 1, extra=1)
amb("s02", lambda d: room(d, .03), 1)
amb("s03", lambda d: crickets(d, .03), 1, extra=1); amb("s03", lambda d: room(d, .025), 1); amb("s03", lambda d: wind(d, .04, 500), 1)
amb("s04a", lambda d: room(d, .03), 1, fi=.5, fo=.5)
for k in range(5): put("fx", at("s04a") + .3 + k * 1.3, st(bp(noise(.3), 600, 4000) * np.exp(-t_(.3) * 30) * .15), .5)
amb("s04b", lambda d: candle(d, .03), 1, fi=.5, fo=.5)
amb("s04c", lambda d: room(d, .03), 1, fi=.5, fo=.5)
amb("s05", lambda d: birds(d, 1.0, .06), 1); amb("s05", lambda d: wind(d, .05, 700), 1); amb("s05", lambda d: leaves(d, .05), 1)
for k in range(8): put("fx", at("s05") + 1 + k * 1.45, st(lp(noise(.25), 1200) * np.exp(-t_(.25) * 18) * .3), .35)  # digging
amb("s06", lambda d: waves(d, 8., .2), 1, extra=1.5); amb("s06", lambda d: gulls(d, .03), 1); amb("s06", lambda d: wind(d, .08, 1200), 1)
put("fx", at("s06") + 18.5, st(hp(noise(1.5), 800) * np.exp(-t_(1.5) * 3) * .4), .6)  # splash
amb("s07", lambda d: rain(d, .2), 1, extra=.8); amb("s07", lambda d: room(d, .03), 1); put("fx", at("s07") + 3, thunder_far(.25), 1.)
amb("s08", lambda d: room(d, .03), 1); amb("s08", lambda d: birds(d, .5, .03), 1)
put("fx", at("s08") + 15.9, shutter(), .9)
put("fx", at("s08") + 5.5, st(hp(noise(1.5), 2500) * .02 * (np.sin(np.arange(secs(1.5)) / SR * 2 * np.pi * 9) > .8)), .8)  # focus ring
amb("s09", lambda d: engine(d, .14), 1, fi=.05); amb("s09", lambda d: beat_music(d, 100, .2, 2000), 1, fi=.05)
amb("s09", lambda d: babble(d, vox, .06), 1, fi=.05); amb("s09", lambda d: city(d, .08), 1, fi=.05)
amb("s10", lambda d: room(d, .035), 1, fi=.02, dur=9.4, fo=.02); amb("s10", lambda d: clock(d, .03), 1, dur=9.4, fi=.02, fo=.02)
put("fx", at("s10") + 9.1, door_slam(), 1.)
amb("s10b", lambda d: city(d, .1), 1, fi=4); amb("s10b", lambda d: wind(d, .07, 600), 1, fi=4)
amb("s11", lambda d: crickets(d, .045), 1, extra=1); amb("s11", lambda d: wind(d, .03, 500), 1)
put("fx", at("s11") + 17.0, shutter(), .7)
amb("s12", lambda d: babble(d, vox, .07), 1, extra=1); amb("s12", lambda d: city(d, .04), 1)
amb("s13", lambda d: station_hum(d, .05), 1, extra=1)
put("fx", at("s13") + 8.5, train_depart(15), .8)
put("fx", at("s13") + 23.5, shutter(), .7)
amb("s14", lambda d: slosh(d, .05), 1); amb("s14", lambda d: clock(d, .035, 120), 1); amb("s14", lambda d: room(d, .02), 1)
amb("s15", lambda d: city(d, .04), 1); amb("s15", lambda d: room(d, .03), 1)
put("fx", at("s15"), buzz_phone(20, start=3.3, stop=13.2, gain=.25), .8)
amb("s16", lambda d: fluor_hum(d, .035), 1, fi=.05); amb("s16", lambda d: ventilation(d, .05), 1, fi=.05)
amb("s17", lambda d: babble(d, vox, .09), 1)
put("fx", at("s17") + 8.0, applause(7, .35), .8)
for k in range(4): put("fx", at("s17") + 2 + k * 3.7, clink(), .15, pan=(-.5 + k * .3))
amb("s18", lambda d: birds(d, .9, .05), 1, extra=1); amb("s18", lambda d: room(d, .03), 1); amb("s18", lambda d: clock(d, .02), 1)
put("fx", at("s18") + 3.0, clink(), .2)
amb("s19", lambda d: room(d, .035), 1, extra=1); amb("s19", lambda d: babble(d, vox, .015), 1)
put("fx", at("s19") + 3, breaths(20, .5, .05), .5)
amb("s20", lambda d: birds(d, 1.5, .05), 1, extra=1); amb("s20", lambda d: leaves(d, .06), 1); amb("s20", lambda d: wind(d, .06, 900, .2), 1)
amb("s20", lambda d: cicadas(d, .02), 1, t0=3, dur=6)
amb("s21", lambda d: crickets(d, .03), 1, extra=1); amb("s21", lambda d: line_hiss(d, .012), 1, t0=3, dur=15)
amb("s22", lambda d: wind(d, .1, 500, .1), 1, extra=1); amb("s22", lambda d: candle(d, .02), 1)
amb("s23", lambda d: clock(d, .04), 1, extra=1); amb("s23", lambda d: room(d, .03), 1); amb("s23", lambda d: birds(d, .3, .015), 1)
amb("s24", lambda d: birds(d, 1.0, .06), 1, extra=1); amb("s24", lambda d: wind(d, .05, 700), 1); amb("s24", lambda d: leaves(d, .06), 1)
for k in range(8): put("fx", at("s24") + 1 + k * 1.45, st(lp(noise(.25), 1200) * np.exp(-t_(.25) * 18) * .3), .3)
amb("s25", lambda d: waves(d, 9., .26), 1, extra=1.5); amb("s25", lambda d: gulls(d, .02), 1); amb("s25", lambda d: wind(d, .07, 900), 1)
amb("s26", lambda d: room(d, .03), 1, fo=3); amb("s26", lambda d: birds(d, .4, .02), 1, fo=4)
put("fx", at("s26") + 1, breaths(34, .2, .09, old=True), 1.)
put("fx", at("s26") + 2, heartbeat(36, 58, 200, .35, bpm_end=34, stop_at=33.5), .7)
amb("s27", lambda d: birds(d, 1.6, .07), 1, fi=3); amb("s27", lambda d: leaves(d, .07), 1, fi=3); amb("s27", lambda d: wind(d, .05, 800), 1, fi=3)
amb("end", lambda d: birds(d, .6, .03), 1, fo=6)

# ---- music -------------------------------------------------------------------------
mus = np.zeros((N, 2), np.float32)
gains = {"piano": 1.0, "strings": 3.6, "winds": 1.6, "harp": 3.2, "solo": 3.4}
for k, g in gains.items():
    a, _ = sf.read(f"{B}/mus_{k}.wav", dtype="float32")
    a = a[:N]
    if len(a) < N: a = np.concatenate([a, np.zeros((N - len(a), 2), np.float32)])
    rt = 2.6 if k != "piano" else 2.0
    a = reverb(a, rt, .32 if k == "piano" else .4, 7000, .02)
    mus += a * g
bus["mus"] = mus

# duck the music and ambience under dialogue
env = lp(np.abs(bus["dia"]).mean(1), 4, 1)
env = np.clip(env / (env.max() + 1e-9) * 6, 0, 1)
duck = 1 - .55 * env
bus["mus"] *= duck[:, None]; bus["amb"] *= (1 - .35 * env)[:, None]

# ---- master ------------------------------------------------------------------------------
gains = {"dia": 1.0, "amb": .9, "fx": .9, "mus": .55}
master = sum(bus[k] * g for k, g in gains.items())
for k in bus: sf.write(f"{B}/stem_{k}.wav", bus[k], SR, subtype="FLOAT")
pk = np.abs(master).max(); master = master / pk * .89
master = np.tanh(master * 1.1) / np.tanh(1.1)
sf.write(f"{B}/mix.wav", master, SR, subtype="PCM_24")
print("mix", T, "s peak", pk)
