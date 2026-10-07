// Infant looking up: leaf light dancing on the ceiling, a mobile, a tiny hand reaching for the light.
uniform float p_hand;   // 0 hidden .. 1 raised
uniform float p_curl;   // finger curl 0..1
uniform float p_focus;

float sdBabyHand(vec2 p, float curl){
  // palm
  float d = sdEll(p - vec2(0., 0.), vec2(.11, .12));
  // wrist / forearm going down
  d = smin(d, sdCaps(p, vec2(0., -.05), vec2(.04, -.6), .085, .11), .05);
  // fingers
  for (int i = 0; i < 4; i++){
    float fi = float(i);
    float a = (fi - 1.5) * .28;
    vec2 base = vec2(sin(a) * .09, .09 + cos(a) * .02);
    float len = (.12 - abs(fi - 1.3) * .018) * (1. - curl * .55);
    vec2 dir = vec2(sin(a * 1.4), cos(a * 1.4));
    vec2 mid = base + dir * len * .55;
    vec2 tip = mid + normalize(dir + vec2(0., -curl * 1.6)) * len * .5;
    d = smin(d, sdCaps(p, base, mid, .03, .027), .02);
    d = smin(d, sdCaps(p, mid, tip, .027, .024), .015);
  }
  // thumb
  vec2 tb = vec2(-.1, -.02);
  vec2 tt = tb + normalize(vec2(-.7, .8) + vec2(curl * .8, -curl * .3)) * .11;
  d = smin(d, sdCaps(p, tb, tt, .038, .028), .03);
  return d;
}

vec3 scene(vec2 uv, float t){
  vec2 p = cuv(uv);
  vec2 q = p + vec2(sin(t * .2) * .02, cos(t * .17) * .015);
  // ceiling, warm cream, light falloff
  vec3 ceil = vec3(.78, .66, .52) * (.55 + .25 * (1. - length(q * vec2(.6, 1.))));
  // leaf light: moving canopy mask -> round sun spots (pinhole)
  float wind = t * .35;
  vec3 light = vec3(0.);
  for (int i = 0; i < 2; i++){
    float fi = float(i);
    vec2 lq = q * (1.5 + fi * .8) + vec2(wind * (.25 + fi * .15), sin(wind * .5 + fi) * .15);
    float canopy = fbm(lq + vec2(fbm(lq * 1.3 + wind * .2), fbm(lq * 1.3 - wind * .2 + 4.)) * .7);
    float spot = smoothstep(.5, .6, canopy);
    light += vec3(1.7, 1.35, .9) * spot * (1. - fi * .5);
  }
  // round discs from pinholes
  light += bokeh(q * .7, 5., 4., .6, vec3(1.6, 1.25, .8), vec3(1.4, 1.1, .7), t, .03) * .12 * (light.r + .2);
  float beam = smoothstep(.9, -.2, q.x + q.y * .6);
  vec3 col = ceil * vec3(.85, .9, 1.) * .36 + ceil * light * beam * .7;
  // mobile: dark shapes hanging, defocused, rotating
  float blurM = mix(.06, .02, p_focus);
  for (int i = 0; i < 4; i++){
    float fi = float(i);
    float ang = t * .25 + fi * TAU / 4.;
    vec2 c = vec2(.2 + cos(ang) * .5, .12 + sin(ang) * .1 + sin(t * .9 + fi) * .01);
    float depth = 1.6 + .5 * sin(ang);
    float sh;
    if (i == 0) sh = sdCircle(p - c, .06 * depth) ; // moon
    else if (i == 1) { vec2 s = (p - c) * rot(t * .3); float a = atan(s.y, s.x); float r = length(s); sh = r - .055 * depth * (.65 + .35 * cos(a * 5.)); } // star
    else if (i == 2) sh = sdEll(p - c, vec2(.08, .03) * depth); // fish/cloud
    else sh = sdCaps(p, c - vec2(.04, 0), c + vec2(.04, .01), .025 * depth, .02 * depth);
    float str = sdSeg(p, c, vec2(c.x, .6));
    vec3 mc = (i == 0) ? vec3(.95, .82, .45) : (i == 1 ? vec3(.5, .62, .85) : (i == 2 ? vec3(.85, .45, .4) : vec3(.55, .75, .55)));
    float m = fill(sh, blurM * max(.3, 2.2 - depth));
    vec3 shd = mc * (.25 + .45 * sqrt(inner(sh, .05 * depth))) * (.7 + .5 * light.r * .5);
    col = mix(col, shd, m * .95);
    col = mix(col, vec3(.15), fill(str - .0015, .004) * .4);
  }
  // baby hand rising from bottom
  float hy = mix(-1.1, -.12, p_hand);
  vec2 hp = (p - vec2(-.3 + sin(t * .8) * .03, hy)) * rot(.25 + sin(t * .6) * .08) / 1.9;
  float hd = sdBabyHand(hp, p_curl) * 1.9;
  float hblur = mix(.04, .008, p_focus);
  float hm = fill(hd, hblur);
  vec3 skin = vec3(1., .66, .5);
  float sss = smoothstep(-.04, 0., hd);
  float shade = .55 + .45 * sat(hp.x * 3. + .5);
  float vol = sqrt(inner(hd, .09));
  vec3 hc = skin * (.12 + .3 * shade * (.4 + .6 * vol)) + vec3(1., .4, .22) * sss * .35 * (1. + light.r * .3);
  col = mix(col, hc, hm);
  col += dust(p, t, 3., .25) * .25 * beam;
  return col;
}
