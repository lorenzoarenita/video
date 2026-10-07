// Twenty-six. The darkroom: under the red safelight, an image slowly appears in the developer.
uniform float p_dev;    // development 0 (blank) .. 1 (full image)
uniform float p_cam;

vec3 scene(vec2 uv, float t){
  vec2 p = cuv(uv);
  p *= 1. - p_cam * .1;
  vec3 red = vec3(1., .08, .03);
  vec3 col = red * .015;
  // tray (top-down), slightly perspective
  vec2 tp = p - vec2(0., -.02);
  float tray = sdBox(tp, vec2(.62, .4)) - .03;
  float trayIn = sdBox(tp, vec2(.58, .36)) - .02;
  col = mix(col, red * .06, fill(tray, .004));
  // liquid ripples (agitation)
  float rip = sin(length(tp - vec2(.7, .3)) * 40. - t * 3.) * .5 + sin(tp.x * 25. + t * 2.) * .3;
  vec2 dist = vec2(sin(tp.y * 18. + t * 1.6), cos(tp.x * 15. + t * 1.3)) * .0025 * (1. + .5 * sin(t * .5));
  // photo paper
  vec2 pp = tp + dist;
  float paper = sdBox(pp, vec2(.42, .27));
  vec2 puv = pp / vec2(.84, .54) + .5;
  vec3 img = texture(uTex0, puv).rgb;
  float lum = dot(img, vec3(.3, .55, .15));
  // development curve: dark tones appear first
  float dev = sat(p_dev);
  float target = pow(sat(lum * 2.8), .75);
  float shown = mix(1., target, smoothstep(0., 1., dev * (1.6 - target * .6)));
  vec3 paperC = vec3(.9) * shown;
  col = mix(col, red * .12, fill(trayIn, .004));
  col = mix(col, paperC * vec3(1., .14, .07) * .9, fill(paper, .002));
  // safelight reflection on the liquid surface
  vec2 rl = tp - vec2(-.3, .2) + dist * 4.;
  col += red * glow(length(rl * vec2(1., 1.6)), .05) * .5 * (.8 + .2 * rip);
  // tongs entering from right, agitating the paper
  vec2 gp = p - vec2(.5 + sin(t * 1.2) * .03, -.1 + sin(t * 1.2) * .02);
  float tong = min(sdCaps(gp, vec2(0.), vec2(.6, .25), .012, .016), sdCaps(gp, vec2(.0, -.03), vec2(.6, .2), .012, .016));
  col = mix(col, red * .02, fill(tong, .003));
  // a hand holding them (silhouette)
  col = mix(col, red * .01, fill(sdEll(p - vec2(1.05, .1), vec2(.18, .12)), .03));
  col += dust(p, t * .3, 2., .15) * red * .05;
  return col;
}
