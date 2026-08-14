extends Camera2D
class_name CelesteCamera

@export_group("Target Tracking")
## Drag and drop your Player node here in the Inspector
@export var target: Node2D
## How fast the camera moves toward the target
@export var follow_speed: float = 6.0
## How far ahead the camera looks in the facing direction
@export var look_ahead_distance: float = 48.0
## Speed at which the look-ahead shifts when turning around
@export var look_ahead_speed: float = 3.0

@export_group("Screen Shake")
## Fast shaking speed
@export var shake_frequency: float = 20.0

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

	# 2. Smooth Position Tracking (Frame-rate independent Exponential Decay)
	var desired_position = target.global_position + look_ahead_offset
	global_position = global_position.lerp(desired_position, 1.0 - exp(-follow_speed * delta))

	# 3. Screen Shake Logic
	_process_shake(delta)

func _process_shake(delta: float) -> void:
	if shake_intensity > 0.0:
		shake_time += delta * shake_frequency
		shake_intensity = move_toward(shake_intensity, 0.0, shake_decay_rate * delta)
		
		# Generate semi-random offset based on sine waves
		var x_offset = sin(shake_time * 1.1) * shake_intensity
		var y_offset = cos(shake_time * 1.3) * shake_intensity
		offset = Vector2(x_offset, y_offset)
	else:
		offset = Vector2.ZERO
		shake_time = 0.0

## Call this method from any script to trigger camera shake
func add_shake(amount: float, decay: float = 15.0) -> void:
	shake_intensity = amount
	shake_decay_rate = decay

## Call this to set or change room limits dynamically
func apply_room_limits(rect: Rect2i) -> void:
	limit_left = rect.position.x
	limit_top = rect.position.y
	limit_right = rect.position.x + rect.size.x
	limit_bottom = rect.position.y + rect.size.y
