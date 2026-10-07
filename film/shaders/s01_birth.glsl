// Birth: eyes open for the first time. Overexposed, defocused world; a face of light leans in.
uniform float p_open;   // eyelid opening 0..1
uniform float p_focus;  // 0 = totally blurred, 1 = soft but readable
uniform float p_face;   // mother's face presence 0..1
uniform float p_smile;
uniform float p_glare;  // overexposure
uniform float p_old;    // 1 = the last day: cooler light, long hair (her daughter)

vec3 scene(vec2 uv, float t){
  vec2 p = cuv(uv);
  float blur = mix(.3, .015, sqrt(sat(p_focus)));
  // tiny head motion of a newborn
  p += vec2(sin(t * .7) * .01, sin(t * .53 + 1.) * .008) * (1. - p_focus * .5);
  // room: warm wall, window top-left
  vec3 wall = mix(vec3(.55, .38, .26), vec3(.95, .78, .62), sat(.6 - p.y + p.x * .2));
  wall = mix(wall, vec3(.6, .62, .64), p_old * .6);
  vec3 col = wall * .3 * (1. - .6 * smoothstep(.3, 1.2, length(p - vec2(-.4, .1))));
  float win = sdBox(p - vec2(-.55, .12), vec2(.32, .42));
  float winM = fill(win, blur * .9);
  col += vec3(2.4, 2.1, 1.7) * winM * (.6 + .6 * p_glare);
  col += vec3(1.2, .8, .5) * glow(max(win, 0.), .06 + blur * .3) * .5 * (1. + p_glare);
  // window frame cross, very soft
  float frame = min(abs(p.x + .55), abs(p.y - .1));
  col *= 1. - .35 * fill(frame - .012, blur * .6) * winM * p_focus;
  // curtain sway
  float cur = sdBox(p - vec2(-.95 + sin(t * .3) * .02, .05), vec2(.12, .6));
  col = mix(col, vec3(1.4, 1.1, .85), fill(cur, blur) * .6);
  // bokeh speckles from window
  col += bokeh(p, 2., 3., .8, vec3(1.3, 1., .7), vec3(1., .85, .7), t, .02) * .12 * (1. - p_focus * .4);
  // the face
  float lean = p_face;
  vec2 fc = vec2(.25 - (1. - lean) * .9, -.02 + sin(t * .4) * .015);
  vec2 fp = p - fc;
  fp *= rot(-.12 + sin(t * .3) * .03);
  float head = sdEll(fp, vec2(.30, .38));
  float hair = sdEll(fp - vec2(.0, .08), vec2(.36, .44));
  hair = mix(hair, smin(hair, sdBox(fp - vec2(.0, -.3), vec2(.36, .4)), .1), p_old);
  float hairN = fbm(fp * 9. + t * .05) * .06;
  vec3 skin = vec3(1.25, .78, .55);
  float hm = fill(hair + hairN, blur * 1.1) * lean;
  col = mix(col, vec3(.22, .12, .08), hm * .92);
  // rim light on hair from window
  float rim = smoothstep(.08 + blur, 0., abs(hair + hairN)) * sat(-fp.x * 2. + .5);
  col += vec3(2.2, 1.6, 1.) * rim * lean * .9 * (1. + p_glare * .5);
  float fm = fill(head, blur) * lean;
  vec3 face = skin * (.55 + .5 * sat(-fp.x * 1.4 + .3)) ;
  // features (very soft)
  float fb = blur * 1.4 + .02;
  float eyes = fill(sdEll(vec2(abs(fp.x) - .11, fp.y - .06), vec2(.05, .028)), fb);
  face *= 1. - eyes * .55 * p_focus;
  float mouthY = fp.y + .17 - fp.x * fp.x * 1.2 * p_smile;
  float mouth = fill(sdBox(vec2(fp.x, mouthY), vec2(.07, .006)), fb);
  face *= 1. - mouth * .45 * p_focus;
  face += vec3(.5, .2, .15) * fill(sdEll(vec2(abs(fp.x) - .15, fp.y + .07), vec2(.07, .05)), fb * 2.) * .25;
  col = mix(col, face, fm);
  // soft eye moisture / glare veil
  col += vec3(1., .85, .7) * (.05 + p_glare * .25) * (1. - p_focus * .7);
  col *= .6;
  // eyelids
  float soft = mix(.25, .12, p_open);
  float lid = eyelids(uv, p_open, soft);
  vec3 lidCol = vec3(.35, .06, .03) * (.25 + .5 * p_glare); // light through eyelids: warm red
  col = mix(lidCol * (.6 + .4 * sin(t * 1.3) * 0.), col, lid);
  return col;
}
