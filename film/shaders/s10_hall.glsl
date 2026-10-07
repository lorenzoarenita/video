// Sixteen. The mother in the hallway, lit by a lamp. "¿Tú sabes qué hora es?" Then the door slams shut.
uniform float p_door;  // 0 open .. 1 shut
uniform float p_step;  // mother steps forward

vec3 scene(vec2 uv, float t){
  vec2 p = cuv(uv);
  p += vec2(vnoise(vec2(t * 2., 0.)) - .5, vnoise(vec2(0., t * 1.7)) - .5) * .005;
  vec3 col = vec3(.02, .015, .012);
  // hallway in one-point perspective: back wall rect, side walls/floor/ceiling as trapezoids
  vec2 vp = vec2(.05, .03);
  vec2 d = p - vp;
  vec2 bw = vec2(.16, .2);       // back wall half size
  vec2 op = vec2(.62, .46);      // opening half size (near)
  float tx = sat((abs(d.x) - bw.x) / (op.x - bw.x)), ty = sat((abs(d.y) - bw.y) / (op.y - bw.y));
  float inOpen = step(abs(d.x), op.x) * step(abs(d.y), op.y);
  vec3 lampC = vec3(2., 1.25, .6);
  vec2 lamp = vp + vec2(-.13, .04);
  vec3 wallC = vec3(.38, .27, .18);
  float lit = .12 + 1.4 * glow(length(p - lamp), .16);
  // which surface: compare normalized distances
  float side = abs(d.x) / op.x, cap = abs(d.y) / op.y;
  vec3 surf = wallC * lit;
  if (abs(d.x) < bw.x && abs(d.y) < bw.y) surf = wallC * lit * .8;           // back wall
  else if (side > cap) surf *= (d.x < 0. ? 1.1 : .7);                       // side walls
  else surf *= (d.y < 0. ? vec3(.7, .6, .5) : vec3(.5));                    // floor / ceiling
  col = mix(col, surf, inOpen);
  // perspective seams
  float seam = min(abs(abs(d.y) / max(abs(d.x), 1e-3) - bw.y / bw.x), 10.);
  col *= 1. - .3 * smoothstep(.02, 0., seam) * step(bw.x, abs(d.x)) * inOpen;
  // back door (far room, dim)
  col = mix(col, vec3(.04, .03, .03), fill(sdBox(d - vec2(.04, -.05), vec2(.05, .15)), .003));
  col += lampC * glow(length(p - lamp), .015) * .7;
  // picture frame on left wall
  col = mix(col, col * .45, fill(sdBox(p - vp - vec2(-.3, .08), vec2(.05, .07)), .004) * inOpen);
  // mother silhouette in hallway, arms crossed
  float S = mix(.55, .66, sat(p_step));
  vec2 fp = (p - vec2(.06 + p_step * .02, vp.y - .32 - p_step * .05)) / S;
  vec2 hip = vec2(0., .5), sh = vec2(.0, .8), head = sh + vec2(.0, .13);
  float f = sdPose(fp, hip, sh, head, .07,
    vec2(.04, .26), vec2(.05, 0.), vec2(-.04, .26), vec2(-.05, 0.),
    vec2(.12, .63), vec2(-.06, .68), vec2(-.12, .63), vec2(.06, .66), .1);
  f = smin(f, sdEll(fp - head - vec2(0., .03), vec2(.085, .08)), .02);
  f = smin(f, sdCircle(fp - head - vec2(-.05, .07), .04), .02);
  f *= S;
  float m = fill(f, .003);
  col = mix(col, vec3(.02, .015, .012) + lampC * .12 * smoothstep(-.01, 0., f) * smoothstep(.2, -.1, p.x - lamp.x), m);
  // her own bedroom door frame (foreground, left & right edges)
  float jamb = min(abs(p.x + .78) - .05, abs(p.x - .82) - .05);
  col = mix(col, vec3(.01), fill(jamb, .01));
  // the door closing: sweeping in from the right (hinge at right)
  float edge = mix(1.3, -1.25, pow(sat(p_door), 1.6));
  float door = step(edge, p.x);
  vec3 doorC = vec3(.05, .04, .035) * (.6 + .4 * smoothstep(edge, edge + .4, p.x));
  doorC += lampC * .05 * smoothstep(.02, .0, abs(p.x - edge));
  col = mix(col, doorC, door);
  col *= 1. - smoothstep(.97, 1., p_door);
  return col;
}
