// The garden at golden hour. var 0: grandfather + Lucía (6) plant a seed.
// var 1: old Lucía + granddaughter, the same gesture, under the grown lemon tree.
// var 2: morning, no people, the tree and a new sprout (epilogue).
uniform float p_var;
uniform float p_dig;   // digging gesture intensity
uniform float p_seed;  // child's hand reaching down with seed 0..1
uniform float p_cam;   // slow camera push

float grassLine(vec2 p, float base, float seed, float t, float dens){
  float x = p.x * dens;
  float id = floor(x);
  float d = 1e5;
  for (int i = -1; i <= 1; i++){
    float cid = id + float(i);
    float r = h11(cid * 1.31 + seed);
    float bx = (cid + .5 + (r - .5) * .8) / dens;
    float hgt = (.015 + .05 * pow(h11(cid * 7.1 + seed), 2.)) ;
    float bend = sin(t * 1.2 + cid * .7) * .012 + (r - .5) * .03;
    vec2 a = vec2(bx, base), b = vec2(bx + bend * 2., base + hgt);
    d = min(d, sdCaps(p, a, b, .004, .0005));
  }
  return d;
}

float figures(vec2 p, float gy, float S, float t, float var){
  vec2 ap = (p - vec2(-.22, gy)) / S;
  float dg = sin(t * 2.2) * p_dig;
  float old = var > .5 ? 1. : .85;
  vec2 hip = vec2(0., .28), sh = vec2(.12, .58) + vec2(.03, -.04) * old, head = sh + vec2(.07, .1);
  float adult = sdPose(ap, hip, sh, head, .062,
    vec2(.03, .03), vec2(-.2, .02),
    vec2(.22, .27), vec2(.22, .01),
    vec2(.25, .4), vec2(.37, .1 + dg * .04),
    vec2(.22, .37 + dg * .03), vec2(.34, .08 - dg * .03), .08);
  if (var < .5) adult = min(adult, min(sdEll(ap - head - vec2(.0, .03), vec2(.095, .012)), sdEll(ap - head - vec2(-.005, .05), vec2(.055, .035))));
  else adult = smin(adult, sdCircle(ap - head - vec2(-.055, .03), .035), .02);
  vec2 cp = (p - vec2(.24, gy)) / S;
  cp.x = -cp.x;
  float reach = p_seed;
  vec2 chip = vec2(0., .2), csh = vec2(.06, .38), chead = csh + vec2(.035, .095);
  float child = sdPose(cp, chip, csh, chead, .066,
    vec2(.12, .2), vec2(.06, .01), vec2(.15, .16), vec2(.11, .01),
    vec2(.15, .3), mix(vec2(.2, .3), vec2(.27, .14), reach),
    vec2(.11, .28), vec2(.17, .24), .065);
  child = smin(child, sdCaps(cp, chead + vec2(-.06, .0), chead + vec2(-.075, -.075 + sin(t * 2.) * .004), .025, .018), .02);
  return min(adult, child) * S;
}

vec3 scene(vec2 uv, float t){
  vec2 p = cuv(uv);
  float zoom = 1. - p_cam * .12;
  p *= zoom;
  p.x += p_cam * .05;
  float var = p_var;
  bool morning = var > 1.5;
  // sky
  vec3 top = morning ? vec3(.45, .62, .85) : vec3(.35, .45, .65);
  vec3 hor = morning ? vec3(1.7, 1.35, .9) : vec3(1.9, 1.05, .45);
  vec3 col = mix(hor, top, sat((p.y + .2) * 1.3));
  vec2 sunp = morning ? vec2(.72, .1) : vec2(.62, -.08);
  float sd = length(p - sunp);
  col += vec3(2.5, 1.6, .7) * glow(sd, .05) * (morning ? .7 : .8);
  if (morning){ float ang = atan(p.y - sunp.y, p.x - sunp.x); col += vec3(1.4, 1.1, .7) * pow(sat(sin(ang * 14. + sin(t * .2) * .3) * .5 + .5), 3.) * exp(-sd * 2.2) * .1 * step(-.3, p.y); }
  col += vec3(4., 3., 1.8) * smoothstep(.045, .04, sd) * (morning ? .5 : 1.);
  // distant trees, hazy
  float far = -.12 + .08 * fbm(vec2(p.x * 3., 1.)) + .03 * fbm(vec2(p.x * 12., 4.));
  vec3 haze = mix(hor * .6, top * .7, .3);
  col = mix(col, haze * vec3(.75, .7, .6), fill(p.y - far, .01) * .8);
  float mid = -.2 + .05 * fbm(vec2(p.x * 5. + 3., 2.));
  col = mix(col, haze * .4, fill(p.y - mid, .006) * .9);
  // ground
  float gy = -.3 + .015 * sin(p.x * 2.);
  vec3 groundC = morning ? vec3(.07, .09, .035) : vec3(.05, .03, .02);
  float gm = fill(p.y - gy, .003);
  if (morning) groundC += vec3(.25, .22, .08) * smoothstep(-.6, gy, p.y) * .4;
  // ground lit faintly
  vec3 gcol = groundC + vec3(.4, .25, .1) * glow(length(p - vec2(sunp.x, gy)), .25) * .3 * float(!morning);
  col = mix(col, gcol, gm);
  // tree (var 1/2: grown; var 0: none, just fence)
  vec3 rimC = morning ? vec3(1.4, 1.3, 1.1) : vec3(2.2, 1.3, .55);
  if (var > .5){
    vec2 tp = p - vec2(-.62, gy);
    float g = .78;
    float tr = sdTree(tp, g, 4., t * .5);
    float can = treeCanopy(tp - vec2(0., .02), g * 1.05, 2., t);
    vec3 leaf = morning ? vec3(.04, .08, .03) : vec3(.03, .035, .015);
    col = mix(col, leaf, can);
    // rim light on canopy edges
    float edge = can * (1. - treeCanopy(tp - (sunp - vec2(-.62, gy)) * .015, g * 1.05, 2., t));
    col += rimC * edge * .5;
    col = mix(col, vec3(.02, .015, .01), fill(tr, .003) * (1. - can * .8));
    // lemons
    vec2 lq = tp / g * 9.;
    vec2 lid = floor(lq);
    vec3 ln = h33(vec3(lid, 5.));
    vec2 lc = lid + .5 + (ln.xy - .5) * .5;
    float lemon = fill(sdEll((lq - lc) * rot(ln.z * 3.), vec2(.16, .12)), .04) * step(.62, ln.z) * can;
    col = mix(col, vec3(.9, .7, .1) * (morning ? .8 : .45) + rimC * .12, lemon);
  }
  // figures
  if (var < 1.5){
    float S = .62;
    float figs = figures(p, gy, S, t, var);
    vec3 figC = vec3(.035, .02, .015);
    float fm = fill(figs, .0025);
    vec2 eo = normalize(sunp - p) * .005;
    float rimA = fm * (1. - fill(figures(p + eo, gy, S, t, var), .002));
    col = mix(col, figC, fm);
    col += rimC * rimA * .6;
    // seed glint
    float reach = p_seed;
    vec2 seedP = vec2(.24, gy) + vec2(-mix(.2, .27, reach), mix(.3, .14, reach)) * S + vec2(-.01, -.006);
    col += vec3(2., 1.4, .7) * glow(length(p - seedP), .004) * reach * .5;
    col = mix(col, gcol * 1.2, fill(sdEll(p - vec2(.03, gy), vec2(.05, .012)), .003));
  } else {
    // sprout beside the big tree
    vec2 sp = p - vec2(.15, gy);
    float stem = sdCaps(sp, vec2(0.), vec2(.004 + sin(t) * .002, .05), .003, .002);
    float l1 = sdEll((sp - vec2(-.014, .05)) * rot(.6), vec2(.016, .006));
    float l2 = sdEll((sp - vec2(.014, .055)) * rot(-.6), vec2(.016, .006));
    float spr = min(stem, min(l1, l2));
    col = mix(col, vec3(.05, .12, .03), fill(spr, .0015));
    col += vec3(.7, 1., .5) * (fill(spr + .002, .002) - fill(spr + .004, .002)) * .3;
  }
  // foreground grass (out of focus)
  float gl = min(grassLine(p, gy - .005, 1., t, 140.), grassLine(p + vec2(.003, 0.), gy - .005, 9., t, 110.));
  col = mix(col, gcol * .8, fill(gl, .0015));
  float gf = grassLine(p * .6 + vec2(0., .0), -.5 * .6 - .02, 3., t, 30.);
  col = mix(col, vec3(.01, .008, .005), fill(gf, .01) * .9);
  // floating pollen in the light
  col += dust(p, t * .6, 4., .2) * rimC * .18 * smoothstep(1., -.2, length(p - sunp));
  return col;
}
