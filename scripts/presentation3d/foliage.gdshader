shader_type spatial;
uniform sampler2D source_texture : source_color, filter_linear_mipmap;
uniform vec3 leaf_dark : source_color = vec3(0.16, 0.30, 0.15);
uniform vec3 leaf_light : source_color = vec3(0.46, 0.64, 0.30);
uniform float wind_strength = 0.045;
// Wind: the canopy sways more the higher the vertex, with a slower gust layered on top; each plant
// gets its own phase from its world position so a forest never moves in lockstep.
void vertex() {
    float height = max(VERTEX.y, 0.0);
    float phase = NODE_POSITION_WORLD.x * 0.37 + NODE_POSITION_WORLD.z * 0.53;
    float gust = 0.6 + 0.4 * sin(TIME * 0.35 + phase * 0.2);
    float sway = (sin(TIME * 1.7 + phase) + 0.35 * sin(TIME * 3.9 + phase * 2.0 + VERTEX.x * 2.0)) * gust;
    VERTEX.x += sway * wind_strength * height * height;
    VERTEX.z += sway * wind_strength * 0.45 * height * height;
}
void fragment() {
    vec3 c = texture(source_texture, UV).rgb;
    if (c.g > c.r * 1.12 && c.g > c.b * 1.25) {
        float value = dot(c, vec3(0.23, 0.65, 0.12));
        c = mix(leaf_dark, leaf_light, smoothstep(0.10, 0.95, value));
    }
    ALBEDO = c;
    ROUGHNESS = 0.92;
}
