// Fifty-eight. Winter. A candle on the sill, the window open, snow coming in.
uniform float p_cam;

vec3 scene(vec2 uv, float t){
  vec2 p = cuv(uv);
  p *= 1. - p_cam * .06;
  vec3 col = vec3(.015, .02, .035);
  // open window to snowy night
  float win = sdBox(p - vec2(.0, .1), vec2(.45, .34));
  vec3 night = mix(vec3(.08, .1, .16), vec3(.2, .22, .3), sat(.5 - p.y));
  // distant roofs with snow
  float roof = p.y - (-.05 + .04 * floor(h11(floor(p.x * 4.)) * 3.));
  night = mix(night, vec3(.03, .035, .05), fill(roof, .002));
  night = mix(night, vec3(.5, .55, .65), fill(abs(roof - .006) - .004, .002) * .7);
  col = mix(col, night, fill(win, .003));
  // open window pane (angled) on the right
  float pane = sdBox((p - vec2(.6, .1)) * vec2(1.6, 1.), vec2(.18, .34));
  col = mix(col, vec3(.03, .035, .05) + vec3(.1, .1, .14) * fbm(p * 5.), fill(pane, .003) * .9);
  // sill
  float sill = sdBox(p - vec2(0., -.26), vec2(.6, .025));
  col = mix(col, vec3(.08, .07, .065), fill(sill, .002));
  // candle on the sill
  vec2 cp = p - vec2(-.18, -.235);
  float body = sdBox(cp - vec2(0., .06), vec2(.025, .06));
  col = mix(col, vec3(.9, .8, .6) * .25, fill(body, .002));
  vec2 fp = cp - vec2(0., .135);
  fp.x -= sin(t * 3.) * .006 * (fp.y + .02) * 10.;  // wind from the window
  float fl = sdEll(fp - vec2(0., .02), vec2(.011, .03));
  col += vec3(2.4, 1.2, .35) * fill(fl, .01) * 1.1;
  col += vec3(1.2, .6, .2) * glow(length(fp), .08) * .5;
  // snow: falling, some drifting in through the window
  for (int L = 0; L < 3; L++){
    float fl2 = float(L);
    vec2 q = p * (8. + fl2 * 6.) + vec2(sin(t * .3 + fl2) * 1.5 - t * .2 * fl2, t * (.6 + fl2 * .3));
    vec3 n = h33(vec3(floor(q), fl2 + 1.));
    float d = length(fract(q) - .5 - (n.xy - .5) * .7);
    float sz = .06 + fl2 * .03;
    float inside = fill(win, .1) + fill(sdBox(p - vec2(-.1, -.1), vec2(.3, .2)), .25) * .15;
    col += vec3(.9, .95, 1.) * smoothstep(sz, sz * .3, d) * step(.7, n.z) * mix(.02, .8, inside) * (1. - fl2 * .5 * (1. - inside)) * (1. - fl2 * .2);
  }
  return col;
}
