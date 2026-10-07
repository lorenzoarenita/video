# The edit: order of shots, transitions, ages and on-screen texts. Shared by the video assembler and the sound mixer.
import json, os
ROOT = os.path.dirname(os.path.abspath(__file__))
SHOTS = {s["id"]: s for s in json.load(open(os.path.join(ROOT, "shots.json")))}

# (shot id or black:<dur>, transition INTO this shot: ("cut"|"dissolve"|"dip", seconds))
SEQ = [
    ("black0:7", ("cut", 0)),
    ("s01", ("cut", 0)),
    ("title:8", ("dip", 1.5)),
    ("s02", ("dip", 1.5)),
    ("s03", ("dissolve", 2.0)),
    ("s04a", ("dissolve", 1.0)),
    ("s04b", ("dissolve", 1.0)),
    ("s04c", ("dissolve", 1.0)),
    ("s05", ("dip", 2.0)),
    ("s06", ("dissolve", 1.5)),
    ("s07", ("dip", 1.5)),
    ("s08", ("dip", 1.5)),
    ("s09", ("cut", 0)),
    ("s10", ("cut", 0)),
    ("s10b", ("cut", 0)),
    ("s11", ("dip", 2.0)),
    ("s12", ("dissolve", 1.2)),
    ("s13", ("dissolve", 1.5)),
    ("s14", ("dip", 2.0)),
    ("s15", ("dissolve", 1.5)),
    ("s16", ("cut", 0)),
    ("s17", ("dip", 2.0)),
    ("s18", ("dip", 2.0)),
    ("s19", ("dissolve", 2.0)),
    ("s20", ("dissolve", 2.0)),
    ("s21", ("dissolve", 1.5)),
    ("s22", ("dissolve", 2.0)),
    ("s23", ("dip", 2.5)),
    ("s24", ("dissolve", 2.0)),
    ("s25", ("dissolve", 2.5)),
    ("s26", ("dip", 3.0)),
    ("black1:5", ("cut", 0)),
    ("s27", ("dip", 2.0)),
    ("end:26", ("dip", 3.0)),
]

AGES = {"s01": "0", "s03": "2", "s05": "6", "s06": "7", "s07": "9", "s08": "12", "s09": "15", "s10": "16",
        "s11": "19", "s12": "21", "s13": "23", "s14": "26", "s15": "31", "s17": "33", "s18": "36", "s19": "38",
        "s20": "40", "s21": "52", "s22": "58", "s23": "74", "s24": "79", "s25": "84", "s26": "88"}

# Lucía's own words, written on screen (shot, t_in, t_out, text)
THOUGHTS = [
    ("s07", 14.0, 21.5, "Fue la primera vez que algo no volvió."),
    ("s17", 17.5, 23.0, "Gané. Y no tenía a quién llamar."),
    ("s22", 5.0, 16.5, "Mamá se fue en invierno,\ncon la ventana abierta, como a ella le gustaba."),
    ("s23", 6.0, 17.0, "Andrés se fue primero.\nSiempre fue más rápido que yo."),
    ("s25", 2.0, 9.0, "Me enseñaron a plantar, a no tenerle miedo al agua,\na guardar lo que miraba."),
    ("s25", 10.0, 15.5, "Lo demás lo aprendí sola:"),
    ("s25", 16.0, 21.0, "que se puede perder algo y seguir queriéndolo;"),
    ("s25", 21.5, 25.5, "que a veces es tarde, y aun así hay que decirlo;"),
    ("s25", 26.0, 30.0, "y que mirar es la forma más callada de querer."),
]

def durations():
    out = []
    for item, tr in SEQ:
        if ":" in item:
            name, d = item.split(":"); out.append((item, name, float(d), tr))
        else:
            out.append((item, item, SHOTS[item]["dur"], tr))
    return out

def timeline():
    """Returns list of dicts with global start time of each item. Dissolves overlap; dips and cuts do not."""
    t = 0.0; tl = []
    for item, name, d, (kind, td) in durations():
        if tl and kind == "dissolve": t -= td
        tl.append(dict(item=item, name=name, start=t, dur=d, tr=kind, td=td))
        t += d
    return tl

def start_of(name):
    for e in timeline():
        if e["name"] == name: return e["start"]
    raise KeyError(name)

def total():
    tl = timeline(); return tl[-1]["start"] + tl[-1]["dur"]

if __name__ == "__main__":
    for e in timeline(): print(f'{e["start"]:7.2f}  {e["name"]:8s} {e["dur"]:5.1f}  {e["tr"]} {e["td"]}')
    print("total", total())
