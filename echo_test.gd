extends Node2D

class EchoWave:
	var position: Vector2
	var radius: float = 0.0
	var max_radius: float = 160.0
	var speed: float = 360.0 # Pixels per second (matches speed = 6 at 60fps)
	var alpha: float = 1.0

var active_waves: Array[EchoWave] = []
var base_fade_duration: float = 1.33 # Seconds platforms stay visible

func spawn_echo(pos: Vector2, max_r: float = 160.0) -> void:
	var wave := EchoWave.new()
	wave.position = pos
	wave.max_radius = max_r
	active_waves.append(wave)

func _process(delta: float) -> void:
	var i = active_waves.size() - 1
	while i >= 0:
		var wave = active_waves[i]
		wave.radius += wave.speed * delta
		wave.alpha = 1.0 - (wave.radius / wave.max_radius)

		# Check collision against all platform nodes in group 'echo_platforms'
		for platform in get_tree().get_nodes_in_group("echo_platforms"):
			if platform.has_method("check_echo_hit"):
				platform.check_echo_hit(wave.position, wave.radius)

		if wave.radius >= wave.max_radius:
			active_waves.remove_at(i)
		i -= 1

	queue_redraw() # Trigger _draw() for visual wave rings

func _draw() -> void:
	for wave in active_waves:
		var color := Color(0.0, 0.94, 1.0, wave.alpha) # Cyan wave color
		draw_arc(wave.position, wave.radius, 0.0, TAU, 32, color, 2.0)
