shader_type spatial;
uniform sampler2D source_texture : source_color, filter_linear_mipmap;
uniform vec3 leaf_dark : source_color = vec3(0.16, 0.30, 0.15);
uniform vec3 leaf_light : source_color = vec3(0.46, 0.64, 0.30);
void fragment() {
    vec3 c = texture(source_texture, UV).rgb;
    if (c.g > c.r * 1.12 && c.g > c.b * 1.25) {
        float value = dot(c, vec3(0.23, 0.65, 0.12));
        c = mix(leaf_dark, leaf_light, smoothstep(0.10, 0.95, value));
    }
    ALBEDO = c;
    ROUGHNESS = 0.92;
}
