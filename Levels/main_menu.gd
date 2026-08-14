extends Control

# Export variables for scene paths as requested
@export_file("*.tscn") var start_scene: String
@export_file("*.tscn") var options_scene: String

@onready var start_button: Button = $CanvasLayer/Control/VBoxContainer/StartButton
@onready var options_button: Button = $CanvasLayer/Control/VBoxContainer/OptionsButton
@onready var quit_button: Button = $CanvasLayer/Control/VBoxContainer/QuitButton

# Hover animation settings
@export var hover_scale: Vector2 = Vector2(1.1, 1.1)
@export var normal_scale: Vector2 = Vector2(1.0, 1.0)
@export var tween_duration: float = 0.15

# Dictionary to store active tweens for each button
var button_tweens: Dictionary = {}

func _ready() -> void:
	# Connect and setup each button
	setup_button_hover(start_button)
	setup_button_hover(options_button)
	setup_button_hover(quit_button)
	
	start_button.pressed.connect(_on_start_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func setup_button_hover(button: Button) -> void:
	# Adjust pivot offset to center so scaling happens from the center
	button.pivot_offset = button.size / 2.0
	
	# Connect hover signals
	button.mouse_entered.connect(func(): animate_button_scale(button, hover_scale))
	button.mouse_exited.connect(func(): animate_button_scale(button, normal_scale))
	button.focus_entered.connect(func(): animate_button_scale(button, hover_scale)) # For keyboard/gamepad
	button.focus_exited.connect(func(): animate_button_scale(button, normal_scale))

func animate_button_scale(button: Button, target_scale: Vector2) -> void:
	# Kill existing tween on this button if running to prevent conflicting overlays
	if button_tweens.has(button) and button_tweens[button] != null:
		button_tweens[button].kill()
	
	var tween: Tween = create_tween()
	button_tweens[button] = tween
	
	# Chain smooth transition & easing
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", target_scale, tween_duration)

# Button Actions
func _on_start_pressed() -> void:
	if start_scene != "":
		get_tree().change_scene_to_file(start_scene)
	else:
		print("Start Scene path not assigned in Inspector!")

func _on_options_pressed() -> void:
	if options_scene != "":
		get_tree().change_scene_to_file(options_scene)
	else:
		print("Options Scene path not assigned in Inspector!")

func _on_quit_pressed() -> void:
	get_tree().quit()
