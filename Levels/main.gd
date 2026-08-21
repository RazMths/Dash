extends Node2D

const PORT = 7000
const MAX_CLIENTS = 2

@export var player_scene: PackedScene = preload("res://Actors/player.tscn")
@onready var players_container: Node2D = $Players
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)

func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_0):
		host_game()
	if Input.is_key_pressed(KEY_1):
		join_game("127.0.0.1")

# Call this method to start a session as Host
func host_game() -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CLIENTS)
	if error != OK:
		print("Failed to host game: ", error)
		return
	
	multiplayer.multiplayer_peer = peer
	spawn_player(1)

# Call this method to connect to Host
func join_game(ip_address: String = "127.0.0.1") -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip_address, PORT)
	if error != OK:
		print("Failed to connect: ", error)
		return
	
	multiplayer.multiplayer_peer = peer

func _on_player_connected(id: int) -> void:
	if multiplayer.is_server():
		spawn_player(id)

func _on_player_disconnected(id: int) -> void:
	var p = players_container.get_node_or_null("Player_" + str(id))
	if p:
		p.queue_free()

func spawn_player(id: int) -> void:
	var player_instance = player_scene.instantiate()
	player_instance.name = "Player_" + str(id)
	player_instance.set_multiplayer_authority(id)
	
	# Set distinct spawn offset for the second player
	if id != 1:
		player_instance.global_position = Vector2(1000.0, -450.0)
	else:
		player_instance.global_position = Vector2(850.0, -450.0)
		
	players_container.add_child(player_instance, true)
