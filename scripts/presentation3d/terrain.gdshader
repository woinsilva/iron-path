shader_type spatial;
uniform sampler2D grain : repeat_enable, filter_linear_mipmap;
uniform vec3 deep_color : source_color = vec3(0.26, 0.36, 0.14);
uniform vec3 light_color : source_color = vec3(0.43, 0.51, 0.23);
uniform float grain_scale = 1.0;
varying vec3 world_position;
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
    float a = texture(grain, world_position.xz * 0.065 * grain_scale).r;
    float b = texture(grain, world_position.xz * 0.36 * grain_scale).r;
    ALBEDO = mix(deep_color, light_color, smoothstep(0.12, 0.82, a * 0.88 + b * 0.12));
    ROUGHNESS = 0.98;
}
