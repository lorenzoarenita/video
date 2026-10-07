# Assemble the film: shots + transitions + typography + sound -> build/TODA_LA_LUZ_master.mp4
import json, os, subprocess, sys
import edit
B = os.path.join(edit.ROOT, "build")
SH = os.path.join(B, "shots")
W, H, AH = 1920, 1080, 804
TOP = (H - AH) // 2
LIMIT = 1e9

def ts(t):
    t = max(0, t); h = int(t // 3600); m = int(t % 3600 // 60); s = t % 60
    return f"{h}:{m:02d}:{s:05.2f}"

def write_ass():
    tl = {e["name"]: e for e in edit.timeline()}
    ev = []
    def add(style, t0, t1, text, layer=0): ev.append(f"Dialogue: {layer},{ts(t0)},{ts(t1)},{style},,0,0,0,,{text}")
    # spoken lines
    for l in json.load(open(os.path.join(B, "lines_timed.json"))):
        add("Dia", l["start"] - .05, l["end"] + .4, "{\\fad(150,250)}" + l["text"])
    # ages, top bar, left
    for shot, age in edit.AGES.items():
        s = tl[shot]["start"] + 1.0
        add("Age", s, s + 4.5, "{\\fad(900,1200)}" + age)
    # Lucía's thoughts, inside the picture
    for shot, a, b, text in edit.THOUGHTS:
        s = tl[shot]["start"]
        add("Thought", s + a, s + b, "{\\fad(1200,1200)}" + text.replace("\n", "\\N"))
    # title
    t = tl["title"]["start"]
    add("Title", t + 1.2, t + 7.2, "{\\fad(2000,1500)}TODA LA LUZ")
    # end
    e = tl["end"]["start"]
    add("Title", e + 1.5, e + 6.5, "{\\fad(1500,1500)}TODA LA LUZ")
    add("Thought", e + 7.0, e + 13.5, "{\\fad(1500,1500)}Para alguien que todavía no ha llegado.")
    cred = ("Imagen: escenas escritas en GLSL y renderizadas fotograma a fotograma\\N"
            "Música original para piano y cuerdas (Salamander Grand Piano · VSCO 2 Community Edition)\\N"
            "Voces: Kokoro · Sonido sintetizado")
    add("Credit", e + 15.0, e + 24.5, "{\\fad(1500,2000)}" + cred)
    # camera flashes when she takes a photograph
    for shot, tt in (("s11", 17.0), ("s13", 23.5)):
        s0 = tl[shot]["start"] + tt
        add("Flash", s0, s0 + .5, "{\\fad(0,420)\\p1}m 0 0 l 1920 0 1920 1080 0 1080{\\p0}", layer=5)
    hdr = f"""[Script Info]
ScriptType: v4.00+
PlayResX: {W}
PlayResY: {H}
WrapStyle: 0
ScaledBorderAndShadow: yes

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Dia,EB Garamond,46,&H00E6EAEE,&H000000FF,&H00000000,&H64000000,0,0,0,0,100,100,0.5,0,1,0,0,2,80,80,46,1
Style: Thought,EB Garamond,56,&H00F2F2F2,&H000000FF,&H00000000,&H80000000,0,1,0,0,100,100,1,0,1,0,2,2,160,160,{TOP + 150},1
Style: Age,EB Garamond,40,&H00A8A8A8,&H000000FF,&H00000000,&H00000000,0,0,0,0,100,100,6,0,1,0,0,7,96,96,{TOP // 2 - 22},1
Style: Credit,EB Garamond,34,&H00B4B4B4,&H000000FF,&H00000000,&H00000000,0,1,0,0,100,100,1,0,1,0,0,5,0,0,0,1
Style: Flash,Arial,20,&H00FFFFFF,&H000000FF,&H00FFFFFF,&H00000000,0,0,0,0,100,100,0,0,1,0,0,7,0,0,0,1
Style: Title,EB Garamond,104,&H00F4F4F4,&H000000FF,&H00000000,&H00000000,0,0,0,0,100,100,26,0,1,0,0,5,0,0,0,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
"""
    open(os.path.join(B, "film.ass"), "w").write(hdr + "\n".join(ev) + "\n")

def build(out, crf=17, preset="slow", extra_v=None, scale=None, audio=True, subs=True, venc=None):
    tl = edit.timeline()
    inputs, filt = [], []
    n = 0
    for k, e in enumerate(tl):
        name, d = e["name"], e["dur"]
        if name in edit.SHOTS and os.path.exists(os.path.join(SH, name + ".mp4")):
            inputs += ["-i", os.path.join(SH, name + ".mp4")]
            chain = f"[{n}:v]scale={W}:{AH}:flags=lanczos,setsar=1,fps=24,format=yuv420p,trim=duration={d},setpts=PTS-STARTPTS"
        else:
            inputs += ["-f", "lavfi", "-t", str(d), "-i", f"color=c=black:s={W}x{AH}:r=24"]
            chain = f"[{n}:v]setsar=1,format=yuv420p"
        # dips: fade in at start of this clip / fade out at end of previous
        nxt = tl[k + 1] if k + 1 < len(tl) else None
        if e["tr"] == "dip" and e["td"] > 0:
            chain += f",fade=t=in:st=0:d={e['td'] * .6:.2f}"
        if nxt and nxt["tr"] == "dip" and nxt["td"] > 0:
            chain += f",fade=t=out:st={d - nxt['td'] * .6:.2f}:d={nxt['td'] * .6:.2f}"
        filt.append(chain + f",fps=24,settb=1/24[c{k}]")
        n += 1
    # chain: concat for cuts/dips, xfade for dissolves
    cur = "c0"; cur_len = tl[0]["dur"]
    for k in range(1, len(tl)):
        e = tl[k]
        if e["tr"] == "dissolve":
            off = cur_len - e["td"]
            filt.append(f"[{cur}][c{k}]xfade=transition=fade:duration={e['td']}:offset={off:.3f},settb=1/24[x{k}]")
            cur_len = cur_len + e["dur"] - e["td"]
        else:
            filt.append(f"[{cur}][c{k}]concat=n=2:v=1:a=0,settb=1/24[x{k}]")
            cur_len += e["dur"]
        cur = f"x{k}"
    ass = os.path.join(B, "film.ass").replace(":", "\\:")
    post = f"[{cur}]pad={W}:{H}:0:{TOP}:black" + (f",ass='{ass}'" if subs else "")
    if scale: post += f",scale={scale}:flags=lanczos"
    if extra_v: post += "," + extra_v
    filt.append(post + "[v]")
    open(os.path.join(B, "filter.txt"), "w").write(";\n".join(filt))
    cmd = ["ffmpeg", "-y", "-loglevel", "error"] + inputs
    if audio: cmd += ["-i", os.path.join(B, "mix.wav")]
    cmd += ["-filter_complex_script", os.path.join(B, "filter.txt"), "-map", "[v]"]
    if audio: cmd += ["-map", f"{n}:a", "-af", "loudnorm=I=-17:TP=-1.5:LRA=14", "-c:a", "aac", "-b:a", "192k", "-ar", "48000"]
    cmd += (venc or ["-c:v", "libx264", "-preset", preset, "-crf", str(crf)]) + [ "-pix_fmt", "yuv420p", "-movflags", "+faststart", "-t", f"{min(cur_len, LIMIT):.3f}", out]
    print(" ".join(cmd[:8]), "...")
    subprocess.run(cmd, check=True)
    return cur_len

def from_kit(out):
    """Final film from the saved clean picture (kit/picture_*.mp4) + current subtitles + build/mix.wav."""
    parts = sorted(f for f in os.listdir(os.path.join(edit.ROOT, "kit")) if f.startswith("picture_"))
    lst = os.path.join(B, "parts.txt")
    open(lst, "w").write("".join(f"file '{os.path.join(edit.ROOT, 'kit', p)}'\n" for p in parts))
    ass = os.path.join(B, "film.ass").replace(":", "\\:")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-f", "concat", "-safe", "0", "-i", lst, "-i", os.path.join(B, "mix.wav"),
                    "-vf", f"ass='{ass}'", "-map", "0:v", "-map", "1:a", "-af", "loudnorm=I=-17:TP=-1.5:LRA=14",
                    "-c:v", "libx264", "-preset", "slow", "-b:v", "880k", "-maxrate", "3000k", "-bufsize", "6000k",
                    "-c:a", "aac", "-b:a", "192k", "-movflags", "+faststart", "-t", f"{edit.total():.3f}", out], check=True)

if __name__ == "__main__":
    write_ass()
    if "--ass" in sys.argv: sys.exit()
    if "--clean" in sys.argv:   # picture only, no subtitles, no sound -> kit (for re-voicing later)
        os.makedirs(os.path.join(edit.ROOT, "kit"), exist_ok=True)
        print("length", build(os.path.join(B, "picture_clean.mp4"), audio=False, subs=False,
                              venc=["-c:v", "libx264", "-preset", "slow", "-crf", "20", "-maxrate", "2100k", "-bufsize", "4200k", "-g", "240"]))
    elif "--kit" in sys.argv:
        from_kit(os.path.join(edit.ROOT, "..", "TODA_LA_LUZ.mp4"))
    elif "--preview" in sys.argv:
        LIMIT = float(sys.argv[sys.argv.index("--preview") + 1])
        print("length", build(os.path.join(B, "preview.mp4"), crf=30, preset="ultrafast", scale="960:540"))
    else:
        out = sys.argv[1] if len(sys.argv) > 1 and not sys.argv[1].startswith("-") else os.path.join(B, "TODA_LA_LUZ_master.mp4")
        print("length", build(out))
