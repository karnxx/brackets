extends Node

const PORT := 7777
const MAX_PLAYERS := 2
const PLAYER_SCENE = preload("res://scsnes/player.tscn")

var spawned_players: Array[int] = []


func _ready():
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

	var host_id = multiplayer.get_unique_id()

	_register_and_spawn(host_id)


func join_game(ip: String):
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, PORT)

	if error != OK:
		print("Failed to join: ", error)
		return

	multiplayer.multiplayer_peer = peer

	print("Joining ", ip)

	await multiplayer.connected_to_server

	print("Connected to server!")

	get_tree().change_scene_to_file("res://scsnes/house.tscn")
	await get_tree().scene_changed

	# Wait one extra frame so House is completely ready.
	await get_tree().process_frame

	print("Join scene ready!")

	request_spawn.rpc_id(1)


@rpc("any_peer", "call_remote", "reliable")
func request_spawn():
	if not multiplayer.is_server():
		return

	var new_player_id = multiplayer.get_remote_sender_id()

	print("Spawn requested by: ", new_player_id)

	# Give the joining player every player that already exists.
	for existing_id in spawned_players:
		spawn_player.rpc_id(new_player_id, existing_id)

	# Then add the joining player for everyone.
	_register_and_spawn(new_player_id)


func _register_and_spawn(id: int):
	if id in spawned_players:
		return

	spawned_players.append(id)

	spawn_player.rpc(id)


@rpc("authority", "call_local", "reliable")
func spawn_player(id: int):
	if get_tree().current_scene == null:
		return

	if get_tree().current_scene.has_node(str(id)):
		return

	var player = PLAYER_SCENE.instantiate()

	player.name = str(id)
	player.set_multiplayer_authority(id)

	get_tree().current_scene.add_child(player)

	print(
		"Spawned player: ",
		id,
		" | Local ID: ",
		multiplayer.get_unique_id()
	)


func _on_peer_disconnected(id: int):
	spawned_players.erase(id)

	if get_tree().current_scene == null:
		return

	var player = get_tree().current_scene.get_node_or_null(str(id))

	if player:
		player.queue_free()
