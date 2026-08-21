extends CharacterBody2D

@export_group("Movement")
@export var move_speed: float = 220.0
@export var acceleration: float = 1600.0
@export var friction: float = 1400.0
@export var air_acceleration: float = 1200.0
@export var air_friction: float = 600.0

@export_group("Jumping")
@export var jump_velocity: float = -380.0
@export var min_jump_velocity: float = -120.0
@export var gravity: float = 980.0
@export var fall_gravity_multiplier: float = 1.6
@export var apex_gravity_multiplier: float = 0.5
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12

@export_group("Wall Mechanics (Celeste-Style)")
@export var wall_slide_speed: float = 70.0
@export var wall_climb_speed: float = 120.0
@export var wall_jump_velocity: Vector2 = Vector2(280.0, -360.0)

@export_group("Dash")
@export var dash_speed: float = 550.0
@export var dash_duration: float = 0.14
@export var ghost_spawn_interval: float = 0.03

@export_group("Hazards")
@export var fall_limit_y: float = 800.0

# Node References
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var walk_particles: GPUParticles2D = $WalkParticles
@onready var jump_particles: GPUParticles2D = $JumpParticles
@onready var wall_particles: GPUParticles2D = $WallParticles

@export var overlay_manager: ColorRect
@export var echo_manager: Node2D

@onready var default_sprite_scale: Vector2 = animated_sprite.scale

# Timers & State
var coyote_counter: float = 0.0
var buffer_counter: float = 0.0
var dash_counter: float = 0.0
var ghost_timer: float = 0.0

var is_dashing: bool = false
var can_dash: bool = true
var dash_vector: Vector2 = Vector2.ZERO
var is_wall_sliding: bool = false

# Signals
signal player_dashed
signal player_landed(impact_velocity: float)

var facing_direction: float = 1.0
var last_velocity_y: float = 0.0

func _physics_process(delta: float) -> void:
	# If player fall the scene will reset
	if global_position.y > fall_limit_y:
		reset_scene()
	
	# 1. Dash State
	if is_dashing:
		dash_counter -= delta
		ghost_timer -= delta
		velocity = dash_vector * dash_speed
		
		walk_particles.emitting = false
		wall_particles.emitting = false
		
		if ghost_timer <= 0.0:
			spawn_dash_ghost()
			ghost_timer = ghost_spawn_interval

		animated_sprite.play("jump")
		
		if dash_counter <= 0.0:
			is_dashing = false
			velocity = dash_vector * (move_speed * 0.8)
			if overlay_manager:
				pass # overlay_manager.spawn_echo(global_position)
		
		move_and_slide()
		return

	if is_on_floor():
		can_dash = true

	# 2. Wall Detection & Sliding / Climbing
	var wall_normal = get_wall_normal()
	var input_dir_x = Input.get_axis("move_left", "move_right")
	var is_against_wall = is_on_wall() and not is_on_floor()

	# Determine if sliding down or holding onto a wall
	is_wall_sliding = is_against_wall and (velocity.y > 0 or Input.is_action_pressed("move_up") or Input.is_action_pressed("move_down"))

	if is_wall_sliding:
		# Reposition wall particles to touch the wall
		wall_particles.position.x = sign(-wall_normal.x) * 8.0
		wall_particles.emitting = true

		if Input.is_action_pressed("move_up"):
			velocity.y = -wall_climb_speed
		elif Input.is_action_pressed("move_down"):
			velocity.y = wall_climb_speed
		else:
			# Slow wall slide gravity drag
			velocity.y = min(velocity.y + gravity * 0.2 * delta, wall_slide_speed)
	else:
		if wall_particles:
			wall_particles.emitting = false

		# Normal Dynamic Air / Floor Gravity
		if is_on_floor():
			coyote_counter = coyote_time
		else:
			coyote_counter -= delta
			var current_gravity = gravity
			if abs(velocity.y) < 50.0:
				current_gravity *= apex_gravity_multiplier
			elif velocity.y > 0:
				current_gravity *= fall_gravity_multiplier
			velocity.y += current_gravity * delta

	# 3. Jump Input Buffering
	if Input.is_action_just_pressed("jump"):
		buffer_counter = jump_buffer_time
	else:
		buffer_counter -= delta

	# 4. Jump Execution (Floor vs Wall Jump)
	if buffer_counter > 0.0:
		if coyote_counter > 0.0:
			execute_jump()
		elif is_against_wall:
			execute_wall_jump(wall_normal)

	if Input.is_action_just_released("jump") and velocity.y < min_jump_velocity:
		velocity.y = min_jump_velocity

	# 5. Horizontal Physics
	var accel = acceleration if is_on_floor() else air_acceleration
	var deccel = friction if is_on_floor() else air_friction

	if input_dir_x != 0:
		velocity.x = move_toward(velocity.x, input_dir_x * move_speed, accel * delta)
		facing_direction = sign(input_dir_x)
	else:
		velocity.x = move_toward(velocity.x, 0, deccel * delta)

	# 6. Dash Triggering
	if Input.is_action_just_pressed("dash") and can_dash:
		start_dash()

	if not is_on_floor():
		last_velocity_y = velocity.y

	move_and_slide()

	# 7. Landing Detection
	if is_on_floor() and last_velocity_y > 0:
		apply_landing_squash(last_velocity_y)
		trigger_burst_particles()
		player_landed.emit(last_velocity_y)
		last_velocity_y = 0.0

	# 8. Update Animations
	update_animations(input_dir_x)

func reset_scene() -> void:
	# Disable player processing to prevent multiple triggers
	set_physics_process(false)
	
	var tween = create_tween()
	# Assuming overlay_manager is a ColorRect covering the screen
	if overlay_manager:
		tween.tween_property(overlay_manager, "color:a", 1.0, 0.25)
		tween.tween_callback(get_tree().reload_current_scene)
	else:
		get_tree().reload_current_scene()

func update_animations(input_dir_x: float) -> void:
	if facing_direction != 0:
		animated_sprite.flip_h = (facing_direction < 0)

	if is_wall_sliding:
		animated_sprite.play("jump")
	elif not is_on_floor():
		walk_particles.emitting = false
		if velocity.y < 0:
			animated_sprite.play("jump")
		else:
			animated_sprite.play("fall")
	else:
		if abs(velocity.x) > 10.0:
			animated_sprite.play("walk")
			walk_particles.emitting = true
		else:
			animated_sprite.play("idle")
			walk_particles.emitting = false

func execute_jump() -> void:
	velocity.y = jump_velocity
	coyote_counter = 0.0
	buffer_counter = 0.0
	apply_jump_stretch()
	trigger_burst_particles()
	if overlay_manager:
		overlay_manager.spawn_echo(global_position)

func execute_wall_jump(wall_normal: Vector2) -> void:
	# Push away from wall normal direction
	velocity.x = wall_normal.x * wall_jump_velocity.x
	velocity.y = wall_jump_velocity.y
	facing_direction = sign(wall_normal.x)
	
	buffer_counter = 0.0
	apply_jump_stretch()
	trigger_burst_particles()

	if overlay_manager:
		overlay_manager.spawn_echo(global_position)

func trigger_burst_particles() -> void:
	if jump_particles:
		jump_particles.restart()
		jump_particles.emitting = true

func start_dash() -> void:
	can_dash = false
	is_dashing = true
	dash_counter = dash_duration
	ghost_timer = 0.0
	
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
	if input_dir == Vector2.ZERO:
		input_dir = Vector2.RIGHT if facing_direction >= 0 else Vector2.LEFT

	dash_vector = input_dir
	player_dashed.emit()

func apply_jump_stretch() -> void:
	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	animated_sprite.scale = default_sprite_scale * Vector2(0.7, 1.35)
	tween.tween_property(animated_sprite, "scale", default_sprite_scale, 0.15)

func apply_landing_squash(fall_speed: float) -> void:
	var intensity = clamp(fall_speed / 600.0, 0.15, 0.35)
	var squash_x = 1.0 + intensity
	var squash_y = 1.0 - intensity
	
	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	animated_sprite.scale = default_sprite_scale * Vector2(squash_x, squash_y)
	tween.tween_property(animated_sprite, "scale", default_sprite_scale, 0.18)

func spawn_dash_ghost() -> void:
	var ghost := Sprite2D.new()
	var current_texture = animated_sprite.sprite_frames.get_frame_texture(animated_sprite.animation, animated_sprite.frame)
	ghost.texture = current_texture
	ghost.global_position = animated_sprite.global_position
	ghost.flip_h = animated_sprite.flip_h
	ghost.scale = animated_sprite.scale
	ghost.modulate = Color(0.3, 0.7, 1.0, 0.6)
	
	get_parent().add_child(ghost)
	
	var tween = ghost.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ghost, "modulate:a", 0.0, 0.25)
	tween.tween_callback(ghost.queue_free) 
