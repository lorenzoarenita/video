// Sixteen, alone on the rooftop. The city glowing below, endless.
uniform float p_cam;

vec3 scene(vec2 uv, float t){
  vec2 p = cuv(uv);
  p *= 1. - p_cam * .05;
  float hz = -.02;
  vec3 col = mix(vec3(.25, .13, .08), vec3(.02, .025, .06), sat((p.y - hz) * 2.5));
  // stars faint
  vec2 sq = p * 120.; vec3 sn = h33(vec3(floor(sq), 2.));
  col += vec3(.8) * step(.993, sn.z) * smoothstep(.15, 0., length(fract(sq) - .5)) * smoothstep(.1, .4, p.y) * .5;
  // city: endless grid of lights in perspective below the horizon
  if (p.y < hz){
    float dy = hz - p.y;
    float z = .1 / dy;
    vec2 q = vec2(p.x * z, z);
    vec2 g = q * vec2(22., 9.);
    vec2 id = floor(g); vec3 n = h33(vec3(id, 1.));
    vec2 f = fract(g) - .5;
    float lightD = length(f - (n.xy - .5) * .6);
    float sz = .05;
    vec3 lc = mix(vec3(1.6, .8, .35), vec3(.9, .95, 1.2), step(.85, n.y));
    col = vec3(.03, .02, .03) + vec3(.2, .09, .05) * exp(-dy * 6.);
    col += lc * smoothstep(sz + .05, sz * .3, lightD) * step(.15, n.z) * (.5 + .5 * sin(t * (1. + n.x) + n.y * 9.) * step(.95, n.x)) * .9;
    // avenues: moving car lights along lines
    float av = abs(fract(q.x * .5) - .5);
    float cars = smoothstep(.02, .0, av) * pow(vnoise(vec2(q.y * 3. - t * 2., floor(q.x * .5))), 6.) * 6.;
    col += vec3(1.8, .3, .2) * cars * .4;
    col = mix(col, vec3(.25, .13, .08), exp(-z * .03) * .0 + smoothstep(.0, .06, -dy + .06) * .5);
  }
  // rooftop parapet in foreground
  float roof = p.y - (-.33 + p.x * .02);
  col = mix(col, vec3(.012, .01, .012), fill(roof, .002));
  // antenna and water tank silhouettes
  float ant = sdBox(p - vec2(.75, -.1), vec2(.004, .23));
  ant = min(ant, sdBox(p - vec2(.75, .05), vec2(.06, .003)));
  ant = min(ant, sdBox(p - vec2(.75, .0), vec2(.04, .003)));
  float tank = sdBox(p - vec2(-.85, -.2), vec2(.11, .12)) - .02;
  col = mix(col, vec3(.01), fill(min(ant, tank), .002));
  // the girl sitting on the edge, seen from behind
  vec2 fp = (p - vec2(-.05, -.33));
  float g = sdCircle(fp - vec2(0., .2), .034);                                 // head
  g = smin(g, sdEll(fp - vec2(0., .175), vec2(.04, .045)), .01);              // hair volume
  g = smin(g, sdCaps(fp, vec2(0., .2), vec2(.005, .1), .03, .045), .02);       // long hair
  g = smin(g, sdCaps(fp, vec2(-.05, .14), vec2(.05, .14), .022, .022), .03);  // shoulders
  g = smin(g, sdBox(fp - vec2(0., .06), vec2(.05 + fp.y * -.08, .07)), .03);  // back
  g = smin(g, sdCaps(fp, vec2(-.06, .12), vec2(-.075, .05), .018, .016), .02);  // elbows out
  g = smin(g, sdCaps(fp, vec2(.06, .12), vec2(.075, .05), .018, .016), .02);
  col = mix(col, vec3(.012, .01, .014) + vec3(.5, .25, .12) * smoothstep(-.004, 0., g) * .3, fill(g, .0015));
  return col;
}
