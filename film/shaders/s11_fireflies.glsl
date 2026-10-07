// Nineteen. A hill at night, the Milky Way, fireflies. Two silhouettes sitting close.
uniform float p_lean;  // she leans her head on his shoulder
uniform float p_cam;

float couple(vec2 p, float lean){
  // him (left), sitting, knees up
  vec2 a = p - vec2(-.06, 0.);
  float d = sdPose(a, vec2(0., .05), vec2(.0, .42), vec2(.01, .56), .07,
    vec2(.2, .3), vec2(.3, .0), vec2(.18, .28), vec2(.28, .0),
    vec2(.14, .3), vec2(.24, .26), vec2(-.12, .25), vec2(-.2, .05), .1);
  // her (right), leaning towards him
  vec2 b = p - vec2(.2, 0.);
  vec2 sh = vec2(-.02 - lean * .06, .4 - lean * .03);
  vec2 hd = sh + vec2(-.03 - lean * .05, .12 - lean * .03);
  float e = sdPose(b, vec2(0., .05), sh, hd, .065,
    vec2(.18, .28), vec2(.28, .0), vec2(.16, .26), vec2(.26, 0.),
    vec2(.12, .27), vec2(.2, .25), vec2(.1, .25), vec2(.18, .22), .09);
  e = smin(e, sdCaps(b, hd + vec2(.03, .0), hd + vec2(.05, -.13), .05, .04), .03); // hair
  return min(d, e);
}

vec3 scene(vec2 uv, float t){
  vec2 p = cuv(uv);
  p *= 1. - p_cam * .06;
  vec3 col = mix(vec3(.02, .03, .07), vec3(.005, .008, .02), sat(p.y + .2));
  // milky way band
  vec2 mq = p * rot(-.5);
  float band = exp(-mq.y * mq.y * 22.) * (.5 + .7 * fbm(mq * 5. + 2.));
  float dustlane = smoothstep(.45, .7, fbm(mq * 9. + 7.)) * exp(-mq.y * mq.y * 60.);
  col += vec3(.25, .25, .38) * band * (1. - dustlane * .8) * .6;
  // stars, two layers
  for (int L = 0; L < 2; L++){
    float fl = float(L);
    vec2 sq = p * (90. + fl * 140.); vec3 sn = h33(vec3(floor(sq), 9. + fl));
    float th = mix(.97, .9, band * .9);
    col += vec3(.9, .9, 1.) * step(th + fl * .02, sn.z) * smoothstep(.2, 0., length(fract(sq) - .5 - (sn.xy - .5) * .5)) * (.5 + .5 * sin(t * 3. + sn.x * 40.)) * (1. - fl * .4);
  }
  // shooting star
  float ss = mod(t, 11.);
  vec2 sp0 = vec2(-.5, .4) + vec2(.6, -.15) * (ss - 4.);
  float trail = sdSeg(p, sp0, sp0 - vec2(.15, -.04));
  col += vec3(1.) * smoothstep(.003, 0., trail) * step(4., ss) * step(ss, 4.6) * 1.5;
  // hill
  float hill = p.y - (-.22 - p.x * p.x * .25 + .02 * fbm(vec2(p.x * 4., 1.)));
  vec3 hc = vec3(.004, .008, .01);
  col = mix(col, hc, fill(hill, .003));
  // couple on the hilltop
  float S = .36;
  float c = couple((p - vec2(-.07, -.225)) / S, sat(p_lean)) * S;
  col = mix(col, vec3(.003, .005, .008) + vec3(.1, .12, .2) * smoothstep(-.004, 0., c) * .3, fill(c, .0015));
  // grass tips
  float gx = p.x * 160.; float gh = h11(floor(gx)) * .02;
  float gt = p.y - (-.22 - p.x * p.x * .25 + .02 * fbm(vec2(p.x * 4., 1.)) + gh * smoothstep(.5, 0., abs(fract(gx) - .5)));
  col = mix(col, hc, fill(gt, .002));
  // fireflies: wandering glows, some out of focus in foreground
  for (int i = 0; i < 26; i++){
    float fi = float(i);
    vec3 r = h33(vec3(fi, 3., 1.));
    vec2 fp = vec2((r.x - .5) * 2.4, -.48 + r.y * .35) + vec2(sin(t * (.3 + r.z * .4) + fi), cos(t * (.25 + r.x * .3) + fi * 2.)) * .05;
    float blink = smoothstep(.2, 1., sin(t * (.8 + r.z) + fi * 7.)) ;
    float near = step(.8, r.z);
    float sz = near > .5 ? .025 : .004 + r.z * .003;
    float dd = length(p - fp);
    vec3 fc = vec3(1.2, 1.6, .4);
    col += fc * blink * (near > .5 ? smoothstep(sz, sz * .7, dd) * .5 : glow(dd, sz) * .8);
  }
  return col;
}
