shader_type spatial;
uniform sampler2D grain : repeat_enable, filter_linear_mipmap;
uniform vec3 deep_color : source_color = vec3(0.26, 0.36, 0.14);
uniform vec3 light_color : source_color = vec3(0.43, 0.51, 0.23);
uniform float grain_scale = 1.0;
uniform vec3 slope_color : source_color = vec3(0.6, 0.5, 0.33);
varying vec3 world_position;
varying vec3 world_normal;
void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
    float a = texture(grain, world_position.xz * 0.065 * grain_scale).r;
    float b = texture(grain, world_position.xz * 0.36 * grain_scale).r;
    vec3 grass = mix(deep_color, light_color, smoothstep(0.12, 0.82, a * 0.88 + b * 0.12));
    // Slopes show bare earth and lit crests read lighter, so the hills are visible from the high camera.
    float slope = smoothstep(0.14, 0.34, 1.0 - world_normal.y);
    ALBEDO = mix(grass, slope_color * (0.85 + 0.3 * b), slope);
    ROUGHNESS = 0.98;
}
