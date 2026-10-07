# Re-voice every line with ElevenLabs. Reads ELEVENLABS_API_KEY from the environment.
# Writes build/voice/<id>.wav (48 kHz) so mix.py / assemble.py pick them up unchanged.
#   python3 tts_eleven.py --voices   -> pick and cache one Spanish voice per character
#   python3 tts_eleven.py [ids...]   -> synthesize (all lines, or only the given ids)
import os, sys, json, subprocess, urllib.request, urllib.parse
from lines import LINES

KEY = os.environ.get("ELEVENLABS_API_KEY") or sys.exit("ELEVENLABS_API_KEY no está definida")
API = "https://api.elevenlabs.io"
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "build", "voice"); os.makedirs(OUT, exist_ok=True)
CAST = os.path.join(HERE, "cast.json")
MODEL = os.environ.get("ELEVEN_MODEL", "eleven_v3")

def call(path, data=None, raw=False, method=None):
    req = urllib.request.Request(API + path, data=json.dumps(data).encode() if data is not None else None,
                                 headers={"xi-api-key": KEY, "Content-Type": "application/json"}, method=method)
    with urllib.request.urlopen(req, timeout=120) as r:
        b = r.read()
    return b if raw else json.loads(b)

# who each character is: (gender, age, description used to rank shared voices)
WANT = {
    "madre":   ("female", "middle_aged", "warm tender mother"),
    "madre80": ("female", "old", "frail elderly woman"),
    "padre":   ("male", "middle_aged", "gentle warm father"),
    "abuelo":  ("male", "old", "kind old grandfather"),
    "lucia":   ("female", "young", "soft natural young woman"),
    "lucia_old": ("female", "old", "old woman soft"),
    "nina":    ("female", "young", "child girl"),
    "mateo":   ("male", "young", "young man soft"),
    "andres":  ("male", "middle_aged", "calm man"),
    "otro":    ("male", "middle_aged", "neutral narrator"),
}
# character in lines.py -> cast slot, plus per-line delivery
SLOT = {"madre": "madre", "madre80": "madre80", "padre": "padre", "abuelo": "abuelo",
        "lucia2": "nina", "lucia6": "nina", "alba5": "nina", "nieta": "nina",
        "lucia16": "lucia", "lucia19": "lucia", "lucia38": "lucia", "lucia52": "lucia", "alba15": "lucia", "alba50": "lucia", "amiga": "lucia",
        "lucia79": "lucia_old", "lucia88": "lucia_old",
        "mateo": "mateo", "andres": "andres", "galerista": "otro", "carta1": "otro", "carta2": "madre", "carta3": "padre"}
# eleven_v3 audio tags for delivery (ignored by older models when stripped)
TAG = {"l00": "[whispers]", "l01": "[softly, moved]", "l02": "[softly]", "l03": "[whispers]", "l05": "[curious]",
       "l13": "[gently]", "l14": "[gently]", "l17": "[sad, softly]", "l18": "[quietly]", "l21": "[annoyed]",
       "l22": "[shouting, upset]", "l23": "[softly]", "l24": "[whispers]", "l26": "[sad]", "l27": "[sad]",
       "l32": "[warm]", "l34": "[softly]", "l37": "[crying softly]", "l38": "[whispers]", "l40": "[shouting, upset]",
       "l42": "[emotional]", "l43": "[tired, tender]", "l50": "[softly, smiling]", "l51": "[softly]", "l52": "[whispers, weak]",
       "l39": "[excited]", "l53": "[excited, shouting]", "l16": "[excited, shouting]", "l08": "[excited]"}
# characters whose pitch we still nudge to sound younger (no child voices are guaranteed)
PITCH = {"lucia2": 300, "lucia6": 150, "alba5": 200, "nieta": 200}

def pick_voices():
    cast = json.load(open(CAST)) if os.path.exists(CAST) else {}
    used = set(cast.values())
    for slot, (g, age, desc) in WANT.items():
        if slot in cast: continue
        q = urllib.parse.urlencode({"language": "es", "gender": g, "age": age, "page_size": 30, "sort": "usage_character_count_1y"})
        try: vs = call(f"/v1/shared-voices?{q}").get("voices", [])
        except Exception as e: vs = []; print("shared-voices:", e)
        vs = [v for v in vs if v["voice_id"] not in used]
        castilian = [v for v in vs if "spain" in (v.get("accent") or "").lower() or "castil" in (v.get("accent") or "").lower() or "peninsular" in (v.get("accent") or "").lower()]
        v = (castilian or vs or [None])[0]
        if v:
            try: call(f"/v1/voices/add/{v['public_owner_id']}/{v['voice_id']}", {"new_name": f"TLL {slot}"})
            except Exception as e: print("add voice:", e)
            cast[slot] = v["voice_id"]; used.add(v["voice_id"])
            print(f"{slot:10s} -> {v['name']} ({v.get('accent')}, {v.get('age')})")
        else:
            print(f"{slot:10s} -> sin voz compartida; elige una a mano en cast.json")
    json.dump(cast, open(CAST, "w"), indent=1)

def synth(only):
    cast = json.load(open(CAST))
    for lid, shot, t, ch, text, fx in LINES:
        if only and lid not in only: continue
        vid = cast[SLOT[ch]]
        txt = (TAG.get(lid, "") + " " + text).strip() if MODEL == "eleven_v3" else text
        body = {"text": txt, "model_id": MODEL, "voice_settings": {"stability": 0.5, "similarity_boost": 0.8, "style": 0.3}}
        mp3 = call(f"/v1/text-to-speech/{vid}?output_format=mp3_44100_192", body, raw=True)
        p = f"{OUT}/{lid}_el.mp3"; open(p, "wb").write(mp3)
        eff = ["pitch", str(PITCH[ch])] if ch in PITCH else []
        subprocess.run(["sox", p, "-r", "48000", "-c", "1", f"{OUT}/{lid}.wav"] + eff +
                       ["silence", "1", "0.02", "0.3%", "reverse", "silence", "1", "0.02", "0.3%", "reverse"], check=True)
        print(lid, ch, text)

if __name__ == "__main__":
    if "--voices" in sys.argv: pick_voices()
    else:
        if not os.path.exists(CAST): pick_voices()
        synth(set(sys.argv[1:]))
