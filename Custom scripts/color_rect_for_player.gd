extends ColorRect

class EchoData:
	var world_pos: Vector2
	var progress: float = 0.0
	var expand_speed: float = 2.0      # Speed of expansion
	var max_radius: float = 0.35        # Size on screen (0.35 = 35% of screen height)
	var strength: float = 1.0

@export var player: Node2D
var active_echoes: Array[EchoData] = []

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

func _unhandled_input(event: InputEvent) -> void:
	# Trigger echo on spacebar / action for testing
	if event.is_action_pressed("ui_accept"):
		if player:
			spawn_echo(player.global_position)

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

	# 1. Player position to Screen UV
	var player_screen_pos = player.get_global_transform_with_canvas().origin
	var player_uv = player_screen_pos / vp_size
	mat.set_shader_parameter("center", player_uv)

	# 2. Convert active echoes to Screen UV
	var positions: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
	var radii: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]
	var strengths: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]

	# Canvas transform from viewport/camera context
	var canvas_xform = player.get_canvas_transform()

	var i = active_echoes.size() - 1
	while i >= 0:
		var echo = active_echoes[i]
		echo.progress += delta * echo.expand_speed
		
		if echo.progress >= 1.0:
			active_echoes.remove_at(i)
		else:
			# Convert world pos to canvas screen pos
			var screen_pos = canvas_xform * echo.world_pos
			var screen_uv = screen_pos / vp_size
			
			positions[i] = screen_uv
			radii[i] = echo.progress * echo.max_radius
			strengths[i] = (1.0 - echo.progress) * echo.strength
		i -= 1

	# 3. Push uniforms
	mat.set_shader_parameter("aspect_ratio", aspect)
	mat.set_shader_parameter("echo_positions", positions)
	mat.set_shader_parameter("echo_radii", radii)
	mat.set_shader_parameter("echo_strengths", strengths)
