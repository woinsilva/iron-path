shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;
// Camera-matched sprite of a realistic model (rendered offline in Blender). Leaves near the top bend
// with the travelling gust front set by Diorama3D; the trunk base stays planted.
uniform sampler2D sprite : source_color, filter_linear_mipmap, repeat_disable;
uniform float sway = 1.0;
uniform float base_v = 0.8;
global uniform float wind_front;
global uniform float wind_power;
void vertex() {
    float lift = clamp((base_v - UV.y) / base_v, 0.0, 1.0);
    float phase = NODE_POSITION_WORLD.x * 0.37 + NODE_POSITION_WORLD.z * 0.53;
    float reach = exp(-pow((NODE_POSITION_WORLD.x - wind_front) / 7.0, 2.0));
    float breeze = sin(TIME * 1.3 + phase) * 0.012;
    float gust = wind_power * reach * (0.09 + 0.03 * sin(TIME * 5.0 + phase));
    VERTEX.x += (breeze + gust) * sway * lift * lift;
}
void fragment() {
    vec4 c = texture(sprite, UV);
    ALBEDO = c.rgb * 1.18;
    ALPHA = c.a;
    ALPHA_SCISSOR_THRESHOLD = 0.45;
    ROUGHNESS = 0.9;
}
