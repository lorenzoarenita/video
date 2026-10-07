// Thirty-three. Her first exhibition. The prints of her life on white walls. People. Applause.
uniform float p_track;  // camera tracks right across prints
uniform float p_crowd;

vec3 print(vec2 q, int i){
  vec2 u = q + .5;
  if (i == 0) return texture(uTex0, u).rgb;
  if (i == 1) return texture(uTex1, u).rgb;
  if (i == 2) return texture(uTex2, u).rgb;
  return texture(uTex3, u).rgb;
}

vec3 scene(vec2 uv, float t){
  vec2 p = cuv(uv);
  float x = p.x + mix(-.9, 3.3, p_track);
  vec3 col = vec3(.62, .6, .57);
  // wall/floor line
  float floorY = -.36;
  col = mix(col, vec3(.2, .17, .14) * (.6 + .4 * smoothstep(-.5, floorY, p.y)), step(p.y, floorY));
  // spots
  float sx = fract(x / 1.1 + .5) - .5;
  col *= .55 + .65 * exp(-sx * sx * 30.) * smoothstep(-.4, .35, p.y);
  // prints every 1.1 units
  float idx = floor(x / 1.1 + .5);
  vec2 q = vec2(sx * 1.1, p.y - .05);
  vec2 sz = vec2(.32, .2);
  float fr = sdBox(q, sz + .035);
  float im = sdBox(q, sz);
  int ii = int(mod(idx, 4.) + 4.) % 4;
  col = mix(col, vec3(.04), fill(fr, .002));                       // black frame
  col = mix(col, vec3(.93, .92, .9) * .9, fill(sdBox(q, sz + .025), .002)); // mat
  vec3 ph = print(q / (2. * sz), ii) * 1.1;
  col = mix(col, ph, fill(im, .0015));
  // shadow under frame
  col *= 1. - .2 * fill(sdBox(q - vec2(.01, -.02), sz + .04), .03) * (1. - fill(fr, .002));
  // little label
  col = mix(col, vec3(.85), fill(sdBox(q - vec2(sz.x + .09, -.1), vec2(.03, .015)), .002));
  // crowd silhouettes in the foreground, blurred, drifting
  for (int i = 0; i < 6; i++){
    float fi = float(i);
    vec3 r = h33(vec3(fi, 1., 7.));
    float px = (r.x - .5) * 3. + sin(t * .1 * (r.y + .3) + fi) * .3 - p_track * (1.2 + r.z);
    px = mod(px + 1.6, 3.2) - 1.6;
    float S = .75 + r.z * .3;
    vec2 fp = (p - vec2(px, -.75)) / S;
    float f = sdPose(fp, vec2(0., .5), vec2(0., .8), vec2(0., .93), .075,
      vec2(.04, .26), vec2(.04, 0.), vec2(-.04, .26), vec2(-.04, 0.),
      vec2(.12, .6), vec2(.1, .45), vec2(-.12, .6), vec2(-.1, .45), .11);
    col = mix(col, vec3(.08, .07, .07), fill(f * S, .02) * .8 * p_crowd);
  }
  return col;
}
