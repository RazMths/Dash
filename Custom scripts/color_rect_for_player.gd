extends ColorRect

class EchoData:
	var world_pos: Vector2
	var progress: float = 0.0
	var expand_speed: float = 0.6       # Lifespan speed
	var max_radius: float = 0.35         # Expansion peak radius
	var strength: float = 1.0

@export var player: Node2D:
	set(new_player):
		# Disconnect signals from previous player if replaced
		if player and player.is_connected("player_dashed", _on_player_echo_event):
			player.disconnect("player_dashed", _on_player_echo_event)
		if player and player.is_connected("player_stepped", _on_player_echo_event):
			player.disconnect("player_stepped", _on_player_echo_event)

		player = new_player

		# Connect signals to new local player
		if player:
			if player.has_signal("player_dashed") and not player.player_dashed.is_connected(_on_player_echo_event):
				player.player_dashed.connect(_on_player_echo_event)
			if player.has_signal("player_stepped") and not player.player_stepped.is_connected(_on_player_echo_event):
				player.player_stepped.connect(_on_player_echo_event)

var active_echoes: Array[EchoData] = []

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

## Finds the player character assigned to THIS local peer instance
func _find_local_player() -> void:
	var local_id = multiplayer.get_unique_id()
	
	# Search in the "player" group or Players container
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		var players_container = get_tree().root.find_child("Players", true, false)
		if players_container:
			players = players_container.get_children()

	for node in players:
		if node is CharacterBody2D:
			# Match network authority explicitly to local peer ID
			if node.get_multiplayer_authority() == local_id:
				self.player = node
				return

func _process(delta: float) -> void:
	if not player:
		_find_local_player()
		if not player:
			return

	var mat := material as ShaderMaterial
	if not mat:
		return

	var vp := get_viewport()
	var vp_size := vp.get_visible_rect().size
	if vp_size.y == 0:
		return
		
	var aspect := vp_size.x / vp_size.y

	# 1. Update Player position in UV space using current Viewport Canvas
	var player_screen_pos = player.get_global_transform_with_canvas().origin
	var player_uv = player_screen_pos / vp_size
	mat.set_shader_parameter("center", player_uv)

	# 2. Update Echoes
	var positions: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
	var radii: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]
	var strengths: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]

	# Use active viewport canvas transform for world-to-screen conversion
	var canvas_xform = vp.get_canvas_transform()

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
			
			if echo.progress < 0.4:
				var t = echo.progress / 0.4
				current_radius = lerp(0.0, echo.max_radius, ease(t, -2.0))
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


func spawn_echo(world_position: Vector2, size_reducer: float = 1.0) -> void:
	if active_echoes.size() >= 5:
		active_echoes.pop_front()
	
	var echo := EchoData.new()
	echo.world_pos = world_position
	echo.max_radius *= size_reducer
	active_echoes.append(echo)


	# Method 2: Group fallback (if Player nodes are added to group "player")
	var candidates = get_tree().get_nodes_in_group("player")
	for node in candidates:
		if node is CharacterBody2D and node.is_multiplayer_authority():
			self.player = node
			return

## Signal handler for player actions
func _on_player_echo_event() -> void:
	if player:
		spawn_echo(player.global_position)
