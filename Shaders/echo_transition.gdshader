shader_type canvas_item;

uniform sampler2D mask_texture : hint_default_white, repeat_enable;

uniform float progress : hint_range(0.0, 1.0) = 1.0;
uniform float player_circle: hint_range(0.0, 1.0, 0.1) = 0.25;
uniform float edge_sharpness : hint_range(0.001, 0.2) = 0.01;
uniform float motion_speed : hint_range(0.0, 5.0) = 0.15; // Speed of organic movement

uniform vec2 center = vec2(0.5, 0.5);
uniform float aspect_ratio = 1.7777778;
uniform vec4 wipe_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

const int MAX_ECHOES = 5;
uniform vec2 echo_positions[5];
uniform float echo_radii[5];
uniform float echo_strengths[5];

void fragment() {
	// 1. Dynamic UV offset over TIME for living, organic movement
	vec2 moving_uv = UV + vec2(sin(TIME * motion_speed * 1.5), cos(TIME * motion_speed)) * 0.08;
	
	// Sample noise texture with moving UVs
	float raw_mask = texture(mask_texture, moving_uv).r;
	
	// Center-normalize the mask value (-0.5 to 0.5) so it wobbles around the real border
	float mask = raw_mask - 0.5;

	// 2. Base player distance field
	vec2 player_diff = UV - center;
	player_diff.x *= aspect_ratio;
	float player_dist = length(player_diff);
	float field_dist = player_dist - player_circle;

	// 3. Smoothly fuse active echo distance fields
	for (int i = 0; i < MAX_ECHOES; i++) {
		if (echo_strengths[i] > 0.001 && echo_radii[i] > 0.0001) {
			vec2 echo_diff = UV - echo_positions[i];
			echo_diff.x *= aspect_ratio;
			float echo_dist = length(echo_diff);

			float echo_field = (echo_dist - echo_radii[i]) / max(echo_strengths[i], 0.01);
			
			float k = 0.15;
			float h = clamp(0.5 + 0.5 * (field_dist - echo_field) / k, 0.0, 1.0);
			field_dist = mix(field_dist, echo_field, h) - k * h * (1.0 - h);
		}
	}

	// 4. Clean Edge Distortion (Prevents floating black spots/islands)
	// Multiply the noise wobble by distance to damp noise far away from the border
	float border_proximity = smoothstep(0.4, 0.0, abs(field_dist));
	float combined_val = field_dist + (mask * 0.15 * border_proximity);

	// 5. Final composite threshold
	float threshold = mix(-0.2, 1.2, progress);
	float alpha = smoothstep(threshold - edge_sharpness, threshold + edge_sharpness, combined_val);

	COLOR = vec4(wipe_color.rgb, alpha * wipe_color.a);
}