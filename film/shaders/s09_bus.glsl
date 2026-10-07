// Fifteen. Night bus through the city: streaking lights in the window, her reflection's absence, the music.
uniform float p_speed;
uniform float p_rain;

vec3 scene(vec2 uv, float t){
  vec2 p = cuv(uv);
  float sp = 1. + p_speed;
  vec3 col = vec3(.01, .012, .02);
  // passing buildings: vertical bands of lit windows moving left (parallax layers)
  for (int L = 0; L < 3; L++){
    float fl = float(L);
    float spd = (1.6 - fl * .45) * sp;
    float x = p.x + t * spd * .35 + fl * 7.;
    float bid = floor(x * (1.6 + fl));
    float bx = fract(x * (1.6 + fl));
    vec3 bn = h33(vec3(bid, fl, 3.));
    float top = .05 + bn.x * .35 - fl * .05;
    float inB = step(.08, bx) * step(bx, .92) * step(p.y, top) * step(-.3 + fl * .03, p.y);
    vec2 wq = vec2(bx * 8., p.y * (14. + fl * 4.));
    vec3 wn = h33(vec3(floor(wq) + bid * 13., fl));
    float lit = step(.55, wn.x) * step(.25, fract(wq.x)) * step(fract(wq.x), .75) * step(.3, fract(wq.y));
    vec3 wc = mix(vec3(1.4, .8, .35), vec3(.7, .9, 1.3), step(.8, wn.y));
    float dimL = 1. / (1. + fl * 1.2);
    col = mix(col, vec3(.02, .02, .035) * dimL, inB * .9);
    col += wc * lit * inB * .55 * dimL;
  }
  // street lamps streaking (motion blur) and car lights
  for (int i = 0; i < 2; i++){
    float fi = float(i);
    float x = fract((p.x + t * (2.2 + fi) * sp * .5) * .5 + fi * .37);
    float lamp = smoothstep(.08, .0, abs(x - .5) * (1. + 0.)) ;
    col += vec3(2., 1.1, .4) * lamp * glow(abs(p.y - (.28 - fi * .06)), .02) * .6;
  }
  col += bokeh(p + vec2(t * .6 * sp, 0.), 21., 5., .5, vec3(1.6, .5, .4), vec3(.4, .8, 1.5), t, 0.) * .12 * smoothstep(-.1, -.4, p.y);
  col += bokeh(p * .7 + vec2(t * 1.1 * sp, 0.), 23., 4., .45, vec3(1.8, 1.1, .5), vec3(1.6, .4, .9), t, 0.) * .07;
  // window glass: rain streaks diagonal + dirt
  vec3 rg = rainGlass(uv * vec2(1., 1.) + vec2(t * .05, 0.), t, p_rain);
  col += vec3(.4, .4, .5) * rg.z * .15;
  col *= .9 + .1 * fbm(p * 8.);
  // window frame and bus interior reflection
  float frame = sdBox(p - vec2(0., .03), vec2(1.02, .38)) ;
  col *= fill(frame, .01);
  vec3 interior = vec3(.03, .035, .05) + vec3(.1, .12, .2) * smoothstep(-.5, -.3, p.y) * .2;
  col = mix(interior, col, fill(frame, .01));
  // faint reflection of the bus ceiling lights
  col += vec3(.25, .3, .35) * glow(abs(p.y - .3), .005) * smoothstep(.3, 0., abs(fract(p.x * 1.5 + .2) - .5)) * .15;
  return col;
}
