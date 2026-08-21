extends Camera2D
class_name CelesteCamera

@export_group("Target Tracking")
## Drag and drop your Player node here in the Inspector (or let multiplayer auto-assign it)
@export var target: Node2D:
	set(new_target):
		# Disconnect signals from previous target if replaced
		if target and target.is_connected("player_dashed", _on_player_dashed):
			target.disconnect("player_dashed", _on_player_dashed)
		if target and target.is_connected("player_landed", _on_player_landed):
			target.disconnect("player_landed", _on_player_landed)
		
		target = new_target
		
		# Connect signals to new target
		if target:
			if target.has_signal("player_dashed") and not target.player_dashed.is_connected(_on_player_dashed):
				target.player_dashed.connect(_on_player_dashed)
			if target.has_signal("player_landed") and not target.player_landed.is_connected(_on_player_landed):
				target.player_landed.connect(_on_player_landed)

## How fast the camera moves toward the target
@export var follow_speed: float = 6.0
## How far ahead the camera looks in the facing direction
@export var look_ahead_distance: float = 48.0
## Speed at which the look-ahead shifts when turning around
@export var look_ahead_speed: float = 3.0

@export_group("Screen Shake")
## Fast shaking speed
@export var shake_frequency: float = 20.0
@export var player_dash_intensity: float = 4.0

@export_group("Room Limits (Optional)")
## Leave as (0,0,0,0) if you don't want room clamping
@export var limit_rect: Rect2i = Rect2i(0, 0, 0, 0)

var look_ahead_offset: Vector2 = Vector2.ZERO
var shake_intensity: float = 0.0
var shake_decay_rate: float = 15.0
var shake_time: float = 0.0

func _ready() -> void:
	if limit_rect.size != Vector2i.ZERO:
		apply_room_limits(limit_rect)

func _process(delta: float) -> void:
	# 0. Multiplayer Auto-Targeting
	if not target:
		_find_local_player()
		if not target:
			return

	# 1. Look-Ahead Logic
	var facing_dir := 0.0
	if "facing_direction" in target:
		facing_dir = target.facing_direction
	elif target is CharacterBody2D and target.velocity.x != 0:
		facing_dir = sign(target.velocity.x)

	var target_look_ahead = Vector2(facing_dir * look_ahead_distance, 0.0)
	look_ahead_offset = look_ahead_offset.lerp(target_look_ahead, look_ahead_speed * delta)

	# 2. Smooth Position Tracking
	var desired_position = target.global_position + look_ahead_offset
	global_position = global_position.lerp(desired_position, 1.0 - exp(-follow_speed * delta))

	# 3. Screen Shake Logic
	_process_shake(delta)

## Finds the character that belongs to THIS local client instance
func _find_local_player() -> void:
	var players_container = get_node_or_null("../Players")
	if not players_container:
		return

	for child in players_container.get_children():
		if child is CharacterBody2D and child.is_multiplayer_authority():
			target = child
			break

func _process_shake(delta: float) -> void:
	if shake_intensity > 0.0:
		shake_time += delta * shake_frequency
		shake_intensity = move_toward(shake_intensity, 0.0, shake_decay_rate * delta)
		
		var x_offset = sin(shake_time * 1.1) * shake_intensity
		var y_offset = cos(shake_time * 1.3) * shake_intensity
		offset = Vector2(x_offset, y_offset)
	else:
		offset = Vector2.ZERO
		shake_time = 0.0

func add_shake(amount: float, decay: float = 15.0) -> void:
	shake_intensity = amount
	shake_decay_rate = decay

func apply_room_limits(rect: Rect2i) -> void:
	limit_left = rect.position.x
	limit_top = rect.position.y
	limit_right = rect.position.x + rect.size.x
	limit_bottom = rect.position.y + rect.size.y

func _on_player_dashed() -> void:
	add_shake(player_dash_intensity)

func _on_player_landed(impact_velocity: float) -> void:
	if impact_velocity > 300.0:
		var shake_amount = remap(impact_velocity, 300.0, 1000.0, 2.0, 10.0)
		add_shake(shake_amount)
