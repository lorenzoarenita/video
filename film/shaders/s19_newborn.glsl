// Thirty-eight. Now she is the one looking down at a newborn in her arms. "Hola... hola, mi vida. Alba."
uniform float p_focus;
uniform float p_eyes;  // baby opens eyes 0..1
uniform float p_tear;  // wet blur in her eyes

vec3 scene(vec2 uv, float t){
  vec2 p = cuv(uv);
  float br = sin(t * 1.5) * .004;
  p += vec2(sin(t * .4) * .006, br);
  float blur = mix(.04, .006, p_focus) + p_tear * .02 * (.5 + .5 * sin(t * .7));
  // soft white sheets, warm window light from left
  vec3 col = vec3(.55, .5, .45) * (.55 + .5 * smoothstep(1., -.8, p.x));
  float folds = fbm(p * vec2(3., 5.) + 3.);
  col *= .8 + .35 * folds;
  // her forearm (left) cradling, skin, bottom
  float arm = sdCaps(p, vec2(-1.2, -.55), vec2(.3, -.35), .16, .14);
  col = mix(col, vec3(.85, .6, .48) * .6, fill(arm, blur * 2. + .01));
  // blanket bundle
  vec2 bp = p - vec2(-.02, -.02);
  float bundle = sdEll(bp * rot(.25), vec2(.42, .3));
  vec3 blank = vec3(.85, .8, .72) * (.6 + .4 * fbm(bp * 8.)) * (.7 + .5 * smoothstep(.4, -.4, bp.x));
  col = mix(col, blank, fill(bundle, blur * 2. + .006));
  // blanket fold edge around face
  vec2 fcp = bp - vec2(.06, .04);
  float hood = sdEll(fcp * rot(.25), vec2(.2, .17));
  col = mix(col, blank * .7, fill(hood, blur + .005));
  // baby face
  float face = sdEll(fcp * rot(.25), vec2(.15, .13));
  vec3 skin = vec3(1., .66, .55) * (.55 + .45 * smoothstep(.2, -.15, fcp.x));
  float fm = fill(face, blur + .003);
  vec2 q = fcp * rot(.25);
  // closed eyes (curved lines) / opening eyes (dark almonds)
  float eo = sat(p_eyes);
  for (int i = 0; i < 2; i++){
    float s = i == 0 ? -1. : 1.;
    vec2 e = q - vec2(s * .055, .02);
    float lid = abs(e.y + e.x * e.x * 6. - .0) - .003;
    float lidM = fill(lid, blur + .002) * step(abs(e.x), .028);
    float eye = sdEll(e, vec2(.022, .012 * eo + .001));
    skin = mix(skin, vec3(.35, .18, .14), lidM * (1. - eo) * .7);
    skin = mix(skin, vec3(.05, .04, .05), fill(eye, blur + .002) * eo);
    skin += vec3(1.) * fill(sdCircle(e - vec2(-.006, .004), .004), .002) * eo * .5;
  }
  // nose and mouth hints
  skin *= 1. - .15 * fill(sdEll(q - vec2(0., -.025), vec2(.012, .008)), blur + .004);
  skin *= 1. - .3 * fill(sdEll(q - vec2(0., -.065), vec2(.02, .005)), blur + .003);
  // cheeks
  skin += vec3(.3, .05, .05) * fill(sdEll(vec2(abs(q.x) - .07, q.y + .035), vec2(.03, .02)), .02) * .3;
  col = mix(col, skin, fm);
  // tiny hand near face
  vec2 hp = q - vec2(-.12, -.1);
  float hand = sdEll(hp, vec2(.03, .025));
  for (int i = 0; i < 4; i++){ float fi = float(i); hand = smin(hand, sdCircle(hp - vec2(-.025 + fi * .015, .025 - abs(fi - 1.5) * .004), .009), .006); }
  col = mix(col, vec3(1., .65, .55) * .7, fill(hand, blur + .002));
  // window glow
  col += vec3(1.5, 1.2, .9) * glow(length(p - vec2(-1.2, .4)), .4) * .25;
  return col;
}
