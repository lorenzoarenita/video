# Assemble the film: shots + transitions + typography + sound -> build/TODA_LA_LUZ_master.mp4
import json, os, subprocess, sys
import edit
B = os.path.join(edit.ROOT, "build")
SH = os.path.join(B, "shots")
W, H, AH = 1920, 1080, 804
TOP = (H - AH) // 2

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
Style: Title,EB Garamond,104,&H00F4F4F4,&H000000FF,&H00000000,&H00000000,0,0,0,0,100,100,26,0,1,0,0,5,0,0,0,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
"""
    open(os.path.join(B, "film.ass"), "w").write(hdr + "\n".join(ev) + "\n")

def build(out, crf=17, preset="slow", extra_v=None, scale=None, audio=True):
    tl = edit.timeline()
    inputs, filt = [], []
    n = 0
    for k, e in enumerate(tl):
        name, d = e["name"], e["dur"]
        if name in edit.SHOTS:
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
        filt.append(chain + f"[c{k}]")
        n += 1
    # chain: concat for cuts/dips, xfade for dissolves
    cur = "c0"; cur_len = tl[0]["dur"]
    for k in range(1, len(tl)):
        e = tl[k]
        if e["tr"] == "dissolve":
            off = cur_len - e["td"]
            filt.append(f"[{cur}][c{k}]xfade=transition=fade:duration={e['td']}:offset={off:.3f}[x{k}]")
            cur_len = cur_len + e["dur"] - e["td"]
        else:
            filt.append(f"[{cur}][c{k}]concat=n=2:v=1:a=0[x{k}]")
            cur_len += e["dur"]
        cur = f"x{k}"
    ass = os.path.join(B, "film.ass").replace(":", "\\:")
    post = f"[{cur}]pad={W}:{H}:0:{TOP}:black,ass='{ass}'"
    if scale: post += f",scale={scale}:flags=lanczos"
    if extra_v: post += "," + extra_v
    filt.append(post + "[v]")
    open(os.path.join(B, "filter.txt"), "w").write(";\n".join(filt))
    cmd = ["ffmpeg", "-y", "-loglevel", "error", "-stats"] + inputs
    if audio: cmd += ["-i", os.path.join(B, "mix.wav")]
    cmd += ["-filter_complex_script", os.path.join(B, "filter.txt"), "-map", "[v]"]
    if audio: cmd += ["-map", f"{n}:a", "-af", "loudnorm=I=-17:TP=-1.5:LRA=14", "-c:a", "aac", "-b:a", "192k", "-ar", "48000"]
    cmd += ["-c:v", "libx264", "-preset", preset, "-crf", str(crf), "-pix_fmt", "yuv420p", "-movflags", "+faststart", "-t", f"{cur_len:.3f}", out]
    print(" ".join(cmd[:8]), "...")
    subprocess.run(cmd, check=True)
    return cur_len

if __name__ == "__main__":
    write_ass()
    if "--ass" in sys.argv: sys.exit()
    out = sys.argv[1] if len(sys.argv) > 1 and not sys.argv[1].startswith("-") else os.path.join(B, "TODA_LA_LUZ_master.mp4")
    print("length", build(out))
