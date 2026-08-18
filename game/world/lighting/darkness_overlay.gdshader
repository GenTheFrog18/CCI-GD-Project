shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform sampler2D darkness_mask : repeat_disable, filter_linear;
uniform vec2 mask_origin;
uniform vec2 mask_size;
uniform mat3 screen_to_world;
uniform vec4 light_positions[16];
uniform vec4 light_parameters[16];
uniform int light_count = 0;
uniform vec4 darkness_tint : source_color = vec4(0.08, 0.10, 0.14, 1.0);
uniform float maximum_screen_darkness = 0.82;

void fragment() {
	vec4 world_color = texture(screen_texture, SCREEN_UV);
	vec2 screen_position = SCREEN_UV / SCREEN_PIXEL_SIZE;
	vec2 world_position = (screen_to_world * vec3(screen_position, 1.0)).xy;
	vec2 mask_uv = (world_position - mask_origin) / mask_size;
	float base_darkness = 0.0;
	if (all(greaterThanEqual(mask_uv, vec2(0.0))) && all(lessThanEqual(mask_uv, vec2(1.0)))) {
		base_darkness = texture(darkness_mask, mask_uv).r;
	}
	float light_reveal = 0.0;
	for (int index = 0; index < 16; index++) {
		if (index >= light_count) {
			break;
		}
		float radius = max(light_positions[index].z, 1.0);
		float distance_ratio = distance(world_position, light_positions[index].xy) / radius;
		float contribution = smoothstep(1.0, 0.0, distance_ratio) * light_parameters[index].x;
		light_reveal = max(light_reveal, contribution);
	}
	float final_darkness = clamp(base_darkness - light_reveal, 0.0, 1.0) * maximum_screen_darkness;
	world_color.rgb = mix(world_color.rgb, world_color.rgb * darkness_tint.rgb, final_darkness);
	COLOR = world_color;
}
