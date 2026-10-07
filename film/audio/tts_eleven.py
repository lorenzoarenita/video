# Re-voice every line with ElevenLabs. Uses ELEVENLABS_API_KEY if set; otherwise relies on the
# environment's network secret for api.elevenlabs.io to add the xi-api-key header.
# Writes build/voice/<id>.wav (48 kHz) so mix.py / assemble.py pick them up unchanged.
#   python3 tts_eleven.py --voices   -> pick and cache one Spanish voice per character
#   python3 tts_eleven.py [ids...]   -> synthesize (all lines, or only the given ids)
import os, sys, json, subprocess, urllib.request, urllib.parse, urllib.error
from lines import LINES

KEY = os.environ.get("ELEVENLABS_API_KEY")
API = "https://api.elevenlabs.io"
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "build", "voice"); os.makedirs(OUT, exist_ok=True)
CAST = os.path.join(HERE, "cast.json")
MODEL = os.environ.get("ELEVEN_MODEL", "eleven_v4")

def call(path, data=None, raw=False, method=None):
    req = urllib.request.Request(API + path, data=json.dumps(data).encode() if data is not None else None,
                                 headers={"Content-Type": "application/json", **({"xi-api-key": KEY} if KEY else {})}, method=method)
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
    "alba":    ("female", "young", "young woman clear"),
    "amiga":   ("female", "young", "lively young woman"),
    "mateo":   ("male", "young", "young man soft"),
    "andres":  ("male", "middle_aged", "calm man"),
    "otro":    ("male", "middle_aged", "neutral narrator"),
    "otra":    ("female", "middle_aged", "neutral formal woman"),
}
# character in lines.py -> cast slot, plus per-line delivery
SLOT = {"madre": "madre", "madre80": "madre80", "padre": "padre", "abuelo": "abuelo",
        "lucia2": "nina", "lucia6": "nina", "alba5": "nina", "nieta": "nina",
        "lucia16": "lucia", "lucia19": "lucia", "lucia38": "lucia", "lucia52": "lucia", "alba15": "alba", "alba50": "alba", "amiga": "amiga",
        "lucia79": "lucia_old", "lucia88": "lucia_old",
        "mateo": "mateo", "andres": "andres", "galerista": "otro", "carta1": "otro", "carta2": "otra", "carta3": "otro"}
# Eleven v4 direction: free-text tags in square brackets, stackable, followed in sequence; [pause]/[long pause] for breaks.
# Each entry replaces the line's text when sent (the subtitles keep the plain text from lines.py).
V4 = {
 "l00": "[muffled, from far away, tender, out of breath] Ya casi... [pause] ya casi, mi amor.",
 "l01": "[whispers, overwhelmed with love, voice trembling] Hola... [pause] [softly laughs] Hola, Lucía.",
 "l02": "[whispers, tearful, smiling] Ya estás aquí.",
 "l03": "[softly, to a baby, wonder] Mira... [pause] la luz.",
 "l04": "[gentle, hushed, close to a small child at night] ¿Ves? [pause] Es la luna.",
 "l05": "[small child voice, two years old, curious, trying a new word] Lu... [pause] na.",
 "l06": "[small child voice, two years old, delighted] ¡Agua!",
 "l07": "[small child voice, two years old, amazed, quiet] Fuego.",
 "l08": "[small child voice, two years old, happy, calling out] ¡Mamá!",
 "l09": "[old man, warm, patient, slightly out of breath while kneeling] Haz un hoyo pequeño. [pause] Así.",
 "l10": "[old man, warm, gently] Ahora... la semilla.",
 "l11": "[little girl, six years old, curious] ¿Cuándo saldrá el limonero?",
 "l12": "[old man, chuckles softly] Uy... [pause] dentro de mucho.",
 "l13": "[old man, tender, wise, unhurried] Lo que se planta hoy no es para uno, Lucía.",
 "l14": "[old man, softly, smiling] Es para alguien que todavía no ha llegado.",
 "l15": "[father, calm and reassuring, over the sound of waves] No tengas miedo. [pause] Dame la mano.",
 "l16": "[little girl, six years old, shouting with joy from the water, laughing] ¡Papá, mira!",
 "l17": "[mother, holding back tears, very gently] El abuelo se ha ido, cariño.",
 "l18": "[little girl, quietly, confused] ¿Adónde?",
 "l19": "[father, warm, a little shy, proud] Toma. [pause] Para que guardes lo que mires.",
 "l20": "[teenage girl, shouting over loud music, laughing] ¡Lucía! ¡Vente, que nos vamos!",
 "l21": "[mother, tired, worried, controlled anger, late at night] ¿Tú sabes qué hora es?",
 "l22": "[teenage girl, sixteen, shouting, furious, voice cracking] ¡Déjame! [pause] ¡Tú no me entiendes!",
 "l23": "[young man, whispers, lying under the stars, amused] ¿Qué miras?",
 "l24": "[young woman, whispers, dreamy] Todo.",
 "l25": "[young man, softly laughs, flirting] Pues hazme una foto.",
 "l26": "[young man, sad, guilty, quiet, on a train platform] Lo siento, Lucía.",
 "l27": "[young man, barely holding it together] No puedo quedarme.",
 "l28": "[formal, polite, cold, reading a letter] Gracias por su interés, pero...",
 "l29": "[formal, detached, reading a letter] No encaja con nuestra línea.",
 "l30": "[formal, slightly apologetic, reading a letter] Quizá el año que viene.",
 "l31": "[older man, voicemail, a little hesitant] Lucía, soy papá.",
 "l32": "[older man, voicemail, warm, a bit awkward, smiling] Nada... [pause] que me he acordado de cuando te di la cámara.",
 "l33": "[older man, voicemail, gentle, no pressure] Llámame cuando puedas.",
 "l34": "[older man, voicemail, softly, after a pause] [pause] Te quiero.",
 "l35": "[gallery owner, warm, impressed, quiet among a crowd] Enhorabuena, Lucía. [pause] Es precioso.",
 "l36": "[man, sleepy, tender, morning, murmuring] Quédate un poco más.",
 "l37": "[woman, crying softly, overwhelmed with love, whispering to her newborn] Hola... [pause] [sniff] Hola, mi vida.",
 "l38": "[whispers, tearful, smiling] Alba.",
 "l39": "[little girl, five years old, excited, calling from the garden] ¡Mamá, mira!",
 "l40": "[teenage girl, fifteen, shouting, furious, slamming a door] ¡Déjame! [pause] ¡Tú no me entiendes!",
 "l41": "[woman in her fifties, on the phone, hesitant, emotional] Mamá...",
 "l42": "[woman in her fifties, on the phone, voice breaking, sincere] Perdóname por aquella vez. [pause] Ahora lo entiendo.",
 "l43": "[very old woman, frail, tender, smiling through tears, on the phone] Ay, hija. [pause] Yo ya lo sabía.",
 "l44": "[old woman, warm, patient, kneeling in the garden] Haz un hoyo pequeño. [pause] Así.",
 "l45": "[little girl, six years old, curious] ¿Cuándo saldrá?",
 "l46": "[old woman, chuckles softly] Uy... [pause] dentro de mucho.",
 "l47": "[old woman, tender, wise, unhurried] Lo que se planta hoy no es para una.",
 "l48": "[old woman, softly, smiling] Es para alguien que todavía no ha llegado.",
 "l49": "[little girl, six years old, puzzled] ¿Y tú cómo lo sabes?",
 "l50": "[old woman, long pause, then softly, smiling, moved] [pause] Porque yo llegué.",
 "l51": "[woman, at a deathbed, holding back tears, very gently] Mamá. [pause] Estoy aquí.",
 "l52": "[very old woman, dying, faint whisper, peaceful, amazed] Mira... [long pause] qué luz.",
 "l53": "[little girl, shouting with joy from far across the garden] ¡Mamá! ¡Ha salido!",
}
# characters whose pitch we still nudge to sound younger (no child voices are guaranteed)
PITCH = {}  # v4 is directed by tags; no pitch tricks

def pick_model():
    """Use ElevenLabs v4: ask the API which v4 TTS models this account has and take the newest. Never fall back to v3."""
    global MODEL
    try: ids = [m["model_id"] for m in call("/v1/models")]
    except urllib.error.HTTPError as e:  # key without models_read: trust the configured v4 model
        print("modelo:", MODEL, f"(sin listar modelos: HTTP {e.code})"); return
    if MODEL in ids: print("modelo:", MODEL); return
    ms = [m for m in call("/v1/models") if m.get("can_do_text_to_speech") and "v4" in m["model_id"].lower()]
    if not ms: sys.exit("La cuenta no ofrece ningún modelo v4: " + ", ".join(m["model_id"] for m in call("/v1/models")))
    ms.sort(key=lambda m: (("es" in [l.get("language_id") for l in m.get("languages", [])]), m["model_id"]), reverse=True)
    MODEL = ms[0]["model_id"]; print("modelo:", MODEL)

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
        txt = V4.get(lid, text)
        body = {"text": txt, "model_id": MODEL, "voice_settings": {"stability": 0.4, "similarity_boost": 0.8}}
        mp3 = call(f"/v1/text-to-speech/{vid}?output_format=mp3_44100_192", body, raw=True)
        p = f"{OUT}/{lid}_el.mp3"; open(p, "wb").write(mp3)
        eff = ["pitch", str(PITCH[ch])] if ch in PITCH else []
        subprocess.run(["sox", p, "-r", "48000", "-c", "1", f"{OUT}/{lid}.wav"] + eff +
                       ["silence", "1", "0.02", "0.3%", "reverse", "silence", "1", "0.02", "0.3%", "reverse"], check=True)
        print(lid, ch, text)

if __name__ == "__main__":
    pick_model()
    if "--voices" in sys.argv: pick_voices()
    else:
        if not os.path.exists(CAST): pick_voices()
        synth(set(sys.argv[1:]))
