// First words. Variant 0: "agua" (drops falling into a bowl), 1: "fuego" (a candle), 2: "mamá" (a doorway of light)
uniform float p_var;
uniform float p_focus;

vec3 water(vec2 p, float t){
  // looking down into a basin of water lit by window: ripples from drops
  vec3 col = vec3(.04, .08, .1);
  vec2 q = p * 1.2;
  float h = 0.;
  for (int i = 0; i < 5; i++){
    float fi = float(i);
    float ti = mod(t - fi * 1.3, 6.5);
    vec2 c = vec2(sin(fi * 2.3) * .35, cos(fi * 1.7) * .18);
    float r = length(q - c);
    float wave = sin(r * 60. - ti * 9.) * exp(-r * 4.) * exp(-ti * .45) * smoothstep(ti * .35 + .02, ti * .35 - .05, r);
    h += wave;
  }
  vec2 g = vec2(dFdx(h), dFdy(h)) * 40.;
  // reflected window (bright rect) distorted by ripples
  vec2 rq = q + g * .4;
  float win = fill(sdBox(rq - vec2(-.3, .1), vec2(.35, .25)), .08);
  col += vec3(.9, 1., 1.05) * win * .9;
  col += vec3(.5, .7, .8) * sat(g.x * .6 + g.y * .3) * .7;
  col += vec3(.2, .35, .4) * fbm(q * 3. + t * .05) * .3;
  // falling drop glints
  float drop = mod(t, 1.3);
  col += vec3(1.) * glow(length(p - vec2(sin(floor(t / 1.3) * 2.3) * .3, .5 - drop * .6)), .006) * step(drop, .8);
  return col;
}
vec3 candle(vec2 p, float t){
  vec3 col = vec3(.02, .012, .008);
  col += bokeh(p, 9., 1.6, .7, vec3(.8, .45, .15), vec3(.5, .25, .1), t, .01) * .09;
  // candle body
  float body = sdBox(p - vec2(0., -.38), vec2(.07, .2));
  vec3 wax = vec3(.9, .75, .55);
  float topg = glow(length(p - vec2(0., -.2)), .08);
  col = mix(col, wax * (.08 + topg * .9), fill(body, .004));
  // flame
  vec2 fp = p - vec2(0., -.12);
  float flick = sin(t * 7.) * .004 + sin(t * 13.1) * .003 + (fbm(vec2(t * 3., 0.)) - .5) * .02;
  fp.x -= flick * (fp.y + .05) * 4.;
  float fl = sdEll(fp - vec2(0., .055), vec2(.025, .075 + sin(t * 5.) * .004));
  float core = sdEll(fp - vec2(0., .03), vec2(.012, .03));
  col += vec3(2.4, 1.2, .35) * fill(fl, .02) * 1.2;
  col += vec3(2., 1.8, 1.4) * fill(core, .012);
  col += vec3(.2, .3, 1.) * fill(sdEll(fp - vec2(0., -.005), vec2(.01, .012)), .01) * .6;
  col += vec3(1.2, .55, .18) * glow(length(fp - vec2(0., .05)), .14) * .6;
  // wick
  col = mix(col, vec3(0.), fill(sdSeg(fp, vec2(0., -.02), vec2(.002, .015)) - .002, .002) * .8);
  return col;
}
vec3 doorway(vec2 p, float t){
  vec3 col = vec3(.015, .012, .02);
  float door = sdBox(p - vec2(.1, -.05), vec2(.22, .48));
  vec3 warm = vec3(2.2, 1.5, .9);
  col += warm * fill(door, .02) * .9;
  col += warm * glow(max(door, 0.), .05) * .15;
  // light spill on floor
  vec2 fq = p - vec2(.1, -.53);
  float spill = fill(sdBox(vec2(fq.x + fq.y * .9, fq.y), vec2(.22 - fq.y * .6, .2)), .05) * step(p.y, -.53);
  col += warm * spill * .25;
  // mother silhouette in the doorway, one hand on the frame
  float S = .95;
  vec2 sp = (p - vec2(.06, -.53)) / S;
  float sway = sin(t * .6) * .01;
  vec2 hip = vec2(.0, .5), sh = vec2(.01 + sway, .8), head = sh + vec2(.01, .13);
  float fig = sdPose(sp, hip, sh, head, .068,
     vec2(.02, .26), vec2(.03, .01), vec2(-.04, .26), vec2(-.05, .01),
     vec2(.16, .72), vec2(.22, .9), vec2(-.06, .58), vec2(-.04, .45), .095);
  fig = smin(fig, sdEll(sp - head - vec2(-.01, .02), vec2(.085, .09)), .02); // hair
  fig = smin(fig, sdCaps(sp, head + vec2(-.04, -.03), head + vec2(-.05, -.16), .05, .06), .03); // long hair
  fig = smin(fig, sdBox(sp - vec2(0., .38), vec2(.11 - (sp.y - .38) * .15, .14)), .04); // skirt
  fig *= S;
  float m = fill(fig, .006);
  float wrap = smoothstep(-.025, 0., fig);
  col = mix(col, vec3(.02, .015, .015) + warm * wrap * .35, m);
  return col;
}

vec3 scene(vec2 uv, float t){
  vec2 p = cuv(uv);
  p += vec2(sin(t * .4) * .005, cos(t * .3) * .004);
  if (p_var < .5) return water(p, t);
  if (p_var < 1.5) return candle(p, t);
  return doorway(p, t);
}
