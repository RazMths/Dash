shader_type canvas_item;

uniform sampler2D mask_texture : hint_default_white, filter_nearest;

uniform float progress : hint_range(0.0, 1.0) = 1.0; // Default to 1.0 (black background)
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
	
	// 1. Distance from player
	vec2 player_diff = uv - center;
	player_diff.x *= aspect_ratio;
	float player_dist = length(player_diff);
	
	// 2. Solid Filled Disk Echo Calculation
	float max_disk = 0.0;
	
	for (int i = 0; i < MAX_ECHOES; i++) {
		if (echo_strengths[i] > 0.001 && echo_radii[i] > 0.0001) {
			vec2 echo_diff = uv - echo_positions[i];
			echo_diff.x *= aspect_ratio;
			float dist = length(echo_diff);

			// Solid filled disk formula with soft edge
			float r = echo_radii[i];
			float disk = 1.0 - smoothstep(r - 0.01, r + 0.005, dist);
			
			max_disk = max(max_disk, disk * echo_strengths[i]);
		}
	}

	float mask = texture(mask_texture, UV).r;
	
	// Base black screen alpha
	float threshold = mix(-0.2, 1.2, progress);
	float val = player_dist * 1.2 - mask * 0.4;
	float alpha = smoothstep(threshold - edge_sharpness, threshold + edge_sharpness, val);
	
	// Forcefully subtract disk area from darkness so echoes reveal the world beneath
	alpha = clamp(alpha - max_disk, 0.0, 1.0);
	
	COLOR = vec4(wipe_color.rgb, alpha * wipe_color.a);
}