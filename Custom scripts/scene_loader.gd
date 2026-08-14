extends Node

signal progress_changed(progress: float)
signal load_finished

var loading_screen_scene: PackedScene = preload("res://Levels/loading_screen.tscn")
var loaded_resource: PackedScene
var scene_path: String
var progress: Array = []
var use_sub_threads: bool = true

func _ready() -> void:
	set_process(false)

func load_scene(target_path: String) -> void:
	scene_path = target_path
	
	# Instantiate and attach transition screen
	var new_load_screen = loading_screen_scene.instantiate()
	add_child(new_load_screen)
	
	progress_changed.connect(new_load_screen.on_progress_changed)
	load_finished.connect(new_load_screen.on_load_finished)
	
	# Wait until wipe shader completely covers screen
	await new_load_screen.loading_screen_ready
	start_load()

func start_load() -> void:
	var state = ResourceLoader.load_threaded_request(scene_path, "", use_sub_threads)
	if state == OK:
		set_process(true)

func _process(_delta: float) -> void:
	var status = ResourceLoader.load_threaded_get_status(scene_path, progress)
	
	if progress.size() > 0:
		progress_changed.emit(progress[0])
		
	match status:
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE, ResourceLoader.THREAD_LOAD_FAILED:
			set_process(false)
			push_error("Failed to load scene at path: " + scene_path)
			
		ResourceLoader.THREAD_LOAD_LOADED:
			set_process(false)
			loaded_resource = ResourceLoader.load_threaded_get(scene_path)
			get_tree().change_scene_to_packed(loaded_resource)
			load_finished.emit()
