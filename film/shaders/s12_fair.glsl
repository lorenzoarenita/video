// Twenty-one. The fair: a ferris wheel of lights, strings of bulbs, the two of them close, kissing.
uniform float p_kiss;
uniform float p_cam;

vec3 scene(vec2 uv, float t){
  vec2 p = cuv(uv);
  p.x += p_cam * .05;
  vec3 col = mix(vec3(.04, .02, .06), vec3(.01, .01, .03), sat(p.y + .3));
  // ferris wheel, defocused, rotating
  vec2 wc = vec2(.45, .12);
  vec2 wp = (p - wc) * rot(t * .08);
  float wr = .42;
  float ang = atan(wp.y, wp.x); float rr = length(wp);
  float nb = 36.;
  float a = (floor(ang / TAU * nb) + .5) * TAU / nb;
  vec2 bulb = vec2(cos(a), sin(a)) * wr;
  float bd = length(wp - bulb);
  vec3 bc = mix(vec3(1.8, .5, .7), vec3(1.6, 1.1, .4), .5 + .5 * sin(a * 3. + t * 2.));
  col += bc * smoothstep(.035, .028, bd) * .6;
  // spokes of light
  float spoke = abs(fract(ang / TAU * 12.) - .5) * rr * 12. * .5;
  col += vec3(1.4, .9, .5) * smoothstep(.012, 0., spoke) * step(rr, wr) * .15 * (.6 + .4 * sin(rr * 40. - t * 3.));
  // cabins
  float nc = 10.; float ac = (floor(ang / TAU * nc) + .5) * TAU / nc;
  vec2 cab = vec2(cos(ac), sin(ac)) * wr;
  col += vec3(1.5, 1.2, .7) * smoothstep(.05, .04, length(wp - cab)) * .25;
  // strings of bulbs in foreground (catenaries)
  for (int i = 0; i < 2; i++){
    float fi = float(i);
    float y0 = .38 - fi * .18;
    float cy = y0 - .12 * (1. - pow(p.x / 1.3, 2.)) ;
    float bx = fract(p.x * (9. + fi * 5.)) - .5;
    vec2 bq = vec2(bx / (9. + fi * 5.), p.y - cy);
    float bsz = .02 + fi * .015;
    col += vec3(1.9, 1.3, .6) * smoothstep(bsz, bsz * .6, length(bq)) * .45;
    col = mix(col, vec3(.01), smoothstep(.002, 0., abs(p.y - cy)) * .5);
  }
  col += bokeh(p, 33., 4., .5, vec3(1.5, .6, .9), vec3(1.6, 1.1, .5), t, .02) * .07;
  // crowd silhouettes far, blurred
  float crowd = p.y - (-.28 + .05 * fbm(vec2(p.x * 9., 2.)) + .03 * sin(p.x * 30.));
  col = mix(col, vec3(.02, .01, .02), fill(crowd, .01) * .8);
  // the couple, close, foreground left, faces approaching
  float k = sat(p_kiss);
  float S = .62;
  vec2 cp = (p - vec2(-.42, -.5)) / S;
  float him = sdPose(cp - vec2(-.1 + k * .02, 0.), vec2(0., .5), vec2(.02, .8), vec2(.06 + k * .02, .94 - k * .01), .075,
     vec2(.03, .26), vec2(.03, 0.), vec2(-.03, .26), vec2(-.03, 0.),
     vec2(.15, .66), vec2(.23, .74), vec2(-.08, .62), vec2(-.05, .45), .1);
  float her = sdPose(cp - vec2(.17 - k * .02, 0.), vec2(0., .48), vec2(-.02, .76), vec2(-.07 - k * .02, .88 - k * .01), .068,
     vec2(.03, .25), vec2(.03, 0.), vec2(-.03, .25), vec2(-.03, 0.),
     vec2(-.12, .66), vec2(-.17, .76), vec2(.08, .6), vec2(.06, .45), .095);
  her = smin(her, sdCaps(cp - vec2(.17 - k * .02, 0.), vec2(-.04, .9), vec2(.01, .74), .06, .05), .03);
  float c = min(him, her) * S;
  col = mix(col, vec3(.012, .008, .015) + vec3(1.2, .5, .7) * smoothstep(-.006, 0., c) * .25, fill(c, .002));
  return col;
}
