shader_type spatial;
render_mode cull_disabled;
// Packed dirt trail: CC0 photo texture along the road strip, with darker worn edges.
uniform sampler2D trail_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D trail_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float tile = 0.35;
uniform vec3 tint : source_color = vec3(1.0);
varying vec3 world_position;
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
    vec2 uv = world_position.xz * tile;
    float edge = smoothstep(0.0, 0.18, UV.x) * smoothstep(1.0, 0.82, UV.x);
    ALBEDO = texture(trail_albedo, uv).rgb * tint * mix(0.72, 1.0, edge);
    NORMAL_MAP = texture(trail_normal, uv).rgb;
    ROUGHNESS = 0.97;
    ALPHA = 1.0;
}
