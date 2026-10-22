shader_type spatial;
uniform float phase = 0.0;
uniform vec3 deep_color : source_color = vec3(0.16,0.39,0.43);
uniform vec3 ripple_color : source_color = vec3(0.48,0.69,0.67);
varying vec3 world_position;
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment() {
    float flow = sin(world_position.z * 2.4 + sin(world_position.x * 3.1) * 0.6 + phase * 0.8);
    float ripple = smoothstep(0.88,1.0,flow) * 0.14;
    ALBEDO = mix(deep_color,ripple_color,ripple);
    ROUGHNESS = 0.28;
    METALLIC = 0.12;
    SPECULAR = 0.55;
}
