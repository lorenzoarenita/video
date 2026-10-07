# Shot list: id, shader, duration, keyframed params. Generates shots.json for the renderer.
import json
S = []
def shot(id, shader, dur, fadeIn=0, fadeOut=0, tex=None, **params):
    S.append(dict(id=id, shader=shader, dur=dur, fadeIn=fadeIn, fadeOut=fadeOut, params=params, tex=tex or []))

shot("s01", "s01_birth", 24, fadeIn=0.3,
     open=[[0,0],[2.5,0],[3.2,0.25],[3.8,0.05],[5.5,0.05],[7,0.5],[7.6,0.3],[10,0.85],[24,1]],
     focus=[[0,0],[10,0.15],[24,0.8]], face=[[0,0],[10,0],[17,1]], smile=1,
     glare=[[0,2.5],[12,0.6],[24,0.2]])
shot("s02", "s02_ceiling", 18, hand=[[0,0],[5,0],[10,1]], curl=[[0,0.6],[10,0.6],[12,0.05],[15,0.7],[18,0.2]],
     focus=[[0,0.3],[18,1]], exposure=0.2)
shot("s03", "s03_moon", 20, point=[[0,0],[3,0],[7,1],[14,1],[18,0]], cloud=[[0,0.5],[20,0.2]], moonx=[[0,0.05],[20,-0.02]], exposure=0.1, temp=-0.3)

shot("s04a", "s04_words", 7, var=0, exposure=0.2)
shot("s04b", "s04_words", 7, var=1)
shot("s04c", "s04_words", 7, var=2)
shot("s05", "s05_garden", 30, var=0, dig=[[0,1],[14,1],[16,0.2]], seed=[[0,0],[15,0],[19,1],[30,1]], cam=[[0,0],[30,1]])
shot("s24", "s05_garden", 32, var=1, dig=[[0,1],[14,1],[16,0.2]], seed=[[0,0],[12,0],[16,1],[32,1]], cam=[[0,0],[32,1]], temp=0.1)
shot("s27", "s05_garden", 20, var=2, cam=[[0,0],[20,1]], temp=0.35, exposure=0.1)

shot("s06", "s06_sea", 26, var=0, run=[[0,0],[15,0],[19,1],[26,1.3]], cam=[[0,0],[26,1]])
shot("s25", "s06_sea", 30, var=1, cam=[[0,0],[30,1]], exposure=-0.1)
shot("s07", "s07_rain", 24, cam=[[0,0],[24,1]], temp=-0.4, sat=-0.2)

shot("s08", "s08_viewfinder", 20, focus=[[0,0],[5,0],[11,1]], shutter=[[0,0],[15.9,0],[16,1],[16.15,1],[16.3,0]])
shot("s09", "s09_bus", 22, speed=0.0, rain=0.35)
shot("s10", "s10_hall", 12, door=[[0,0],[8.6,0],[9.4,1]], step=[[0,0],[5,1]])
shot("s10b", "s10b_roof", 18, cam=[[0,0],[18,1]], fadeIn=2)

shot("s11", "s11_fireflies", 30, lean=[[0,0],[14,0],[20,1]], cam=[[0,0],[30,1]])
shot("s12", "s12_fair", 14, kiss=[[0,0],[6,0],[11,1]], cam=[[0,0],[14,1]])
shot("s13", "s13_platform", 26, train=[[0,0],[9,0],[20,1]], gone=[[0,0],[19,0],[21,1]])

shot("s14", "s14_darkroom", 26, dev=[[0,0],[4,0],[22,1]], cam=[[0,0],[26,1]], tex=["assets/photos/s13_24.png"])
shot("s15", "s15_desk", 20, ring=[[0,0],[3,0],[3.3,1],[13,1],[13.5,0]], cam=[[0,0],[20,1]])
shot("s16", "s16_corridor", 26, cam=[[0,0],[26,1]], flicker=1, temp=-0.3, sat=-0.3)
shot("s17", "s17_gallery", 24, track=[[0,0],[19,1],[24,1.0]], crowd=1, tex=["assets/photos/s06_6.png","assets/photos/s05_18.png","assets/photos/s13_24.png","assets/photos/ph_father.png"])

shot("s18", "s18_kitchen", 20, var=0, cam=[[0,0],[20,1]], exposure=-0.1)
shot("s19", "s19_newborn", 28, focus=[[0,0.2],[8,0.9],[28,1]], eyes=[[0,0],[16,0],[19,1]], tear=[[0,1],[12,0.3]], fadeIn=1.5)
shot("s20", "s20_seasons", 32, season=[[0,0],[32,12]], grow=[[0,0.35],[32,0.85]], kid=[[0,0],[3,1],[16,1],[22,2],[32,2]])
shot("s22", "s22_snow", 20, cam=[[0,0],[20,1]], temp=-0.2)
shot("s23", "s18_kitchen", 22, var=1, haze=[[0,0.3],[22,0.8]], cam=[[0,0],[22,1]])

shot("s21", "s03_moon", 22, point=0, cloud=[[0,0.3],[22,0.6]], moonx=[[0,-0.3],[22,-0.34]], exposure=0.0, temp=-0.2)
shot("s26", "s01_birth", 42, old=1, smile=0.6,
     open=[[0,0.9],[14,0.85],[16,0.6],[17,0.8],[28,0.6],[32,0.35],[34,0.5],[38,0.12],[40,0]],
     focus=[[0,0.3],[14,0.8],[28,0.8],[40,0.2]], face=[[0,0],[6,0],[13,1]], glare=[[0,0.2],[30,0.6],[40,2.5]],
     white=[[0,0],[34,0],[41,0.85],[42,1]], exposure=0.1)

if __name__ == "__main__":
    json.dump(S, open("shots.json", "w"), indent=1)
    json.dump([dict(id="ph_father", shader="s08_viewfinder", dur=1, params=dict(var=1))], open("photos.json", "w"))
    print(len(S), "shots", sum(s["dur"] for s in S), "s")
