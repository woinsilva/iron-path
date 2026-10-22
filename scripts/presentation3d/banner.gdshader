shader_type spatial;
uniform vec4 tint : source_color = vec4(0.12, 0.43, 0.48, 1.0);
uniform float phase = 0.0;
uniform float pulse = 0.0;
void vertex() {
    float free_edge = smoothstep(-0.575, 0.575, VERTEX.x);
    VERTEX.z += sin(phase * 2.4 + VERTEX.x * 4.0 + VERTEX.y) * 0.12 * free_edge;
}
void fragment() {
    vec3 base = tint.rgb;
    float trim = step(UV.x, 0.08) + step(0.92, UV.x) + step(UV.y, 0.06) + step(0.94, UV.y);
    float sigil = 1.0 - step(0.12, abs(UV.x - 0.5) + abs(UV.y - 0.5));
    ALBEDO = mix(base, vec3(0.82, 0.68, 0.35), clamp(trim + sigil, 0.0, 1.0));
    EMISSION = base * pulse * 0.2;
    ROUGHNESS = 0.9;
}
