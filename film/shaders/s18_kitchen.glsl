// Thirty-six. Morning kitchen: low sun through the window, steam from a cup, a man by the window.
// var 1 (seventy-four): two cups on the table, only one steaming. Haze in her eyes.
uniform float p_var;
uniform float p_haze;
uniform float p_cam;

vec3 scene(vec2 uv, float t){
  vec2 p = cuv(uv);
  p *= 1. - p_cam * .05;
  bool old = p_var > .5;
  vec3 col = vec3(.08, .06, .05);
  // window with morning light
  float win = sdBox(p - vec2(.35, .12), vec2(.32, .3));
  vec3 sun = vec3(2.4, 1.9, 1.3);
  vec3 outside = mix(vec3(1.6, 1.5, 1.3), vec3(.8, .9, 1.), sat(p.y));
  // outside: blurred tree
  outside = mix(outside, vec3(.35, .45, .25), smoothstep(.55, .7, fbm(p * 4. + vec2(t * .02, 0.))) * .6);
  col = mix(col, outside, fill(win, .004));
  float mul = min(abs(p.x - .35) - .006, abs(p.y - .12) - .006);
  col = mix(col, vec3(.06, .05, .04), fill(mul, .002) * fill(win, .004));
  // light beam across the room (volumetric)
  vec2 bd = normalize(vec2(-1., -.55));
  vec2 rel = p - vec2(.35, .12);
  float along = dot(rel, bd), across = dot(rel, vec2(-bd.y, bd.x));
  float beam = smoothstep(.3, .0, abs(across) - along * .1) * step(0., along) * exp(-along * 1.2);
  col += sun * beam * .08 * (.7 + .3 * fbm(p * 6. + t * .05));
  col += dust(p, t * .4, 6., .25) * sun * beam * .3;
  // table
  float tableY = -.22;
  col = mix(col, vec3(.2, .13, .08) * (.5 + .6 * smoothstep(-.6, .3, p.x)), step(p.y, tableY));
  // sun patch on table
  col += sun * .25 * fill(sdBox(vec2(p.x + .05 + (p.y - tableY) * 1.6, p.y + .32), vec2(.25, .08)), .05) * step(p.y, tableY);
  // cups
  for (int i = 0; i < 2; i++){
    if (i == 1 && !old) break;
    float fi = float(i);
    vec2 cp = p - vec2(-.2 + fi * .25, tableY + .005);
    float cup = sdBox(cp - vec2(0., .055), vec2(.045 - cp.y * .1, .055)) - .006;
    float handle = abs(length(cp - vec2(.06, .06)) - .025) - .006;
    float c = min(cup, handle);
    col = mix(col, vec3(.85, .82, .78) * (.25 + .7 * smoothstep(-.05, .05, cp.x)), fill(c, .002));
    // steam only from the first cup
    if (i == 0){
      vec2 sp = cp - vec2(0., .12);
      float st = 0.;
      for (int k = 0; k < 3; k++){
        float fk = float(k);
        float y = sp.y;
        float x = sp.x + sin(y * 14. - t * 1.4 + fk * 2.) * .02 * (1. + y * 4.) + (fk - 1.) * .01;
        st += smoothstep(.012 + y * .05, .0, abs(x)) * smoothstep(.0, .03, y) * smoothstep(.35, .05, y) * (.5 + .5 * fbm(vec2(x * 30., y * 8. - t)));
      }
      col += vec3(.9, .85, .8) * st * .18 * (1. + beam * 3.);
    }
  }
  // the man by the window (var 0)
  if (!old){
    float S = .82;
    vec2 fp = (p - vec2(.05, -.52)) / S;
    float br = sin(t * .9) * .003;
    float f = sdPose(fp, vec2(0., .5), vec2(.02, .8 + br), vec2(.05, .93 + br), .072,
      vec2(.03, .26), vec2(.03, .0), vec2(-.04, .26), vec2(-.05, .0),
      vec2(.15, .62), vec2(.22, .72), vec2(-.1, .6), vec2(-.12, .44), .105);
    f *= S;
    vec3 fc = vec3(.05, .035, .03) + sun * .25 * smoothstep(-.012, 0., f) * step(.0, p.x - .04);
    col = mix(col, fc, fill(f, .003));
  }
  // haze (cataract)
  float hz = sat(p_haze);
  col = mix(col, vec3(.9, .85, .75) * (.3 + .7 * dot(col, vec3(.33))) + sun * .05, hz * .55);
  return col;
}
