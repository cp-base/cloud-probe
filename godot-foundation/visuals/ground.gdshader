shader_type spatial;
render_mode unshaded;
varying vec2 ground_position;
uniform vec3 viewer_position;
void vertex() { ground_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xz; }
void fragment() {
    vec2 coord=ground_position/6.0;
    vec2 grid=abs(fract(coord-0.5)-0.5)/max(fwidth(coord),vec2(0.00001));
    float lines=1.0-min(min(grid.x,grid.y),1.0);
    float fade=exp(-length(ground_position-viewer_position.xz)*0.028);
    ALBEDO=vec3(0.012,0.033,0.044)+vec3(0.035,0.075,0.083)*lines*fade;
}

