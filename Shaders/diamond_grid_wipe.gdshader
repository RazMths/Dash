shader_type canvas_item;

// Progress from 0.0 (fully clear) to 1.0 (fully covered solid black)
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 wipe_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

// Size of the grid cells in pixels
uniform float grid_size = 32.0;

// Wave spread across the screen
uniform float smoothness = 0.3;

void fragment() {
	// 1. Get screen UV (0.0 to 1.0 left-to-right)
	vec2 uv = SCREEN_UV;
	
	// 2. Local coordinates inside each grid square (-0.5 to 0.5)
	vec2 cell_uv = fract(FRAGCOORD.xy / grid_size) - vec2(0.5);
	
	// 3. Diamond distance from cell center (0.0 at center, 1.0 at cell corners)
	float diamond_dist = abs(cell_uv.x) + abs(cell_uv.y);
	
	// 4. Calculate threshold ranging from 0.0 to 1.0 across the horizontal sweep
	// Range expands so left edge finishes growing to 1.0 while right edge catches up
	float threshold = (progress * (1.0 + smoothness)) - (uv.x * smoothness);
	
	// Clamp threshold to [0.0, 1.0] (0 = invisible, 1.0 = covers entire cell including corners)
	float max_dist = clamp(threshold, 0.0, 1.0);
	
	// 5. Render wipe color when inside the diamond radius
	if (diamond_dist <= max_dist) {
		COLOR = wipe_color;
	} else {
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	}
}