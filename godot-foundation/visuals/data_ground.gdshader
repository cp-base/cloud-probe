shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled;

// Experimental, non-colliding visual plane below the camera.
// Coordinates are world-anchored despite following the player as a mesh.
uniform float noise_level = 1.0;
uniform float flow_level = 1.0;
uniform vec3 effect_tint : source_color = vec3(0.34, 0.72, 0.86);
varying vec2 world_xz;

float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
    world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
    float dist = length(world_xz - CAMERA_POSITION_WORLD.xz);
    float fade = smoothstep(75.0, 145.0, dist)
        * (1.0 - smoothstep(430.0, 650.0, dist));

    float grain = 0.0;
    if (noise_level > 0.5) {
        vec2 grain_cell = floor(world_xz / 7.0);
        float fine = hash21(grain_cell);
        float coarse = hash21(floor(world_xz / 28.0));
        float threshold = noise_level > 1.5 ? 0.865 : 0.935;
        grain = step(threshold, fine) * step(0.22, coarse);
    }

    float flow = 0.0;
    if (flow_level > 0.5) {
        vec2 tile = floor(world_xz / 240.0);
        vec2 local = fract(world_xz / 240.0) - vec2(0.5);
        float seed = hash21(tile);
        float angle = hash21(tile + vec2(7.0, 13.0)) * 6.2831853;
        vec2 direction = vec2(cos(angle), sin(angle));
        float across = dot(local, vec2(-direction.y, direction.x));
        float along = dot(local, direction);
        float lateral = (hash21(tile + vec2(19.0, 5.0)) - 0.5) * 0.28;
        float line = exp(-abs(across - lateral) * 430.0);
        line *= 1.0 - smoothstep(0.22, 0.43, abs(along));
        line *= step(0.28, seed);
        float packet_pos = fract(TIME * (0.21 + seed * 0.13) + seed * 4.1) * 0.72 - 0.36;
        float packet = exp(-pow((along - packet_pos) / 0.040, 2.0));
        flow = line * (0.13 + 0.90 * packet);
    }

    float grain_alpha = grain * (noise_level > 1.5 ? 0.18 : 0.085);
    float stream_alpha = flow * (flow_level > 1.5 ? 0.40 : 0.23);
    float alpha = (grain_alpha + stream_alpha) * fade;
    ALBEDO = effect_tint;
    ALPHA = clamp(alpha, 0.0, 0.55);
}
