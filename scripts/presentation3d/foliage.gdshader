shader_type spatial;
uniform sampler2D source_texture : source_color, filter_linear_mipmap;
uniform vec3 leaf_dark : source_color = vec3(0.16, 0.30, 0.15);
uniform vec3 leaf_light : source_color = vec3(0.46, 0.64, 0.30);
uniform float wind_strength = 0.045;
// Set by Diorama3D: a gust front sweeps across the board every so often; otherwise the air is calm.
global uniform float wind_front;
global uniform float wind_power;
void vertex() {
    float height = max(VERTEX.y, 0.0);
    float phase = NODE_POSITION_WORLD.x * 0.37 + NODE_POSITION_WORLD.z * 0.53;
    float reach = exp(-pow((NODE_POSITION_WORLD.x - wind_front) / 7.0, 2.0));
    float strength = 0.05 + wind_power * reach;
    float sway = sin(TIME * 1.6 + phase) + 0.3 * sin(TIME * 3.7 + phase * 2.0 + VERTEX.x * 2.0);
    // A gust also bends the plant downwind, not just back and forth.
    float lean = wind_power * reach * 0.8;
    VERTEX.x += (sway * strength + lean) * wind_strength * height * height;
    VERTEX.z += sway * strength * wind_strength * 0.4 * height * height;
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
