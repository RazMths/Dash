extends CanvasLayer

signal loading_screen_ready

@onready var color_rect: ColorRect = $ColorRect

@export var duration: float = 0.6

var material: ShaderMaterial

func _ready() -> void:
	material = color_rect.material as ShaderMaterial
	material.set_shader_parameter("progress", 0.0)
	
	# Sweep across: grid diamonds expand from left to right
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(material, "shader_parameter/progress", 1.0, duration)
	
	await tween.finished
	loading_screen_ready.emit()

func on_progress_changed(_progress_value: float) -> void:
	pass

func on_load_finished() -> void:
	# Reveal scene: grid diamonds shrink down left to right
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(material, "shader_parameter/progress", 0.0, duration)
	
	await tween.finished
	queue_free()
