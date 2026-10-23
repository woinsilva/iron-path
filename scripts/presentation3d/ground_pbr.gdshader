shader_type spatial;
// Realistic ground: two tiled CC0 photo materials (meadow and forest floor) blended by a soft noise
// mask, sampled in world space so the terrain mesh can be any shape.
uniform sampler2D grass_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D grass_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D soil_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D soil_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D mask_noise : filter_linear_mipmap, repeat_enable;
uniform float tile = 0.18;
uniform vec3 tint : source_color = vec3(1.0);
varying vec3 world_position;
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
    vec2 uv = world_position.xz * tile;
    float m = smoothstep(0.58, 0.8, texture(mask_noise, world_position.xz * 0.02).r);
    vec3 grass = texture(grass_albedo, uv).rgb;
    // Push the dry photo grass towards a lush meadow green while keeping its detail.
    float luma = dot(grass, vec3(0.3, 0.59, 0.11));
    grass = mix(vec3(luma) * vec3(0.55, 0.95, 0.38) * 1.35, grass, 0.3);
    vec3 soil = texture(soil_albedo, uv * 0.8).rgb;
    // Large-scale tone variation breaks up visible tiling.
    float tone = 0.88 + 0.24 * texture(mask_noise, world_position.xz * 0.006).r;
    ALBEDO = mix(grass, soil, m) * tint * tone;
    NORMAL_MAP = mix(texture(grass_normal, uv).rgb, texture(soil_normal, uv * 0.8).rgb, m);
    ROUGHNESS = 0.95;
}
