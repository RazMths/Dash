extends CharacterBody2D

@export_group("Movement")
@export var move_speed: float = 200.0
@export var acceleration: float = 1200.0
@export var friction: float = 1000.0

@export_group("Jumping")
@export var jump_velocity: float = -350.0
@export var min_jump_velocity: float = -120.0
@export var gravity: float = 980.0
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.1

@export_group("Dash")
@export var dash_speed: float = 500.0
@export var dash_duration: float = 0.15

# Timer counters handled completely in code
var coyote_counter: float = 0.0
var buffer_counter: float = 0.0
var dash_counter: float = 0.0

var is_dashing: bool = false
var can_dash: bool = true
var dash_vector: Vector2 = Vector2.ZERO

# camera thing
signal player_dashed
signal player_landed(impact_velocity: float)

var facing_direction: float = 1.0
var last_velocity_y: float = 0.0

# for echo things
@export var overlay_manager: ColorRect
@export var echo_manager: Node2D

func _physics_process(delta: float) -> void:
	# 1. Handle Dashing State
	if is_dashing:
		dash_counter -= delta
		velocity = dash_vector * dash_speed
		
		# --- FIX 1: Spawn Echo at END of dash ---
		if dash_counter <= 0.0:
			is_dashing = false
			if overlay_manager:
				overlay_manager.spawn_echo(global_position)
		
		move_and_slide()
		return

	# Reset dash availability on floor
	if is_on_floor():
		can_dash = true

	# 2. Gravity & Coyote Time Counter
	if is_on_floor():
		coyote_counter = coyote_time  # Reset full window when on floor
	else:
		velocity.y += gravity * delta
		coyote_counter -= delta       # Tick down when in air

	# 3. Jump Buffer Counter
	if Input.is_action_just_pressed("jump"):
		buffer_counter = jump_buffer_time
	else:
		buffer_counter -= delta

	# Execute Jump if Coyote and Buffer windows are both active (> 0)
	if coyote_counter > 0.0 and buffer_counter > 0.0:
		execute_jump()

	# Variable Jump Height (Release early = short jump)
	if Input.is_action_just_released("jump") and velocity.y < min_jump_velocity:
		velocity.y = min_jump_velocity

	# 4. Horizontal Movement
	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * move_speed, acceleration * delta)
		facing_direction = sign(direction) # for the camera logic
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

	# 5. Dash Triggering
	if Input.is_action_just_pressed("dash") and can_dash:
		start_dash()

	# --- FIX 2: Save fall speed BEFORE move_and_slide resets it ---
	if not is_on_floor():
		last_velocity_y = velocity.y

	move_and_slide()

	# Detect the frame the player hits the ground
	if is_on_floor() and last_velocity_y > 0:
		player_landed.emit(last_velocity_y)
		last_velocity_y = 0.0

func execute_jump() -> void:
	velocity.y = jump_velocity
	coyote_counter = 0.0
	buffer_counter = 0.0

	# Echo on jump
	if overlay_manager:
		overlay_manager.spawn_echo(global_position)

func start_dash() -> void:
	can_dash = false
	is_dashing = true
	dash_counter = dash_duration
	
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
	if input_dir == Vector2.ZERO:
		input_dir = Vector2.RIGHT if facing_direction >= 0 else Vector2.LEFT

	dash_vector = input_dir
	player_dashed.emit()
