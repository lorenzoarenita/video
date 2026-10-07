// A toddler at the window at night. The moon. A father's hand points at it.
uniform float p_point;   // father's hand 0..1
uniform float p_cloud;   // cloud cover
uniform float p_moonx;

vec3 scene(vec2 uv, float t){
  vec2 p = cuv(uv);
  p += vec2(sin(t * .3) * .006, sin(t * .23) * .004);
  // sky
  vec3 col = mix(vec3(.01, .02, .06), vec3(.05, .09, .2), sat(.6 - p.y));
  // stars
  vec2 sq = p * 160.; vec2 sid = floor(sq); vec3 sn = h33(vec3(sid, 1.));
  float star = smoothstep(.12, 0., length(fract(sq) - .5 - (sn.xy - .5) * .6)) * step(.985, sn.z);
  col += vec3(.8, .85, 1.) * star * (.6 + .4 * sin(t * 2. + sn.x * 50.));
  // moon
  vec2 mc = vec2(.35 + p_moonx, .2);
  float md = length(p - mc);
  float mr = .085;
  float crater = fbm((p - mc) * 30. + 3.) ;
  vec3 moon = vec3(1.25, 1.22, 1.08) * (.6 + .5 * crater) * smoothstep(mr, mr - .003, md);
  col += moon;
  col += vec3(.35, .45, .7) * glow(md, .12) * .35 + vec3(.6, .65, .8) * glow(md, .03) * .3;
  // clouds drifting
  float cl = fbm(p * vec2(2.5, 6.) + vec2(t * .03, 0.)) ;
  float cm = smoothstep(.55 - p_cloud * .2, .8, cl) * smoothstep(-.1, .3, p.y);
  vec3 cc = vec3(.08, .1, .18) + vec3(.6, .65, .8) * glow(md, .2) * .6;
  col = mix(col, cc, cm * .85);
  // rooftops silhouettes
  float x = p.x * 3.;
  float fx = fract(x); float hx = h11(floor(x));
  float roof = -.3 + .05 * hx + (hx > .5 ? .06 * (1. - abs(fx - .5) * 2.) : 0.);
  float chim = step(.8, h11(floor(x * 4.) + 3.)) * .04;
  float rd = p.y - (roof + chim);
  col = mix(col, vec3(.01, .012, .025), fill(rd, .002));
  // a few lit windows in houses
  vec2 wq = vec2(p.x * 24., (p.y + .35) * 24.);
  vec3 wn = h33(vec3(floor(wq), 7.));
  float wl = step(.92, wn.x) * step(fract(wq.x), .6) * step(fract(wq.y), .5) * step(p.y, roof - .02);
  col += vec3(1.2, .7, .3) * wl * .6 * (.8 + .2 * sin(t + wn.y * 10.));
  // branch silhouette top-left
  vec2 bp = p - vec2(-1.1, .55);
  float br = sdCaps(bp, vec2(0.), vec2(.6, -.25), .025, .01);
  br = min(br, sdCaps(bp, vec2(.3, -.12), vec2(.45, -.02), .01, .004));
  br = min(br, sdCaps(bp, vec2(.42, -.19), vec2(.58, -.35), .01, .004));
  for (int i = 0; i < 9; i++){ float fi = float(i); vec2 lp = vec2(.08 + fi * .06, -.05 - fi * .025 + sin(fi * 3.) * .04) + vec2(sin(t * .8 + fi) * .004, 0.); br = min(br, sdEll((bp - lp) * rot(fi), vec2(.03, .012))); }
  col = mix(col, vec3(.005, .008, .015), fill(br, .004));
  // window frame (soft focus foreground)
  float fr = min(abs(p.x - .0) - .018, abs(p.y + .02) - .014);
  float outer = -sdBox(p, vec2(.95, .44));
  fr = min(fr, outer);
  col = mix(col, vec3(.02, .02, .03) + vec3(.05, .06, .1) * (1. - abs(p.x)), fill(fr, .012));
  // reflection of warm room lamp on glass
  col += vec3(.25, .15, .06) * glow(length(p - vec2(-.7, -.3)), .25) * .25;
  // father's hand pointing from right
  vec2 hp = p - vec2(mix(1.7, .62, p_point), -.12 + sin(t * .5) * .005);
  hp *= rot(-.42);
  float arm = sdCaps(hp, vec2(.05, 0.), vec2(.9, -.1), .085, .13);
  float fist = sdEll(hp - vec2(-.01, 0.), vec2(.115, .085));
  float finger = sdCaps(hp, vec2(-.06, .04), vec2(-.25, .07), .03, .024);
  float thumb = sdCaps(hp, vec2(-.03, .07), vec2(-.1, .1), .03, .025);
  float knuck = sdCaps(hp, vec2(-.07, -.0), vec2(-.1, -.03), .035, .03);
  float hand = smin(smin(smin(smin(arm, fist, .06), finger, .03), thumb, .02), knuck, .03);
  float sleeve = sdCaps(hp, vec2(.35, -.06), vec2(1.2, -.2), .14, .19);
  hand = min(hand, sleeve);
  vec3 hcol = vec3(.025, .025, .04) + vec3(.25, .28, .45) * smoothstep(-.025, 0., hand) * .5;
  col = mix(col, hcol, fill(hand, .012));
  return col;
}
