extends Node

const PORT := 7777
const MAX_PLAYERS := 2
const PLAYER_SCENE = preload("res://scsnes/player.tscn")

var spawned_players: Array[int] = []
var player_data: Dictionary = {}

var roles =  {
	"INTRUDER":0, "RESIDENT":0, "MEDIC":0
}

var names = [
	"Alpha",
	"Charlie",
	"Bravo",
	"Sigma",
	"Krishiv",
	"Delta",
	"Echo",
	"Foxtrot",
	"Golf"
]

var intweight = 0.25
var resweight = 0.50
var medweight = 0.25

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
	await get_tree().process_frame
	print("Join scene ready!")
	request_spawn.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func request_spawn():
	if not multiplayer.is_server():
		return
	var new_player_id = multiplayer.get_remote_sender_id()
	print("Spawn requested by: ", new_player_id)
	for existing_id in spawned_players:
		var data = player_data[existing_id]
		spawn_player.rpc_id(
			new_player_id,
			existing_id,
			data["role"],
			data["name"]
		)
	_register_and_spawn(new_player_id)

func _register_and_spawn(id: int):
	if id in spawned_players:
		return
	spawned_players.append(id)
	var player_role = roleassigng()
	var player_name = nameassign()
	player_data[id] = {
		"role": player_role,
		"name": player_name
	}
	spawn_player.rpc(id, player_role, player_name)

@rpc("authority", "call_local", "reliable")
func spawn_player(id: int, assigned_role: String, assigned_name: String):
	if get_tree().current_scene == null:
		return
	if get_tree().current_scene.has_node(str(id)):
		return
	var player = PLAYER_SCENE.instantiate()
	player.name = str(id)
	player.set_multiplayer_authority(id)
	player.role = assigned_role
	player.namnam = assigned_name
	get_tree().current_scene.add_child(player)
	print(
		"Spawned player: ", id,
		" | Role: ", player.role,
		" | Name: ", player.namnam,
		" | Local ID: ", multiplayer.get_unique_id()
	)

func _on_peer_disconnected(id: int):
	spawned_players.erase(id)
	if get_tree().current_scene == null:
		return
	var player = get_tree().current_scene.get_node_or_null(str(id))
	if player:
		player.queue_free()

func roleassigng():
	var randa = randf()
	if randa <= medweight or randa <= intweight:
		var randa2 = randf()
		if randa2 <= 0.5 and roles["MEDIC"] == 0:
			return "medic"
			roles["MEDIC"] = 1
		elif roles["INTRUDER"] == 0:
			return "intruder"
			roles["INTRUDER"] = 1
		else:
			return "resident"
	else:
		return "resident"

func nameassign():
	return names.pick_random()
