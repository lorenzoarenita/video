// Shared library for all scenes.
#define PI 3.14159265
#define TAU 6.2831853

float sat(float x){ return clamp(x, 0., 1.); }
float h11(float p){ p = fract(p * .1031); p *= p + 33.33; p *= p + p; return fract(p); }
float h21(vec2 p){ vec3 p3 = fract(vec3(p.xyx) * .1031); p3 += dot(p3, p3.yzx + 33.33); return fract((p3.x + p3.y) * p3.z); }
vec2 h22(vec2 p){ vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973)); p3 += dot(p3, p3.yzx + 33.33); return fract((p3.xx + p3.yz) * p3.zy); }
vec3 h33(vec3 p3){ p3 = fract(p3 * vec3(.1031, .1030, .0973)); p3 += dot(p3, p3.yxz + 33.33); return fract((p3.xxy + p3.yxx) * p3.zyx); }

float vnoise(vec2 p){
  vec2 i = floor(p), f = fract(p); vec2 u = f * f * (3. - 2. * f);
  return mix(mix(h21(i), h21(i + vec2(1, 0)), u.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), u.x), u.y);
}
float vnoise3(vec3 p){
  vec3 i = floor(p), f = fract(p); vec3 u = f * f * (3. - 2. * f);
  float n000 = h33(i).x, n100 = h33(i + vec3(1,0,0)).x, n010 = h33(i + vec3(0,1,0)).x, n110 = h33(i + vec3(1,1,0)).x;
  float n001 = h33(i + vec3(0,0,1)).x, n101 = h33(i + vec3(1,0,1)).x, n011 = h33(i + vec3(0,1,1)).x, n111 = h33(i + vec3(1,1,1)).x;
  return mix(mix(mix(n000, n100, u.x), mix(n010, n110, u.x), u.y), mix(mix(n001, n101, u.x), mix(n011, n111, u.x), u.y), u.z);
}
float fbm(vec2 p){ float a = .5, s = 0.; mat2 m = mat2(1.6, 1.2, -1.2, 1.6); for (int i = 0; i < 5; i++){ s += a * vnoise(p); p = m * p; a *= .5; } return s; }
float fbm3(vec3 p){ float a = .5, s = 0.; for (int i = 0; i < 5; i++){ s += a * vnoise3(p); p = p * 2.03 + vec3(1.7, 9.2, 3.1); a *= .5; } return s; }
mat2 rot(float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// aspect-corrected centered coords: y in [-.5,.5]
vec2 cuv(vec2 uv){ return (uv - .5) * vec2(uRes.x / uRes.y, 1.); }
float ASP(){ return uRes.x / uRes.y; }

// --- SDF 2D ---
float sdCircle(vec2 p, float r){ return length(p) - r; }
float sdBox(vec2 p, vec2 b){ vec2 d = abs(p) - b; return length(max(d, 0.)) + min(max(d.x, d.y), 0.); }
float sdSeg(vec2 p, vec2 a, vec2 b){ vec2 pa = p - a, ba = b - a; float h = sat(dot(pa, ba) / dot(ba, ba)); return length(pa - ba * h); }
float sdCaps(vec2 p, vec2 a, vec2 b, float ra, float rb){ vec2 pa = p - a, ba = b - a; float h = sat(dot(pa, ba) / dot(ba, ba)); return length(pa - ba * h) - mix(ra, rb, h); }
float sdEll(vec2 p, vec2 r){ float k = length(p / r); return (k - 1.) * min(r.x, r.y); }
float smin(float a, float b, float k){ float h = sat(.5 + .5 * (b - a) / k); return mix(b, a, h) - k * h * (1. - h); }
float fill(float d, float aa){ aa = max(abs(aa), 1e-4); return 1. - smoothstep(-aa, aa, d); }
// volumetric shading inside an SDF shape: 0 at edge -> 1 deep inside
float inner(float d, float w){ return sat(-d / w); }

// --- Human silhouette ---
// p: local coords, feet at y=0, height ~1. pose: x=arm swing, y=lean/stoop, z=walk phase, w=child(0..1)
float sdFigure(vec2 p, vec4 pose){
  float child = pose.w;
  float headR = mix(.075, .105, child);
  float h = 1.;
  float stoop = pose.y;
  float leg = mix(.47, .40, child);
  float torsoTop = mix(.82, .74, child);
  vec2 hip = vec2(stoop * .05, leg);
  vec2 sh = vec2(stoop * .22, torsoTop - stoop * .06);
  vec2 head = sh + vec2(stoop * .1, headR + .05 - stoop * .03);
  float d = sdCircle(p - head, headR);
  d = smin(d, sdCaps(p, sh + vec2(0., .02), sh + vec2(0, .06), .035, .03), .03); // neck
  d = smin(d, sdCaps(p, hip, sh, .085, .095), .04); // torso
  float ph = pose.z;
  float sw = sin(ph) * .16;
  vec2 kneeL = hip + vec2(sw * .7, -leg * .5), kneeR = hip + vec2(-sw * .7, -leg * .5);
  vec2 footL = vec2(hip.x + sw * 1.2, .02 + max(0., sin(ph)) * .04), footR = vec2(hip.x - sw * 1.2, .02 + max(0., -sin(ph)) * .04);
  d = smin(d, sdCaps(p, hip + vec2(.03, 0), kneeL, .055, .04), .02);
  d = smin(d, sdCaps(p, kneeL, footL, .04, .03), .02);
  d = smin(d, sdCaps(p, hip - vec2(.03, 0), kneeR, .055, .04), .02);
  d = smin(d, sdCaps(p, kneeR, footR, .04, .03), .02);
  float as = pose.x;
  vec2 elL = sh + vec2(.07 + as * .1, -.22), elR = sh + vec2(-.07 - as * .1, -.22);
  vec2 haL = elL + vec2(.02 + as * .15, -.2 + abs(as) * .05), haR = elR + vec2(-.02 - as * .15, -.2 + abs(as) * .05);
  d = smin(d, sdCaps(p, sh + vec2(.08, -.01), elL, .035, .03), .03);
  d = smin(d, sdCaps(p, elL, haL, .03, .025), .02);
  d = smin(d, sdCaps(p, sh + vec2(-.08, -.01), elR, .035, .03), .03);
  d = smin(d, sdCaps(p, elR, haR, .03, .025), .02);
  return d;
}
// Generic figure with explicit arm targets (in local coords) for gestures (holding hands, reaching)
float sdFigureArms(vec2 p, float stoop, float child, vec2 handL, vec2 handR, float walk){
  float headR = mix(.075, .105, child);
  float leg = mix(.47, .40, child);
  float torsoTop = mix(.82, .74, child);
  vec2 hip = vec2(stoop * .05, leg);
  vec2 sh = vec2(stoop * .22, torsoTop - stoop * .06);
  vec2 head = sh + vec2(stoop * .1, headR + .05 - stoop * .03);
  float d = sdCircle(p - head, headR);
  d = smin(d, sdCaps(p, sh + vec2(0., .02), sh + vec2(0, .06), .035, .03), .03);
  d = smin(d, sdCaps(p, hip, sh, .085, .095), .04);
  float sw = sin(walk) * .16;
  vec2 kneeL = hip + vec2(sw * .7, -leg * .5), kneeR = hip + vec2(-sw * .7, -leg * .5);
  vec2 footL = vec2(hip.x + sw * 1.2, .02 + max(0., sin(walk)) * .04), footR = vec2(hip.x - sw * 1.2, .02 + max(0., -sin(walk)) * .04);
  d = smin(d, sdCaps(p, hip + vec2(.03, 0), kneeL, .055, .04), .02);
  d = smin(d, sdCaps(p, kneeL, footL, .04, .03), .02);
  d = smin(d, sdCaps(p, hip - vec2(.03, 0), kneeR, .055, .04), .02);
  d = smin(d, sdCaps(p, kneeR, footR, .04, .03), .02);
  for (int i = 0; i < 2; i++){
    vec2 s = sh + vec2(i == 0 ? .08 : -.08, -.01);
    vec2 hnd = i == 0 ? handL : handR;
    vec2 m = (s + hnd) * .5; vec2 dir = hnd - s; float L = length(dir);
    float bend = sqrt(max(0., .42 * .42 * .25 - L * L * .25));
    vec2 nrm = normalize(vec2(-dir.y, dir.x)) * (i == 0 ? -1. : 1.);
    vec2 el = m + nrm * bend * .6;
    d = smin(d, sdCaps(p, s, el, .035, .03), .03);
    d = smin(d, sdCaps(p, el, hnd, .03, .025), .02);
  }
  return d;
}

// --- Bokeh field: soft discs of out-of-focus light ---
vec3 bokeh(vec2 p, float seed, float density, float size, vec3 c1, vec3 c2, float t, float drift){
  vec3 acc = vec3(0.);
  for (int L = 0; L < 3; L++){
    float fl = float(L);
    float sc = density * (1. + fl * .7);
    vec2 q = p * sc + vec2(seed * 13.1 + fl * 7.3, fl * 3.1) + vec2(t * drift * (1. + fl * .3), sin(t * .1 + fl) * drift);
    vec2 id = floor(q);
    for (int j = -1; j <= 1; j++) for (int i = -1; i <= 1; i++){
      vec2 cid = id + vec2(i, j);
      vec3 rnd = h33(vec3(cid, seed + fl * 17.));
      if (rnd.z < .45) continue;
      float r = min(size * (.45 + .55 * rnd.x) * (1. + fl * .15), .95);
      vec2 c = cid + .5 + (rnd.xy - .5) * max(0., 1. - r) * .9;
      float dd = length(q - c);
      float disc = smoothstep(r, r * .82, dd);
      float ring = smoothstep(r * .7, r * .95, dd) * disc * .5;
      float flick = .75 + .25 * sin(t * (1. + rnd.y * 2.) + rnd.x * 30.);
      vec3 col = mix(c1, c2, rnd.y);
      acc += col * (disc * .6 + ring) * flick * (.5 + rnd.z) / (1. + fl * .8);
    }
  }
  return acc;
}

// --- Eyelids (POV) ---  open: 0 closed .. 1 fully open. returns mask (1 = visible)
float eyelids(vec2 uv, float open, float soft){
  vec2 p = cuv(uv);
  float o = open * .75;
  float curve = p.x * p.x * .22;
  float top = .62 * o - curve + .02;
  float bot = -.62 * o + curve * .6 - .04;
  float m = smoothstep(top + soft, top - soft, p.y) * smoothstep(bot - soft, bot + soft, p.y);
  return m * smoothstep(0., .08, open);
}

// --- Soft light helpers ---
float glow(float d, float r){ return r * r / (d * d + r * r); }
vec3 skyGrad(float y, vec3 top, vec3 mid, vec3 hor){ return y > 0. ? mix(mid, top, sat(y)) : mix(mid, hor, sat(-y * 3.)); }

// --- Text-free film tools ---
float lineMask(float d, float w){ return smoothstep(w, 0., abs(d)); }

// --- Tree silhouette (branches + leaf canopy). base at origin, height ~1*g ---
float sdTree(vec2 p, float g, float seed, float wind){
  float d = 1e5;
  // trunk
  float th = .32 * g;
  d = sdCaps(p, vec2(0), vec2(.02 * g, th), .045 * g, .03 * g);
  // branches: 3 levels procedurally
  for (int i = 0; i < 6; i++){
    float fi = float(i);
    float a = (h11(fi + seed) - .5) * 1.9 + sin(wind + fi) * .03;
    vec2 b0 = vec2(.02 * g, th * (.55 + .45 * h11(fi * 3.1 + seed)));
    vec2 dir = vec2(sin(a), cos(a));
    float len = (.28 + .2 * h11(fi * 7.7 + seed)) * g;
    vec2 b1 = b0 + dir * len;
    d = min(d, sdCaps(p, b0, b1, .022 * g, .01 * g));
    for (int k = 0; k < 2; k++){
      float a2 = a + (float(k) - .5) * 1.1 + (h11(fi * 11. + float(k) + seed) - .5) * .4;
      vec2 c0 = mix(b0, b1, .6 + .3 * float(k));
      vec2 c1 = c0 + vec2(sin(a2), cos(a2)) * len * .55;
      d = min(d, sdCaps(p, c0, c1, .011 * g, .005 * g));
    }
  }
  return d;
}
float treeCanopy(vec2 p, float g, float seed, float t){
  // returns density 0..1 of foliage
  vec2 q = p / max(g, .001);
  vec2 c = vec2(0., .62);
  float sh = length((q - c) * vec2(.85, 1.15));
  float n = fbm(q * 7. + vec2(seed, t * .15)) * .6 + fbm(q * 18. + vec2(t * .3, seed)) * .4;
  return smoothstep(.48, .38, sh + (n - .5) * .35);
}

// --- Rain drops on glass: returns refraction offset in xy, wetness in z ---
vec3 rainGlass(vec2 uv, float t, float amount){
  vec2 asp = vec2(ASP(), 1.);
  vec3 acc = vec3(0.);
  for (int L = 0; L < 3; L++){
    float fl = float(L);
    vec2 gs = vec2(12., 3.5) * (1. + fl * .8);
    vec2 q = uv * asp * gs;
    q.y += t * (.25 + fl * .07) ;
    vec2 id = floor(q);
    vec3 n = h33(vec3(id, fl * 9.1));
    if (n.z > amount) continue;
    vec2 st = fract(q) - .5;
    float tt = t * (.4 + n.x) + n.y * 6.28;
    float y = -sin(tt + sin(tt + sin(tt) * .5)) * .43;
    float x = (n.x - .5) * .6 + sin(q.y * 3.) * .05;
    vec2 dp = (st - vec2(x, y)) / gs * gs.x / 12.;
    vec2 dpa = (st - vec2(x, y)) * vec2(1., gs.x / gs.y);
    float drop = smoothstep(.09, .05, length(dpa * vec2(1., .9)) );
    float trail = smoothstep(.04, .02, abs(st.x - x)) * smoothstep(y, y + .5, st.y) * smoothstep(.5, y, st.y) * .6;
    float tdrops = smoothstep(.03, .01, length(vec2(st.x - x, fract(st.y * 8.) - .5) * vec2(1., 1. / 8.)*vec2(1.,8.))) * trail;
    acc.xy += dpa * drop * .5 + vec2(0.) ;
    acc.z = max(acc.z, max(drop, tdrops));
  }
  // static droplets
  vec2 q = uv * asp * 40.;
  vec2 id = floor(q); vec3 n = h33(vec3(id, 3.3));
  vec2 st = fract(q) - .5 - (n.xy - .5) * .6;
  float sd = smoothstep(.22, .12, length(st)) * step(n.z, amount * .6) * fract(n.z * 25. - t * .05 + 10.);
  sd = smoothstep(.0, .2, sd) * smoothstep(.0, .2, sd);
  acc.xy += st * sd * .3;
  acc.z = max(acc.z, sd);
  return acc;
}

// Particles: dust motes in a beam
vec3 dust(vec2 p, float t, float seed, float dens){
  vec3 acc = vec3(0.);
  for (int L = 0; L < 3; L++){
    float fl = float(L);
    vec2 q = p * (18. + fl * 14.) + vec2(t * (.08 + fl * .03), t * (.05 + .02 * fl)) * (10. + fl * 5.) + seed;
    vec2 id = floor(q);
    vec3 n = h33(vec3(id, fl + seed));
    if (n.z > dens) continue;
    vec2 c = .5 + (n.xy - .5) * .7 + .15 * vec2(sin(t * .7 + n.x * 9.), cos(t * .5 + n.y * 9.));
    float d = length(fract(q) - c);
    acc += vec3(1.) * smoothstep(.07, .0, d) * (.4 + .6 * n.y) / (1. + fl);
  }
  return acc;
}

// Fully poseable silhouette. j: hip, shoulder, head, kneeL, footL, kneeR, footR, elbowL, handL, elbowR, handR
float sdPose(vec2 p, vec2 hip, vec2 sh, vec2 head, float hr, vec2 kL, vec2 fL, vec2 kR, vec2 fR, vec2 eL, vec2 hL, vec2 eR, vec2 hR, float th){
  float d = sdCircle(p - head, hr);
  d = smin(d, sdCaps(p, mix(sh, head, .2), mix(sh, head, .75), .32 * th, .28 * th), .3 * th);
  d = smin(d, sdCaps(p, hip, sh, .85 * th, .95 * th), .4 * th);
  d = smin(d, sdCaps(p, hip, kL, .55 * th, .42 * th), .2 * th);
  d = smin(d, sdCaps(p, kL, fL, .42 * th, .3 * th), .2 * th);
  d = smin(d, sdCaps(p, hip, kR, .55 * th, .42 * th), .2 * th);
  d = smin(d, sdCaps(p, kR, fR, .42 * th, .3 * th), .2 * th);
  d = smin(d, sdCaps(p, fL, fL + vec2(.5 * th * sign(fL.x - kL.x + .001) * step(-.05, fL.x - kL.x) , 0.), .25 * th, .2 * th), .1 * th);
  d = smin(d, sdCaps(p, fR, fR + vec2(.5 * th * sign(fR.x - kR.x + .001) * step(-.05, fR.x - kR.x), 0.), .25 * th, .2 * th), .1 * th);
  d = smin(d, sdCaps(p, sh, eL, .36 * th, .3 * th), .25 * th);
  d = smin(d, sdCaps(p, eL, hL, .3 * th, .24 * th), .15 * th);
  d = smin(d, sdCaps(p, sh, eR, .36 * th, .3 * th), .25 * th);
  d = smin(d, sdCaps(p, eR, hR, .3 * th, .24 * th), .15 * th);
  return d;
}
