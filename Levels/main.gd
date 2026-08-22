extends Node2D

const PORT = 8910 # Avoid port 7000 system conflicts
const MAX_CLIENTS = 2

@export var player_scene: PackedScene = preload("res://Actors/player.tscn")
@onready var players_container: Node2D = $Players
@onready var camera: Camera2D = $Camera2D
@onready var spawn_points: Node2D = $SpawnPoints # Container holding Marker2D nodes
@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner # Path to your MultiplayerSpawner

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	
	# Handle client connection events
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)

	# Assign custom spawn method so positions replicate during instantiation
	if spawner:
		spawner.spawn_function = _custom_spawn_player

func _unhandled_input(event: InputEvent) -> void:
	# Use single key press events to avoid firing 60+ times per second
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_0:
			host_game()
		elif event.keycode == KEY_1:
			join_game()

# Call this method to start a session as Host
func host_game() -> void:
	_reset_multiplayer_peer()

	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CLIENTS)
	if error != OK:
		print("Failed to host game on port ", PORT, ": Error code ", error)
		_reset_multiplayer_peer()
		return
	
	multiplayer.multiplayer_peer = peer
	print("Host server started. Spawning host player...")
	spawn_player(1)

# Call this method to connect to Host
func join_game(ip_address: String = "127.0.0.1") -> void:
	_reset_multiplayer_peer()

	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip_address, PORT)
	if error != OK:
		print("Failed to initiate connection: ", error)
		_reset_multiplayer_peer()
		return

	multiplayer.multiplayer_peer = peer
	print("Connecting to host at ", ip_address, "...")

## Clears active networking peers cleanly without calling .close() on invalid peers
func _reset_multiplayer_peer() -> void:
	if multiplayer.multiplayer_peer and not (multiplayer.multiplayer_peer is OfflineMultiplayerPeer):
		# Simply assigning OfflineMultiplayerPeer replaces and frees the active ENet instance safely
		multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()

func _on_connected_to_server() -> void:
	print("Successfully connected to host server!")

func _on_connection_failed() -> void:
	print("Failed to establish connection with host server.")
	_reset_multiplayer_peer()

func _on_player_connected(id: int) -> void:
	print("Peer connected with ID: ", id)
	# ONLY the host server instantiates and manages player nodes for new connections
	if multiplayer.is_server():
		spawn_player(id)

func _on_player_disconnected(id: int) -> void:
	print("Peer disconnected: ", id)
	var p = players_container.get_node_or_null("Player_" + str(id))
	if p:
		p.queue_free()

func spawn_player(id: int) -> void:
	if players_container.has_node("Player_" + str(id)):
		return

	# Determine spawn marker index based on current player count
	var spawn_index := players_container.get_child_count()
	var spawn_pos := Vector2.ZERO
	
	if spawn_points and spawn_points.get_child_count() > 0:
		spawn_index = spawn_index % spawn_points.get_child_count()
		spawn_pos = spawn_points.get_child(spawn_index).global_position
	else:
		# Fallback: offset every new player horizontally
		spawn_pos = Vector2(850.0 + (spawn_index * 150.0), -450.0)

	# Pass dictionary payload into spawner.spawn()
	spawner.spawn({
		"id": id,
		"position": spawn_pos
	})

## Custom spawn callback executed automatically on Host and Clients
func _custom_spawn_player(data: Dictionary) -> Node:
	var player_instance = player_scene.instantiate()
	player_instance.name = "Player_" + str(data["id"])
	player_instance.global_position = data["position"]
	return player_instance
