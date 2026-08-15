extends ColorRect

class EchoData:
	var world_pos: Vector2
	var progress: float = 0.0
	var expand_speed: float = 0.6       # Lifespan speed
	var max_radius: float = 0.56        # Expansion peak radius
	var strength: float = 1.0

@export var player: Node2D
var active_echoes: Array[EchoData] = []

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

func spawn_echo(world_position: Vector2) -> void:
	if active_echoes.size() >= 5:
		active_echoes.pop_front()
	
	var echo := EchoData.new()
	echo.world_pos = world_position
	active_echoes.append(echo)

func _process(delta: float) -> void:
	var mat := material as ShaderMaterial
	if not mat or not player:
		return

	var vp_size := get_viewport_rect().size
	if vp_size.y == 0:
		return
		
	var aspect := vp_size.x / vp_size.y

	# 1. Update Player position in UV space
	var player_screen_pos = player.get_global_transform_with_canvas().origin
	var player_uv = player_screen_pos / vp_size
	mat.set_shader_parameter("center", player_uv)

	# 2. Update Echoes
	var positions: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
	var radii: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]
	var strengths: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]

	var canvas_xform = player.get_canvas_transform()

	var i = active_echoes.size() - 1
	while i >= 0:
		var echo = active_echoes[i]
		echo.progress += delta * echo.expand_speed
		
		if echo.progress >= 1.0:
			active_echoes.remove_at(i)
		else:
			var screen_pos = canvas_xform * echo.world_pos
			var screen_uv = screen_pos / vp_size
			
			var current_radius: float
			var current_strength: float
			
			# Smooth expand from 0.0 to max_radius, then smoothly shrink back down
			if echo.progress < 0.4:
				var t = echo.progress / 0.4
				current_radius = lerp(0.0, echo.max_radius, ease(t, -2.0)) # Smooth acceleration
				current_strength = 1.0
			else:
				var t = (echo.progress - 0.4) / 0.6
				current_radius = lerp(echo.max_radius, 0.0, ease(t, 2.0))
				current_strength = 1.0 - t
			
			positions[i] = screen_uv
			radii[i] = current_radius
			strengths[i] = current_strength
		i -= 1

	# 3. Push uniforms
	mat.set_shader_parameter("aspect_ratio", aspect)
	mat.set_shader_parameter("echo_positions", positions)
	mat.set_shader_parameter("echo_radii", radii)
	mat.set_shader_parameter("echo_strengths", strengths)
