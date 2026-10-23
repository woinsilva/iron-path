shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix;
// Falling water: bright streaks scrolling down a translucent curtain, foamy at the base.
void fragment() {
    float streak = fract(UV.y * 3.0 - TIME * 1.6 + sin(UV.x * 23.0) * 0.35);
    float bands = smoothstep(0.0, 0.25, streak) * (1.0 - smoothstep(0.55, 1.0, streak));
    vec3 water = mix(vec3(0.33, 0.66, 0.74), vec3(0.92, 0.98, 1.0), bands * 0.7 + smoothstep(0.75, 1.0, UV.y) * 0.6);
    ALBEDO = water;
    ALPHA = 0.78;
}
