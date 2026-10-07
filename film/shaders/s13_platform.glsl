// Twenty-three. Side view across the tracks at night. The train, his silhouette in a window. It leaves.
uniform float p_train;  // 0 stopped .. 1 gone (position eased)
uniform float p_look;   // his hand on the glass

vec3 farPlatform(vec2 p, float t){
  vec3 col = vec3(.012, .016, .022);
  // back wall with posters, lamps
  col += vec3(.05, .07, .07) * smoothstep(-.1, .3, p.y);
  float lampX = fract(p.x * .9 + .5) - .5;
  vec2 lp = vec2(lampX / .9, p.y - .32);
  col += vec3(.8, 1., .9) * fill(sdBox(lp, vec2(.12, .006)), .002) * 1.5;
  col += vec3(.25, .35, .32) * glow(abs(lp.y), .06) * smoothstep(.25, 0., abs(lp.x)) * .5;
  // light cone onto platform
  float cone = smoothstep(.25 + (.32 - p.y) * .3, 0., abs(lp.x)) * step(p.y, .32) * step(-.15, p.y);
  col += vec3(.15, .2, .19) * cone * .35;
  // bench
  float bench = min(sdBox(p - vec2(.3, -.08), vec2(.14, .008)), min(sdBox(p - vec2(.2, -.12), vec2(.006, .04)), sdBox(p - vec2(.4, -.12), vec2(.006, .04))));
  bench = min(bench, sdBox(p - vec2(.3, -.04), vec2(.14, .006)));
  col = mix(col, vec3(.01), fill(bench, .002));
  // platform edge
  col = mix(col, vec3(.05, .055, .06), fill(abs(p.y + .17) - .012, .002));
  col += vec3(.6, .5, .15) * fill(abs(p.y + .158) - .002, .001) * .4;
  // posters
  for (int i = 0; i < 3; i++){ float fi = float(i); col = mix(col, vec3(.15, .1, .08) + .05 * h33(vec3(fi)).xyz, fill(sdBox(p - vec2(-.8 + fi * .7, .1), vec2(.09, .12)), .002) * .6); }
  return col;
}

vec3 scene(vec2 uv, float t){
  vec2 p = cuv(uv);
  vec3 col = farPlatform(p, t);
  // tracks bed
  col = mix(col, vec3(.01, .01, .012), step(p.y, -.19));
  col += vec3(.4, .45, .45) * smoothstep(.003, 0., abs(p.y + .3)) * .4;
  // the train: carriage body spans y in [-.28, .3], moves left
  float pos = p_train * p_train * 9.;
  float x = p.x + pos;
  float car = fract(x * .42);
  float inBody = step(-.28, p.y) * step(p.y, .3) * step(.015, car) * step(car, .985);
  float gap = 1. - step(.015, car) * step(car, .985);
  vec3 body = vec3(.08, .09, .1) + vec3(.06) * smoothstep(.3, .1, p.y);
  // windows
  float wx = fract(x * .42 * 6.);
  float winM = step(.12, wx) * step(wx, .88) * step(-.02, p.y) * step(p.y, .2) * step(.06, car) * step(car, .94);
  vec3 inside = vec3(1.2, 1.1, .85) * .55 + vec3(.2) * smoothstep(.2, -.02, p.y);
  // passengers
  float wid = floor(x * .42 * 6.);
  vec3 wn = h33(vec3(wid, 4., 0.));
  float pass = 1e5;
  // him: in the window that is at center when the train is stopped
  bool him = wid == floor(.0 * .42 * 6. + .5 * 0.) + 0.;
  vec2 wc = vec2((wid + .5) / (.42 * 6.) - pos, .0);
  vec2 lp = p - wc;
  if (abs(wid - 1.) < .5){
    pass = sdCircle(lp - vec2(.0, .1), .045);
    pass = smin(pass, sdBox(lp - vec2(0., -.0), vec2(.06, .06)) - .02, .03);
    pass = smin(pass, sdCaps(lp, vec2(.05, .02), vec2(.07, .12 + p_look * .04), .015, .013), .02);
  } else if (wn.x > .55){
    pass = sdCircle(lp - vec2((wn.y - .5) * .1, .06), .035);
    pass = smin(pass, sdBox(lp - vec2((wn.y - .5) * .1, -.03), vec2(.05, .05)) - .01, .03);
  }
  inside = mix(inside, vec3(.06, .05, .05), fill(pass, .003));
  vec3 tc = mix(body, inside, winM);
  // motion blur when fast
  float sp = 2. * p_train * 9. * .05;
  tc = mix(tc, vec3(.22, .21, .18), sat(sp * 1.5 - .4) * .5);
  float gone = smoothstep(.85, 1., p_train);
  float trainA = inBody * (1. - gone);
  col = mix(col, tc, trainA);
  col = mix(col, col * .3, gap * step(-.28, p.y) * step(p.y, .3) * (1. - gone) * .7);
  // our platform edge in the foreground (bottom), with yellow line
  col = mix(col, vec3(.03, .033, .036) * (1. + fbm(p * 30.) * .3), step(p.y, -.36));
  col += vec3(.9, .75, .2) * fill(abs(p.y + .38) - .004, .002) * .5;
  // overhead lamp spill on our side
  col += vec3(.2, .26, .25) * smoothstep(-.36, -.5, p.y) * .25;
  return col;
}
