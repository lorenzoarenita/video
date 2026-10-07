// Film post-process: lens (CA, bloom/halation), tone, grade, vignette, grain, fades.
// All params default to 0 = neutral look.
uniform float p_exposure;   // stops
uniform float p_bloom;      // extra bloom
uniform float p_ca;         // extra chromatic aberration
uniform float p_sat;        // saturation offset
uniform float p_grain;      // extra grain
uniform float p_vig;        // extra vignette
uniform float p_white;      // fade to white 0..1
uniform float p_temp;       // warm(+)/cool(-)
uniform float p_blur;       // defocus whole frame (mip level)
uniform float p_lift;       // raise blacks
uniform float p_contrast;
uniform float p_mono;       // 0..1 sepia memory

float h12(vec2 p){ vec3 p3 = fract(vec3(p.xyx) * .1031); p3 += dot(p3, p3.yzx + 33.33); return fract((p3.x + p3.y) * p3.z); }

vec3 aces(vec3 x){ const float a=2.51,b=0.03,c=2.43,d=0.59,e=0.14; return clamp((x*(a*x+b))/(x*(c*x+d)+e),0.,1.); }

vec3 samp(vec2 uv, float lod){ return textureLod(uScene, uv, lod).rgb; }

void main(){
  vec2 uv = gl_FragCoord.xy / uRes;
  vec2 d = uv - .5;
  float r2 = dot(d * vec2(uRes.x/uRes.y, 1.), d * vec2(uRes.x/uRes.y, 1.));
  float lod = max(p_blur, 0.);
  float ca = (0.0005 + p_ca) * r2 * 4.;
  vec3 col;
  col.r = samp(uv - d * ca, lod).r;
  col.g = samp(uv, lod).g;
  col.b = samp(uv + d * ca, lod).b;
  // bloom / halation from mip chain
  vec3 bl = vec3(0.);
  bl += samp(uv, 2.5 + lod) * .30;
  bl += samp(uv, 4. + lod) * .30;
  bl += samp(uv, 5.5 + lod) * .25;
  bl += samp(uv, 7. + lod) * .15;
  vec3 hal = max(bl - .55, 0.);
  col += hal * vec3(1.15, .85, .65) * (0.55 + p_bloom * 2.);
  col = mix(col, bl, clamp(.05 + p_bloom * .4, 0., 1.));
  col *= exp2(p_exposure);
  // white balance
  col *= vec3(1. + p_temp * .12, 1., 1. - p_temp * .14);
  col = aces(col);
  // grade
  float l = dot(col, vec3(.2126, .7152, .0722));
  col = mix(vec3(l), col, 1. + p_sat);
  col = mix(col, vec3(l) * vec3(1.08, .96, .78), clamp(p_mono, 0., 1.));
  col = (col - .5) * (1. + p_contrast) + .5;
  col = col * (1. - (.012 + p_lift)) + (.012 + p_lift) * vec3(.95, 1., 1.05);
  // vignette
  float v = smoothstep(1.25, .25, length(d * vec2(1.25, 1.)) * (1. + p_vig));
  col *= mix(.55, 1., v);
  col = mix(col, vec3(1.), clamp(p_white, 0., 1.));
  col *= uFade;
  // grain (luma dependent, temporal)
  float g = h12(gl_FragCoord.xy + fract(uFrame * .6180339) * 917.) + h12(gl_FragCoord.xy * 1.37 + fract(uFrame * .414) * 517.) - 1.;
  float gamt = (0.045 + p_grain) * (1. - l * .6);
  col += g * gamt * (0.35 + 0.65 * uFade);
  col += (h12(gl_FragCoord.xy + uFrame) - .5) / 255.;
  fragColor = vec4(clamp(col, 0., 1.), 1.);
}
