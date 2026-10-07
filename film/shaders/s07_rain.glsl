// Rain on the window. Grandfather's empty armchair. Outside, the little lemon sapling in the rain.
uniform float p_cam;

vec3 outside(vec2 p, float t, float blur){
  vec3 col = mix(vec3(.16, .2, .22), vec3(.45, .5, .55), sat(p.y + .4));
  // garden blobs
  float hedge = fill(p.y - (-.1 + .08 * fbm(vec2(p.x * 2., 3.))), .03 + blur);
  col = mix(col, vec3(.07, .11, .09), hedge);
  float grd = fill(p.y + .25, .02 + blur);
  col = mix(col, vec3(.08, .1, .08), grd);
  // the sapling with stake
  vec2 sp = (p - vec2(.18, -.26)) / 2.2;
  float stake = sdBox(sp - vec2(.012, .07), vec2(.003, .07));
  float stem = sdCaps(sp, vec2(0.), vec2(.0, .09), .003, .002);
  float lv = 1e5;
  for (int i = 0; i < 6; i++){ float fi = float(i); vec2 lp = vec2(sin(fi * 2.4) * .025, .05 + fi * .008); lv = min(lv, sdEll((sp - lp) * rot(fi * 1.3 + sin(t * 2. + fi) * .1), vec2(.014, .006))); }
  col = mix(col, vec3(.03, .05, .03), fill(min(min(stake, stem), lv), .002 + blur * .3));
  return col;
}

vec3 scene(vec2 uv, float t){
  vec2 p = cuv(uv);
  p *= 1. - p_cam * .06;
  vec3 room = vec3(.03, .035, .045);
  vec3 col = room;
  float win = sdBox(p - vec2(.15, .05), vec2(.62, .4));
  if (win < .01){
    vec3 rg = rainGlass(uv * (1. - p_cam * .06), t, .9);
    vec2 off = rg.xy * .6;
    vec3 o = outside(p + off * 1.5, t, .015);
    vec3 ob = outside(p, t, .06);
    col = mix(ob, o, sat(rg.z * 1.5));
    col += vec3(.35, .4, .45) * rg.z * .12;
    col += vec3(.6, .65, .7) * pow(sat(rg.z), 4.) * sat(rg.y * 6.) * .5;
    col *= fill(win, .004);
    // mullions
    float mul = min(abs(p.x - .15) - .008, abs(p.y - .1) - .006);
    col = mix(col, room * 1.4, fill(mul, .002));
  }
  // sill
  col = mix(col, vec3(.06, .065, .07), fill(sdBox(p - vec2(.15, -.37), vec2(.7, .015)), .003));
  // empty armchair silhouette, bottom-left foreground
  vec2 cp = p - vec2(-.55, -.5);
  float back = sdBox((cp - vec2(.0, .28)) * rot(.08), vec2(.2, .22)) - .05;
  float armL = sdBox(cp - vec2(-.25, .12), vec2(.05, .12)) - .04;
  float armR = sdBox(cp - vec2(.25, .12), vec2(.05, .12)) - .04;
  float seat = sdBox(cp - vec2(0., .05), vec2(.25, .08)) - .03;
  float chair = min(min(back, seat), min(armL, armR));
  float cm = fill(chair, .006);
  vec3 chairC = vec3(.015, .015, .02) + vec3(.12, .14, .17) * smoothstep(-.02, 0., chair) * smoothstep(-.3, .3, cp.x + cp.y) * .5;
  col = mix(col, chairC, cm);
  // cold light from window on floor
  col += vec3(.08, .1, .12) * fill(sdBox(vec2(p.x - .15 + (p.y + .5) * .4, p.y + .48), vec2(.5, .08)), .1) * .4;
  return col;
}
