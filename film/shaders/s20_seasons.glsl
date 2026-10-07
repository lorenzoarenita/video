// Forty to fifty-two. The seasons pass over the lemon tree; it grows; a daughter grows beside it.
uniform float p_season;  // continuous: each unit = one year (0 spring, .25 summer, .5 autumn, .75 winter)
uniform float p_grow;    // tree growth .3 .. 1
uniform float p_kid;     // 0 none, 1 little girl, 2 teenager (crossfade)

vec3 scene(vec2 uv, float t){
  vec2 p = cuv(uv);
  float s = fract(p_season);
  float spring = smoothstep(.2, 0., abs(s - .0)) + smoothstep(.2, 0., abs(s - 1.));
  float summer = smoothstep(.2, 0., abs(s - .25));
  float autumn = smoothstep(.2, 0., abs(s - .5));
  float winter = smoothstep(.2, 0., abs(s - .75));
  float wsum = spring + summer + autumn + winter + 1e-3;
  spring /= wsum; summer /= wsum; autumn /= wsum; winter /= wsum;
  // sky
  vec3 skyT = spring * vec3(.5, .7, .95) + summer * vec3(.35, .6, 1.) + autumn * vec3(.55, .55, .7) + winter * vec3(.55, .58, .62);
  vec3 skyH = spring * vec3(1.3, 1.25, 1.1) + summer * vec3(1.4, 1.3, 1.1) + autumn * vec3(1.5, 1., .65) + winter * vec3(.9, .9, .92);
  vec3 col = mix(skyH, skyT, sat(p.y + .3));
  // fast clouds (time-lapse)
  float cl = fbm(vec2(p.x * 1.5 - p_season * 6., p.y * 4.) );
  col = mix(col, mix(vec3(1.2), vec3(.7), winter), smoothstep(.5, .75, cl) * smoothstep(-.1, .3, p.y) * (.5 + winter * .4));
  // light flicker of passing days (very subtle)
  col *= .92 + .08 * sin(p_season * 200.);
  float gy = -.3;
  vec3 ground = spring * vec3(.12, .2, .06) + summer * vec3(.15, .17, .05) + autumn * vec3(.2, .12, .05) + winter * vec3(.8, .82, .85);
  col = mix(col, ground * (.6 + .5 * fbm(p * vec2(60., 20.))) * (1. + .3 * smoothstep(-.6, -.3, p.y)), fill(p.y - gy, .003));
  // long tree shadow on the grass
  col *= 1. - .35 * fill(sdEll(p - vec2(.15, gy - .06), vec2(.35 * p_grow + .05, .03)), .05) * step(p.y, gy) * (1. - winter);
  // garden wall in back
  vec2 st = vec2(p.x * 14., (p.y - gy) * 30.); st.x += floor(st.y) * .5;
  float stones = smoothstep(.0, .12, min(fract(st.x), fract(st.y))) * (.75 + .25 * h21(floor(st)));
  col = mix(col, vec3(.28, .24, .2) * stones * (1. - winter * .3), fill(sdBox(p - vec2(0., gy + .045), vec2(2., .045)), .002));
  col = mix(col, vec3(.9, .92, .95), fill(sdBox(p - vec2(0., gy + .092), vec2(2., .006)), .002) * winter);
  // the tree
  vec2 tp = p - vec2(-.15, gy);
  float g = p_grow;
  float tr = sdTree(tp, g, 4., t * .5);
  float can = treeCanopy(tp - vec2(0., .02), g * 1.05, 2., p_season * 3.);
  float density = 1. - winter * .85 - autumn * .2;
  float can2 = can * smoothstep(1. - density, 1. - density + .3, fbm(tp * 30. / g + 3.) * .5 + .5 * density);
  vec3 leaf = spring * vec3(.25, .45, .15) + summer * vec3(.12, .3, .08) + autumn * vec3(.55, .4, .1) + winter * vec3(.2, .2, .15);
  col = mix(col, vec3(.08, .06, .04), fill(tr, .002));
  col = mix(col, leaf * (.6 + .5 * fbm(tp * 20.)), can2);
  // blossoms in spring, lemons in summer/autumn
  vec2 lq = tp / max(g, .1) * 14.;
  vec2 lid = floor(lq); vec3 ln = h33(vec3(lid, 5.));
  float dotM = fill(length(lq - lid - .5 - (ln.xy - .5) * .5) - .15, .05) * can;
  col = mix(col, vec3(1.3, 1.1, 1.15), dotM * step(.55, ln.z) * spring);
  col = mix(col, vec3(1.2, .9, .1), dotM * step(.7, ln.z) * (summer + autumn * .8) * smoothstep(.45, .7, g));
  // falling leaves in autumn, snow in winter
  vec2 fq = p * 12. + vec2(sin(t + p.y * 3.) * .3, t * 1.5);
  vec3 fn = h33(vec3(floor(fq), 2.));
  float flake = smoothstep(.12, .0, length(fract(fq) - .5 - (fn.xy - .5) * .6)) * step(.8, fn.z);
  col = mix(col, vec3(1.), flake * winter);
  col = mix(col, vec3(.8, .45, .1), flake * autumn * .8 * step(.92, fn.z));
  // the daughter
  float kid = p_kid;
  if (kid > .01){
    float a1 = sat(1. - abs(kid - 1.)), a2 = sat(kid - 1.);
    // little girl running near the tree
    vec2 kp = (p - vec2(.25 + sin(t * .7) * .06, gy)) / .26;
    float ph = t * 8.;
    float sw = sin(ph) * .2;
    float c1 = sdPose(kp, vec2(0., .42 + abs(sin(ph)) * .02), vec2(.04, .72), vec2(.06, .88), .1,
       vec2(.06 + sw * .5, .22), vec2(.05 + sw, 0.), vec2(-.04 - sw * .5, .22), vec2(-.06 - sw, 0.),
       vec2(.15, .62), vec2(.24, .78), vec2(-.12, .6), vec2(-.2, .5 - sw * .3), .11);
    c1 = smin(c1, sdCircle(kp - vec2(-.05, .96), .05), .03);
    // teenager, standing with arms crossed, turned away
    vec2 tq = (p - vec2(.3, gy)) / .5;
    float c2 = sdPose(tq, vec2(0., .5), vec2(-.01, .8), vec2(-.02, .93), .068,
       vec2(.03, .26), vec2(.03, 0.), vec2(-.03, .26), vec2(-.03, 0.),
       vec2(.12, .62), vec2(-.06, .66), vec2(-.12, .62), vec2(.06, .68), .095);
    c2 = smin(c2, sdCaps(tq, vec2(-.03, .95), vec2(-.06, .76), .06, .05), .02);
    col = mix(col, vec3(.04, .035, .03), fill(c1 * .26, .002) * a1 * (1. - a2));
    col = mix(col, vec3(.04, .035, .03), fill(c2 * .5, .002) * a2);
  }
  return col;
}
