extends Node
const PORT := 7777
const MAX_PLAYERS := 2
const PLAYER_SCENE = preload("res://scsnes/player.tscn")

var spawned_players: Array[int] = []

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)


func host_game():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_PLAYERS)
	if error != OK:
		print("Failed to host: ", error)
		return
	multiplayer.multiplayer_peer = peer
	spawned_players.clear()
	print("Hosting!")
	get_tree().change_scene_to_file("res://scsnes/house.tscn")
	await get_tree().scene_changed
	_register_and_spawn(multiplayer.get_unique_id())

func join_game(ip: String):
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, PORT)
	if error != OK:
		print("Failed to join: ", error)
		return
	multiplayer.multiplayer_peer = peer
	print("Joining ", ip)
	get_tree().change_scene_to_file("res://scsnes/house.tscn")

func _on_peer_connected(id: int):
	print("Player connected: ", id)
	if multiplayer.is_server():
		# Catch the new peer up on everyone who already exists
		for existing_id in spawned_players:
			spawn_player.rpc_id(id, existing_id)
		# Then spawn the new player for everyone (including itself)
		_register_and_spawn(id)
		
func _on_peer_disconnected(id: int):
	spawned_players.erase(id)
	var node = get_tree().current_scene.get_node_or_null(str(id))
	if node:
		node.queue_free()

func _register_and_spawn(id: int):
	spawned_players.append(id)
	spawn_player.rpc(id)

@rpc("authority", "call_local", "reliable")
func spawn_player(id: int):
	if get_tree().current_scene.has_node(str(id)):
		return # avoid double-spawn if rpc arrives twice
	var player = PLAYER_SCENE.instantiate()
	player.name = str(id)
	player.set_multiplayer_authority(id)
	get_tree().current_scene.add_child(player)
	print("Spawned player: ", id)
