shader_type sky;

// Independent comparison study: intentionally sparse angular backgrounds.
// No TIME uniform: the sky is recalculated only when its mode changes.
uniform int variant = 1;
uniform vec3 zenith_color : source_color = vec3(0.027, 0.078, 0.122);
uniform vec3 horizon_color : source_color = vec3(0.063, 0.153, 0.192);

float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float architecture(vec2 angle, float bearing, float scale) {
    float x = (angle.x - bearing) / scale;
    float y = angle.y / scale;
    float v = 0.0;
    for (int i = -2; i <= 2; i++) {
        float fi = float(i);
        float dx = x - fi * 0.028;
        float height = 0.032 + (1.0 - abs(fi) * 0.24) * 0.063;
        float pillar = exp(-abs(dx) * 470.0)
            * smoothstep(-0.026, -0.012, y)
            * (1.0 - smoothstep(height - 0.004, height + 0.004, y));
        v = max(v, pillar);
    }
    float ellipse = length(vec2(x / 0.125, (y - 0.063) / 0.031));
    v = max(v, exp(-abs(ellipse - 1.0) * 90.0) * 0.65);
    return clamp(v, 0.0, 1.0);
}

void sky() {
    float h = EYEDIR.y;
    float horizon_factor = pow(1.0 - clamp(abs(h), 0.0, 1.0), 3.2);
    vec3 color = mix(zenith_color, horizon_color, horizon_factor);

    if (variant > 0) {
        float az = atan(EYEDIR.x, EYEDIR.z);
        float haze = exp(-pow(h / 0.17, 2.0));
        color += vec3(0.0, 0.004, 0.0055) * haze
            * (0.55 + 0.45 * sin(az * 5.0 + sin(az * 9.0)));

        // Very small, deliberately dim static information particles.
        vec2 cells = vec2(az * 145.0, h * 220.0);
        float star_seed = hash21(floor(cells));
        float core = 1.0 - smoothstep(0.08, 0.26, length(fract(cells) - vec2(0.5)));
        float star = step(0.992, star_seed) * core * 0.032;
        color += vec3(0.27, 0.74, 0.87) * star;

        // Thin distant data-lines: restrained to the middle distance/horizon.
        float lines = 0.0;
        for (int i = 0; i < 4; i++) {
            float fi = float(i);
            float wave = 0.008 * sin(az * (4.2 + fi) + fi * 2.3);
            float line_y = -0.029 + fi * 0.020 + wave;
            lines += exp(-pow((h - line_y) / 0.0016, 2.0)) * 0.006;
        }
        color += vec3(0.24, 0.73, 0.85) * lines;
    }

    if (variant > 1) {
        float az = atan(EYEDIR.x, EYEDIR.z);
        vec2 angular = vec2(az, h);
        float ruins = architecture(angular, 0.27, 1.0) * 0.60
            + architecture(angular, -0.72, 0.73) * 0.45;
        color += vec3(0.035, 0.09, 0.115) * clamp(ruins, 0.0, 1.0);
    }
    COLOR = color;
}
