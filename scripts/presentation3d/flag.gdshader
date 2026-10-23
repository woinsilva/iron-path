shader_type spatial;
render_mode cull_disabled;
uniform vec4 tint : source_color = vec4(0.18, 0.5, 0.53, 1.0);
// Waves travel from the pole (left edge) to the free edge, growing with distance from the pole.
void vertex() {
    float free_edge = clamp(UV.x, 0.0, 1.0);
    float phase = TIME * 3.1 + NODE_POSITION_WORLD.x * 0.7;
    VERTEX.z += sin(phase - UV.x * 6.0) * 0.12 * free_edge;
    VERTEX.y += sin(phase * 0.7 - UV.x * 4.0) * 0.04 * free_edge;
}
void fragment() {
    float shade = 0.82 + 0.18 * sin(TIME * 3.1 - UV.x * 6.0);
    float trim = step(UV.y, 0.1) + step(0.9, UV.y);
    ALBEDO = mix(tint.rgb * shade, vec3(0.86, 0.72, 0.38), clamp(trim, 0.0, 1.0));
    ROUGHNESS = 0.85;
}
