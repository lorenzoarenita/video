// Thirty-one. Night, working at the light table. The phone vibrates: Papá. She doesn't pick up.
uniform float p_ring;   // ringing envelope 0..1
uniform float p_cam;

vec3 scene(vec2 uv, float t){
  vec2 p = cuv(uv);
  p *= 1. - p_cam * .05;
  vec3 col = vec3(.01, .012, .02);
  // window at back with city lights
  float win = sdBox(p - vec2(-.5, .22), vec2(.35, .2));
  vec2 wq = (p - vec2(-.5, .22)) * vec2(30., 20.);
  vec3 wn = h33(vec3(floor(wq), 2.));
  vec3 city = vec3(.02, .03, .06) + vec3(1.2, .7, .3) * step(.85, wn.x) * step(abs(fract(wq.x) - .5), .3) * step(abs(fract(wq.y) - .5), .25) * step(p.y, .2 + .1 * h11(floor(wq.x * .2))) * .5;
  col = mix(col, city, fill(win, .003));
  // desk surface
  float desk = step(p.y, -.12);
  col = mix(col, vec3(.04, .03, .025), desk);
  // light table glowing (perspective trapezoid)
  vec2 lt = p - vec2(.15, -.3);
  float lightTable = sdBox(vec2(lt.x * (1. + lt.y * .8), lt.y), vec2(.4, .12));
  vec3 ltC = vec3(1.4, 1.45, 1.5);
  // negatives strips on it
  float strip = step(abs(fract(lt.y * 7. + .5) - .5), .32) * step(abs(lt.x), .36);
  float frames = step(.12, fract(lt.x * 10.)) ;
  vec3 neg = mix(ltC, vec3(.55, .35, .2) * (.4 + .6 * vnoise(lt * 60.)), strip * frames * .85);
  col = mix(col, neg, fill(lightTable, .003));
  col += ltC * glow(max(lightTable, 0.), .08) * .12;
  // loupe
  float loupe = sdCircle(lt - vec2(-.1, .02), .045);
  col = mix(col, vec3(.02), fill(abs(loupe) - .006, .002));
  // desk lamp pool
  col += vec3(1.2, .8, .4) * glow(length((p - vec2(.75, -.18)) * vec2(.6, 1.6)), .12) * .2;
  // the phone, on the desk at left foreground, face up
  float buzz = sat(p_ring) * step(.5, fract(t * 1.6)) ;
  vec2 ph = p - vec2(-.42 + sin(t * 90.) * .002 * buzz, -.36);
  ph *= rot(-.2 + sin(t * 70.) * .01 * buzz);
  float phone = sdBox(ph, vec2(.065, .12)) - .015;
  float screen = sdBox(ph, vec2(.055, .105)) - .01;
  col = mix(col, vec3(.01), fill(phone, .002));
  vec3 scr = vec3(.25, .55, .5) * sat(p_ring) * (.7 + .3 * buzz);
  col = mix(col, scr, fill(screen, .002) * sat(p_ring));
  col += vec3(.2, .45, .4) * glow(max(phone, 0.), .05) * sat(p_ring) * .5;
  // the call icon
  col += vec3(.6, 1., .6) * fill(sdCircle(ph - vec2(0., -.07), .014), .002) * sat(p_ring);
  // her hand at the light table (silhouette from bottom right)
  vec2 hp = p - vec2(.42, -.48);
  float hand = sdCaps(hp, vec2(0.), vec2(.25, -.2), .05, .07);
  hand = smin(hand, sdEll(hp - vec2(-.02, .02), vec2(.07, .045)), .03);
  col = mix(col, vec3(.02, .02, .025), fill(hand, .004));
  return col;
}
