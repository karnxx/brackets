extends Node

const PORT := 7777
const MAX_PLAYERS := 2

const PLAYER_SCENE = preload("res://scsnes/player.tscn")


func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)


func host_game():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_PLAYERS)

	if error != OK:
		print("Failed to host: ", error)
		return

	multiplayer.multiplayer_peer = peer

	print("Hosting!")

	get_tree().change_scene_to_file("res://scsnes/house.tscn")

	await get_tree().scene_changed

	spawn_player.rpc(multiplayer.get_unique_id())

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
		# Spawn the new player for everyone
		spawn_player.rpc(id)


@rpc("authority", "call_local", "reliable")
func spawn_player(id: int):
	var player = PLAYER_SCENE.instantiate()

	player.name = str(id)
	player.set_multiplayer_authority(id)

	get_tree().current_scene.add_child(player)

	print("Spawned player: ", id)
