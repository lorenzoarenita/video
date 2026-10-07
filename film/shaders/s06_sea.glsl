// The sea. var 0: afternoon, father and child (7) holding hands at the shore; p_run sends the child into the water.
// var 1: sunset, old Lucía sitting alone on the sand.
uniform float p_var;
uniform float p_run;
uniform float p_cam;

float waveH(vec2 q, float t){
  float h = 0.;
  h += sin(q.x * 1.3 + q.y * 3. - t * 1.1) * .5;
  h += sin(q.x * 3.1 - q.y * 2.2 - t * 1.7) * .25;
  h += sin(q.x * 7.3 + q.y * 5.1 - t * 2.3) * .12;
  h += (vnoise(q * 6. + vec2(t * .5, 0.)) - .5) * .4;
  return h;
}

float figs(vec2 p, float sy, float t, float var){
  float d = 1e5;
  if (var < .5){
    float S = .42;
    // father (back to camera, standing)
    vec2 fp = (p - vec2(-.08, sy)) / S;
    float sway = sin(t * .5) * .005;
    float fa = sdPose(fp, vec2(0., .48), vec2(sway, .8), vec2(sway, .93), .07,
       vec2(.05, .25), vec2(.06, 0.), vec2(-.05, .25), vec2(-.06, 0.),
       vec2(.13, .6), vec2(.19, .44), vec2(-.12, .6), vec2(-.14, .4), .1);
    d = fa * S;
    // child, holding father's hand then running
    float run = sat(p_run);
    float cx = mix(.035, .08, run);
    float cy = sy + run * .11;
    float cs = S * .58 * (1. - run * .35);
    vec2 cp = (p - vec2(cx, cy)) / cs;
    float ph = t * 9. * step(.01, run) ;
    float bob = abs(sin(ph)) * .03 * step(.01, run);
    cp.y -= bob;
    float sw = sin(ph) * .2 * step(.01, run);
    vec2 handF = (vec2(-.08, sy) + vec2(.19, .44) * S - vec2(cx, cy)) / cs;
    vec2 hl = mix(handF, vec2(-.25, .45), run);
    float ch = sdPose(cp, vec2(0., .44), vec2(0., .74), vec2(0., .9), .1,
       vec2(.05 + sw * .5, .22), vec2(.06 + sw, 0.), vec2(-.05 - sw * .5, .22), vec2(-.06 - sw, 0.),
       mix((vec2(0., .74) + hl) * .5 + vec2(-.05, -.05), vec2(-.2, .65), run), hl,
       vec2(.14, .6), vec2(.2 + run * .1, .45 + run * .2), .11);
    ch = smin(ch, sdEll(cp - vec2(0., .87), vec2(.1, .1)), .03);
    d = min(d, ch * cs);
  } else {
    float S = .36;
    vec2 op = (p - vec2(.1, sy)) / S;
    // sitting with knees up, arms around knees, slightly stooped
    float o = sdPose(op, vec2(0., .1), vec2(.03, .45), vec2(.07, .58), .07,
      vec2(.22, .3), vec2(.3, 0.), vec2(.2, .28), vec2(.28, 0.),
      vec2(.15, .3), vec2(.24, .25), vec2(.12, .28), vec2(.22, .24), .1);
    o = smin(o, sdCircle(op - vec2(.02, .62), .045), .02);
    d = o * S;
  }
  return d;
}

vec3 scene(vec2 uv, float t){
  vec2 p = cuv(uv);
  p *= 1. - p_cam * .08;
  float var = p_var;
  bool sunset = var > .5;
  float hz = .08;
  vec3 skyT = sunset ? vec3(.18, .2, .38) : vec3(.3, .5, .85);
  vec3 skyH = sunset ? vec3(2., .85, .4) : vec3(1.2, 1.15, 1.05);
  vec2 sun = sunset ? vec2(-.25, hz + .05) : vec2(.25, .38);
  vec3 sunC = sunset ? vec3(3., 1.4, .5) : vec3(2.5, 2.2, 1.8);
  vec3 col = mix(skyH, skyT, sat((p.y - hz) * 2.2));
  float sd = length(p - sun);
  col += sunC * glow(sd, sunset ? .06 : .04) * .7;
  col += sunC * 1.5 * smoothstep(.04, .035, sd) * step(hz, p.y);
  // clouds
  float cl = fbm(vec2(p.x * 1.5 + t * .01, p.y * 5.)) ;
  col = mix(col, mix(col, sunset ? vec3(1.2, .5, .35) : vec3(1.1), .6), smoothstep(.55, .75, cl) * smoothstep(hz, hz + .15, p.y) * .6);
  if (p.y < hz){
    // sea with perspective
    float dy = hz - p.y;
    float z = .08 / (dy + .002);
    vec2 q = vec2(p.x * z, z);
    float h = waveH(q * .8, t);
    float hx = waveH(q * .8 + vec2(.03, 0.), t) - h, hz2 = waveH(q * .8 + vec2(0., .03), t) - h;
    vec3 n = normalize(vec3(-hx * 3., 1., -hz2 * 3.));
    vec3 deep = sunset ? vec3(.05, .05, .1) : vec3(.02, .12, .2);
    vec3 sea = mix(deep, skyH * .6, pow(1. - n.y, .5) * .3 + .25 * exp(-dy * 8.));
    // sun glitter
    float gx = p.x - sun.x;
    float path = exp(-gx * gx / (.004 + dy * .06));
    float glit = pow(sat(n.x * sign(-gx + .0001) * .5 + n.z * .5 + .5), 18.) ;
    float spark = pow(vnoise(vec2(q.x * 18., q.y * 2.5) + vec2(0., t * 1.5)), 6.) + pow(vnoise(vec2(q.x * 31., q.y * 4.) - vec2(t, t * 2.)), 8.);
    sea += sunC * path * (spark * 3. + glit * .6 + .05);
    sea = mix(sea, skyH * .85, exp(-dy * 40.) * .6);
    col = sea;
    // shore: sand and foam
    float shoreY = -.22 + sin(p.x * 3. + 1.) * .015;
    float wash = sin(t * .45) * .5 + .5;
    float foamY = shoreY - .02 - wash * .07 + sin(p.x * 9. + t) * .006;
    vec3 sand = sunset ? vec3(.35, .2, .14) : vec3(.6, .5, .38);
    vec3 wet = mix(sand * .5, skyH * .5, .4);
    if (p.y < foamY){
      col = mix(sand * (.5 + .5 * fbm(p * 40.)) * .5, wet, smoothstep(foamY - .1, foamY, p.y) * (1. - wash * .3));
      // wet sand reflection of sun
      col += sunC * path * .25 * smoothstep(foamY - .12, foamY, p.y);
    }
    float foam = smoothstep(.009, .0, abs(p.y - foamY)) * smoothstep(.25, .65, fbm(vec2(p.x * 14., t * .2)));
    foam += smoothstep(.03, .0, foamY - p.y) * step(p.y, foamY) * .25 * fbm(vec2(p.x * 40., p.y * 80.));
    float foam2 = smoothstep(.005, .0, abs(p.y - (foamY + .04 + wash * .02))) * .4 * smoothstep(.35, .7, fbm(vec2(p.x * 9. + 5., t * .3)));
    col += vec3(1.1) * (foam + foam2) * (sunset ? .5 : .9);
    // rolling wave crest band
    float crest = smoothstep(.01, 0., abs(p.y - (shoreY + .03 + sin(t * .45 + 1.) * .02)));
    col += vec3(.8) * crest * .25 * smoothstep(.4, .75, fbm(vec2(p.x * 12., t * .3)));
  }
  float sy = var < .5 ? -.39 : -.36;
  float f = figs(p, sy, t, var);
  float fm = fill(f, .0025);
  vec3 figC = sunset ? vec3(.03, .02, .03) : vec3(.05, .05, .07);
  col = mix(col, figC + skyH * .05 * smoothstep(-.01, 0., f), fm);
  // child's splashes when running
  if (var < .5 && p_run > .6){
    vec3 spl = dust(p * 2. - vec2(.2, -.4), t * 2., 9., .3);
    col += vec3(1.) * spl * .5 * smoothstep(.15, .0, length(p - vec2(.08, sy + .12)));
  }
  return col;
}
