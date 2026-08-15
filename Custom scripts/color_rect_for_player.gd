extends ColorRect

@export var player: Node2D

func _ready() -> void:
	# 1. Start an infinite looping tween animating the progress parameter between 0.3 and 0.4
	var tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Animate forward from 0.3 to 0.4 over 1.5 seconds
	tween.tween_property(material, "shader_parameter/progress", 0.24, 1.5).from(0.2)
	# Animate back from 0.4 to 0.3 over 1.5 seconds
	tween.tween_property(material, "shader_parameter/progress", 0.2, 1.5).from(0.24)

func _process(_delta: float) -> void:
	if not player:
		return
	
	# Keep player centered in screen coordinates
	var screen_pixel_pos = player.get_global_transform_with_canvas().origin
	var viewport_rect = get_viewport_rect()
	
	var center_uv = Vector2(
		screen_pixel_pos.x / viewport_rect.size.x,
		screen_pixel_pos.y / viewport_rect.size.y
	)
	var aspect_ratio = viewport_rect.size.x / viewport_rect.size.y
	
	var mat = material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("center", center_uv)
		mat.set_shader_parameter("aspect_ratio", aspect_ratio)
