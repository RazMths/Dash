shader_type canvas_item;

uniform sampler2D mask_texture : hint_default_white, filter_nearest;

// Controls the size of the hole around the player
uniform float progress : hint_range(0.0, 1.0) = 0.5;

// Sharpness of the ink blob edges (keep low ~0.01 for sharp comic ink)
uniform float edge_sharpness : hint_range(0.001, 0.2) = 0.01;

// Driven by script for player screen position
uniform vec2 center = vec2(0.5, 0.5);
uniform float aspect_ratio = 1.7777778;

// Color of the darkness/transition
uniform vec4 wipe_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec2 uv = UV;
	
	// Aspect-corrected radial distance from player center
	vec2 diff = uv - center;
	diff.x *= aspect_ratio;
	float dist = length(diff);
	
	// Sample the pattern texture
	float mask = texture(mask_texture, UV).r;
	
	// Combine distance and mask texture
	float val = dist * 1.2 - mask * 0.4;
	
	// Remap progress so 0.0 is fully open around player and 1.0 is total darkness
	float threshold = mix(-0.2, 1.2, progress);
	
	// Sharp step for clean comic/ink blob edges
	float alpha = smoothstep(threshold - edge_sharpness, threshold + edge_sharpness, val);
	
	COLOR = vec4(wipe_color.rgb, alpha * wipe_color.a);
}