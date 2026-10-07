// Thirty-one. A hospital corridor at night. The voicemail.
uniform float p_cam;
uniform float p_flicker;

vec3 scene(vec2 uv, float t){
  vec2 p = cuv(uv);
  float push = p_cam * .15;
  vec2 vp = vec2(0., .02);
  vec2 d = (p - vp) / (1. + push);
  vec3 col = vec3(.02);
  float ax = abs(d.x), ay = abs(d.y);
  float wallSide = step(ay * 1.9, ax);  // side walls where |x| dominates
  float z;
  vec3 c;
  if (wallSide > .5){
    z = .5 / max(ax, .001);
    c = vec3(.5, .58, .55) * .22;
    // doors
    float door = step(.62, fract(z * .5)) * step(d.y, ax * .3) * step(-ax * .5, d.y);
    c = mix(c, vec3(.18, .22, .23) * .5, door);
    c *= 1. / (1. + z * .04);
  } else {
    z = .26 / max(ay, .001);
    if (d.y > 0.){
      c = vec3(.35, .38, .38) * .15;
      // ceiling panels
      float pz = fract(z * .35);
      float panel = step(.55, pz) * step(abs(d.x / max(ay, .001)), .5);
      float fl = 1.;
      if (floor(z * .35) == 3.) fl = mix(1., step(.5, fract(sin(floor(t * 13.)) * 43758.)), p_flicker);
      c += vec3(.85, 1., .95) * panel * 1.8 * fl;
    } else {
      // glossy floor reflecting the panels
      c = vec3(.25, .3, .28) * .12;
      float pz = fract(z * .35);
      float refl = smoothstep(.3, .0, abs(pz - .78)) * smoothstep(.8, 0., abs(d.x / max(ay, .001)));
      c += vec3(.5, .62, .58) * refl * .35;
      c *= .8 + .2 * vnoise(vec2(d.x * z * 8., z * 4.));
    }
    c *= 1. / (1. + z * .03);
  }
  col = c;
  // fog / end of corridor glow
  col += vec3(.4, .5, .48) * glow(length(d), .05) * .4;
  // a row of plastic chairs on left
  float chairs = step(.5, fract((.5 / max(ax, .001)) * 1.5)) * step(d.x, 0.) * step(-.06 - ax * .2, d.y) * step(d.y, -ax * .1) * step(.4, ax);
  col = mix(col, vec3(.04, .08, .1), chairs * .8);
  return col;
}
