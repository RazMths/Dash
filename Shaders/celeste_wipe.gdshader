shader_type canvas_item;

// Progress from 0.0 (fully open/clear) to 1.0 (fully covered/black)
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 wipe_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float diamond_size = 30.0;

void fragment() {
	// Calculate aspect ratio so diamonds stay square
	vec2 st = FRAGCOORD.xy;
	
	// Create repeating grid for diamond shapes
	vec2 position = mod(st, vec2(diamond_size)) - vec2(diamond_size * 0.5);
	
	// Diamond distance equation: |x| + |y|
	float dist = (abs(position.x) + abs(position.y)) / (diamond_size * 0.5);
	
	// Compare against the progress threshold
	if (dist < progress * 1.5) {
		COLOR = wipe_color;
	} else {
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	}
}