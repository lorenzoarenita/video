// Through the viewfinder of her first camera: her father in the doorway, the focus ring turning, the shutter.
uniform float p_focus;    // 0 blurred .. 1 sharp
uniform float p_shutter;  // 0..1 shutter blackout pulse
uniform float p_var;      // 0: father in doorway; 1: empty platform (used later)

vec3 world(vec2 p, float t, float blur){
  // a sunlit hallway with an open door to a bright courtyard
  vec3 col = vec3(.12, .09, .07);
  col *= .6 + .4 * smoothstep(.8, -.2, abs(p.x));
  float door = sdBox(p - vec2(0., -.02), vec2(.2, .44));
  vec3 bright = vec3(2.4, 2.0, 1.5);
  col = mix(col, bright, fill(door, blur + .003));
  col += bright * glow(max(door, 0.), .04 + blur) * .12;
  // floor light
  float fl = fill(sdBox(vec2(p.x * (1. + (-.46 - p.y) * 2.), p.y + .6), vec2(.22, .14)), blur + .02) * step(p.y, -.45);
  col += bright * fl * .2;
  // father leaning on the frame, arms crossed, smiling (we don't see it)
  float S = .9;
  vec2 fp = (p - vec2(.04, -.46)) / S;
  float br = sin(t * 1.2) * .003;
  vec2 hip = vec2(0., .5), sh = vec2(-.015, .8 + br), head = sh + vec2(.0, .13);
  float f = sdPose(fp, hip, sh, head, .072,
    vec2(.03, .26), vec2(.02, .0), vec2(-.05, .26), vec2(.06, .02),
    vec2(.1, .62), vec2(-.05, .66), vec2(-.1, .62), vec2(.06, .68), .1);
  f *= S;
  float m = fill(f, blur + .002);
  col = mix(col, vec3(.04, .03, .03) + bright * .15 * smoothstep(-.03 - blur, 0., f), m);
  return col;
}

vec3 scene(vec2 uv, float t){
  vec2 p = cuv(uv);
  if (p_var > .5) return world(p * .9, 2., 0.) * 1.1;
  // handheld micro-shake
  p += vec2(vnoise(vec2(t * 1.5, 0.)) - .5, vnoise(vec2(0., t * 1.3)) - .5) * .006;
  float blur = (1. - p_focus) * .06;
  // split-image focusing aid in center: halves offset when out of focus
  vec2 q = p;
  float rc = length(p);
  if (rc < .07) q.x += (p.y > 0. ? 1. : -1.) * (1. - p_focus) * .05;
  vec3 col = world(q, t, rc < .07 ? .002 : blur);
  // microprism ring
  float ring = smoothstep(.004, .0, abs(rc - .07)) + smoothstep(.003, .0, abs(rc - .13)) * .5;
  col = mix(col, col * .5 + vec3(.05), ring * .6);
  if (rc > .07 && rc < .13) col *= 1. + .25 * sin(atan(p.y, p.x) * 60.) * (1. - p_focus);
  // viewfinder frame: rounded rectangle, dark outside
  float vf = sdBox(p, vec2(.78, .44)) - .04;
  col *= fill(vf, .01);
  col += vec3(.02, .02, .02) * (1. - fill(vf, .01));
  // exposure needle at right edge
  float needle = sdSeg(p, vec2(.86, -.1), vec2(.86 + sin(t * .7) * .01, .1 + sin(t * .9) * .03)) - .002;
  col += vec3(.6, .5, .3) * fill(needle, .002) * .4;
  // edge darkening inside eyepiece
  col *= smoothstep(1.15, .5, length(p * vec2(.8, 1.4)));
  // shutter blackout + flash memory
  col *= 1. - sat(p_shutter);
  return col;
}
