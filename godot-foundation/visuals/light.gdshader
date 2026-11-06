shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never, fog_disabled;

uniform vec4 signal_color : source_color = vec4(0.1, 0.8, 1.0, 1.0);
uniform int kind = 0;
uniform int appearance = 2;
uniform float phase = 0.0;
uniform float gain = 1.0;

float segment(vec2 p, vec2 a, vec2 b) {
    vec2 d = b-a;
    return length(p-a-d*clamp(dot(p-a,d)/dot(d,d),0.0,1.0));
}
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
    vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
    return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void fragment() {
    vec2 p = (UV-0.5)*2.0;
    float r = length(p);
    float d = abs(r-0.56);
    if (kind == 0) { d = abs(max(abs(p.x),abs(p.y))-0.44); }
    if (kind == 1) {
        d = min(segment(p,vec2(0,-0.60),vec2(0.54,0.36)),min(segment(p,vec2(0.54,0.36),vec2(-0.54,0.36)),segment(p,vec2(-0.54,0.36),vec2(0,-0.60))));
    }
    if (kind == 2) { d = abs(abs(p.x)+abs(p.y)-0.63)*0.7071; }
    if (kind == 3) { d = min(d,abs(r-0.33)); }
    float core = exp(-pow(d/0.016,2.0));
    float skirt = exp(-d*27.0)*0.34;
    float pulse = 0.96+0.04*sin(TIME*1.1+phase);
    vec3 light_color;
    float strength;
    if (appearance < 2) {
        strength = core;
        if (appearance == 1) {
            float angle=atan(p.y,p.x);
            float orbit=exp(-abs(r-0.78)*75.0)*step(0.0,sin(angle*3.0+phase))*0.16;
            strength += skirt+orbit+exp(-r*r*85.0)*0.45;
        }
        light_color = signal_color.rgb*strength + vec3(core*0.22);
    } else {
        // Soft luminous matter: no solid silhouette, surface lighting or hard edge.
        vec2 drift=vec2(TIME*0.10+phase, -TIME*0.065);
        float n=noise(p*4.0+drift);
        float body=exp(-r*r*11.0)*(0.28+0.26*n);
        float mist=exp(-r*r*4.0)*pow(noise(p*6.0-drift),2.0)*0.17;
        float seed=exp(-r*r*120.0)*0.9;
        float strand=exp(-abs(p.x+sin(p.y*7.0+TIME*0.5+phase)*0.06)*65.0)*exp(-p.y*p.y*16.0)*0.18;
        strength=(body+mist+seed+strand)*(1.0-smoothstep(0.65,1.0,r));
        light_color=signal_color.rgb*strength+vec3(seed*0.30);
    }
    // Unshaded rendering outputs ALBEDO directly; an emission-only output
    // left these markers black in the tested Mobile renderer.
    ALBEDO=light_color*1.65*pulse*gain;
    EMISSION=vec3(0.0);
    ALPHA=1.0;
}

