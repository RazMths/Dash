shader_type canvas_item;

uniform sampler2D mask_texture : hint_default_white, filter_nearest;

uniform float progress : hint_range(0.0, 1.0) = 1.0;
uniform float edge_sharpness : hint_range(0.001, 0.2) = 0.01;

uniform vec2 center = vec2(0.5, 0.5);
uniform float aspect_ratio = 1.7777778;
uniform vec4 wipe_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

const int MAX_ECHOES = 5;
uniform vec2 echo_positions[5];
uniform float echo_radii[5];
uniform float echo_strengths[5];

void fragment() {
	vec2 uv = UV;	
	float mask = texture(mask_texture, uv).r;

	// 1. Base player field (radius ~0.35)
	vec2 player_diff = uv - center;
	player_diff.x *= aspect_ratio;
	float player_dist = length(player_diff);
	float field_dist = player_dist - 0.35;

	// 2. Smoothly fuse expanding echo fields
	for (int i = 0; i < MAX_ECHOES; i++) {
		if (echo_strengths[i] > 0.001 && echo_radii[i] > 0.0001) {
			vec2 echo_diff = uv - echo_positions[i];
			echo_diff.x *= aspect_ratio;
			float echo_dist = length(echo_diff);

			// Echo field extends outward from its origin
			float echo_field = (echo_dist - echo_radii[i]) / max(echo_strengths[i], 0.01);
			
			// Smooth minimum for liquid fusion
			float k = 0.15;
			float h = clamp(0.5 + 0.5 * (field_dist - echo_field) / k, 0.0, 1.0);
			field_dist = mix(field_dist, echo_field, h) - k * h * (1.0 - h);
		}
	}

	// 3. Apply comic noise mask to the unified contour
	float final_val = (field_dist + 0.35) * 1.2 - mask * 0.4;

	// 4. Final darkness mask
	float threshold = mix(-0.2, 1.2, progress);
	float alpha = smoothstep(threshold - edge_sharpness, threshold + edge_sharpness, final_val);

	COLOR = vec4(wipe_color.rgb, alpha * wipe_color.a);
}