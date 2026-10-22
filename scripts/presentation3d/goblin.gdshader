shader_type spatial;
uniform sampler2D source_texture : source_color, filter_linear_mipmap;
uniform bool green_skin = false;
void fragment() {
    vec3 c = texture(source_texture, UV).rgb;
    if (c.g > c.r * 1.2 && c.b > c.r * 1.1 && c.g > 0.15) {
        float value = dot(c, vec3(0.25, 0.5, 0.25));
        c = mix(vec3(0.20, 0.035, 0.025), vec3(0.63, 0.15, 0.09), smoothstep(0.05, 0.8, value));
    } else if (green_skin && c.r > c.g * 1.10 && c.g > c.b * 1.15 && c.r > 0.4) {
        float value = dot(c, vec3(0.33));
        c = mix(vec3(0.24, 0.34, 0.09), vec3(0.53, 0.65, 0.23), smoothstep(0.1, 0.8, value));
    }
    ALBEDO = c;
    ROUGHNESS = 0.88;
}
