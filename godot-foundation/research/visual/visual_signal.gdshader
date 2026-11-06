shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never, fog_disabled;

// Research-only alternative to res://visuals/light.gdshader.
// Keep Foundation's common uniforms for per-marker interoperability.
uniform vec4 signal_color : source_color = vec4(0.13, 0.86, 1.0, 1.0);
uniform int kind = 0;
uniform int appearance = 2;
uniform float phase = 0.0;
uniform float gain = 1.0;
uniform float proximity = 0.0;
uniform float hostile = 0.0;
uniform int style_mode = 0; // 0: contour / 1: haze

float seg(vec2 p, vec2 a, vec2 b) {
    vec2 d = b - a;
    return length(p - a - d * clamp(dot(p - a, d) / max(dot(d, d), 0.00001), 0.0, 1.0));
}
float hash21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float smooth_noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i+vec2(1.0,0.0)), f.x),
               mix(hash21(i+vec2(0.0,1.0)), hash21(i+vec2(1.0,1.0)), f.x), f.y);
}
void fragment() {
    vec2 p = (UV - 0.5) * 2.0;
    float r = length(p);
    float t = TIME;
    float outline = abs(r - 0.53);
    if (kind == 0) outline = abs(max(abs(p.x), abs(p.y)) - 0.48);
    if (kind == 1) {
        outline = min(seg(p, vec2(0.0,-0.60), vec2(0.55,0.36)),
                  min(seg(p, vec2(0.55,0.36), vec2(-0.55,0.36)),
                      seg(p, vec2(-0.55,0.36), vec2(0.0,-0.60))));
    }
    if (kind == 2) outline = abs(abs(p.x) + abs(p.y) - 0.65) * 0.7071;
    if (kind == 3) outline = min(outline, abs(r - 0.30));

    float closeup = smoothstep(0.12, 0.88, proximity);
    float beat = 0.86 + 0.14 * sin(t * 2.2 + phase);
    float core = exp(-r*r*115.0) * (0.7 + 0.3*beat);
    float ring = exp(-pow(outline / (0.016 + 0.004*closeup), 2.0));
    float halo = exp(-outline*20.0)*0.31;
    float edge = exp(-pow((r-0.76)/0.016,2.0))*(0.11 + 0.10*closeup);
    float enemy_cross = (exp(-abs(p.x)*95.0)*exp(-abs(p.y)*10.0)
                       + exp(-abs(p.y)*95.0)*exp(-abs(p.x)*10.0))*0.36*hostile;
    float amount;
    if (style_mode == 0) {
        // Readability-first target: hard silhouette stays visible at long range.
        amount = ring * (0.60 + 0.36*closeup) + halo*0.7 + edge + core + enemy_cross;
    } else {
        // Soft luminous field with a progressively revealed outline on approach.
        vec2 drift = vec2(t*0.12 + phase, -t*0.075);
        float n = smooth_noise(p*5.0 + drift);
        float cloud = exp(-r*r*8.0) * (0.32 + 0.28*n);
        float ribbons = exp(-abs(p.x + 0.10*sin(7.0*p.y+t*0.6+phase))*39.0)
                        * exp(-p.y*p.y*7.0)*0.24;
        float rim = ring * (0.12 + 0.62*closeup);
        amount = cloud + ribbons + core*1.6 + rim + edge*0.35 + enemy_cross*0.65;
        amount *= 1.0 - smoothstep(0.88, 1.03, r);
    }
    // A separate warm white core on enemies increases category contrast.
    vec3 color_value = signal_color.rgb * amount + vec3(0.16,0.20,0.23) * core;
    color_value += vec3(0.18,0.07,0.07) * hostile * enemy_cross;
    ALBEDO = color_value * (1.25 + 0.22*beat) * gain;
    EMISSION = vec3(0.0);
    ALPHA = 1.0;
}
