extends Node

const PORT := 7777
const MAX_PLAYERS := 10
const PLAYER_SCENE = preload("res://scsnes/player.tscn")

var spawned_players: Array[int] = []
var player_data: Dictionary = {}
var is_hosting := false

signal hosting_started

var names = [
	"Alpha",
	"Charlie",
	"Bravo",
	"Sigma",
	"Krishiv",
	"Delta",
	"Echo",
	"Foxtrot",
	"Golf",
	"Hotel",
	"India",
	"Juliet",
	"Kilo",
	"Lima",
	"Mike",
	"November",
	"Oscar",
	"Papa",
	"Quebec",
	"Romeo",
	"Sierra",
	"Tango",
	"Uniform",
	"Victor",
	"Whiskey",
	"Xray",
	"Yankee",
	"Zulu",
	"Atlas",
	"Nova",
	"Orion",
	"Cosmo",
	"Blaze",
	"Frost",
	"Shadow",
	"Storm",
	"Ember",
	"Flint",
	"Raven",
	"Onyx",
	"Ghost",
	"Viper",
	"Cobra",
	"Falcon",
	"Hawk",
	"Wolf",
	"Lynx",
	"Bear",
	"Fox",
	"Otter",
	"Moose",
	"Byte",
	"Pixel",
	"Glitch",
	"Cache",
	"Kernel",
	"Syntax",
	"Cipher",
	"Vector",
	"Binary",
	"Logic",
	"Python",
	"Rust",
	"Ruby",
	"Swift",
	"Java",
	"Matrix",
	"Vertex",
	"Quantum",
	"Static",
	"Socket",
	"Packet",
	"Proxy",
	"Router",
	"Server",
	"Client",
	"Comet",
	"Meteor",
	"Astro",
	"Solar",
	"Lunar",
	"Cosmic",
	"Venus",
	"Mars",
	"Jupiter",
	"Saturn",
	"Neon",
	"Chrome",
	"Plasma",
	"Flux",
	"Pulse",
	"Drift",
	"Orbit",
	"Echo2",
	"Zero",
	"One",
	"Two",
	"Three",
	"Seven",
	"Eleven",
	"Thirteen",
	"FortyTwo",
	"Agent9",
	"Agent47",
	"AgentX",
	"Red",
	"Blue",
	"Green",
	"Yellow",
	"Purple",
	"Orange",
	"Crimson",
	"Silver",
	"Gold",
	"Ghostie",
	"ShadowX",
	"Night",
	"Dusk",
	"Dawn",
	"Midnight",
	"Sunset",
	"Thunder",
	"Lightning",
	"Rain",
	"Snow",
	"Cloud",
	"Mist",
	"Smoke",
	"Ash",
	"Coal",
	"Ice",
	"Blizzard",
	"Tornado",
	"Fang",
	"Claw",
	"Blade",
	"Arrow",
	"Trigger",
	"Scout",
	"Ranger",
	"Pilot",
	"Captain",
	"Major",
	"Colonel",
	"Commander",
	"Chief",
	"Doctor",
	"Medic",
	"Detective",
	"Inspector",
	"Officer",
	"Guard",
	"Watcher",
	"Keeper",
	"Striker",
	"Rogue",
	"Nomad",
	"Bandit",
	"Outlaw",
	"Mercury",
	"Venom",
	"Jester",
	"Phantom",
	"Wraith",
	"Specter",
	"Reaper",
	"Grim",
	"Hex",
	"Rune",
	"Void",
	"Ace",
	"Boss",
	"King",
	"Queen",
	"Prince",
	"Knight",
	"Wizard",
	"Hero",
	"Legend",
	"Rookie",
	"Pro",
	"Chip",
	"Bit",
	"ByteX",
	"404",
	"404NotFound",
	"Null",
	"Undefined",
	"Overflow",
	"Stack",
	"Pointer",
	"Memory",
	"Core",
	"Thread",
	"Process",
	"Daemon",
	"Root",
	"Admin",
	"Localhost",
	"Loopback",
	"Terminal",
	"Console",
	"Debugger",
	"Compiler",
	"Linker",
	"Builder",
	"Coder",
	"Dev",
	"User",
	"Guest",
	"Unknown",
	"Nobody",
	"Somebody",
	"Random",
	"Karna",
	"Mayukh | Phonk Lord",
	"Xx_Mayukh_xX",
	"NotRealMayukh",
	"THEBIGMSM",
	"msm",
	"WhrsMayukh",
	"Mayukhthehonoredone",
	"Tuff"
]

var animes = ["0","1","2","3"]
var animenumber = 0

func _ready():
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func host_game():
	if is_hosting:
		return
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_PLAYERS)
	if error != OK:
		print("Failed to host: ", error_string(error))
		return
	is_hosting = true
	multiplayer.multiplayer_peer = peer
	print("HOSTING OK on port ", PORT)
	hosting_started.emit()
	
	get_tree().change_scene_to_file("res://scsnes/house.tscn")
	await get_tree().scene_changed
	await get_tree().process_frame
	_register_and_spawn(multiplayer.get_unique_id())

func join_game(ip: String, port: int = PORT):
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, port)
	if error != OK:
		print("Failed to join: ", error)
		return
	multiplayer.multiplayer_peer = peer
	print("Joining ", ip, ":", port)
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
			data["name"]
		)
	_register_and_spawn(new_player_id)

func _register_and_spawn(id: int):
	if id in spawned_players:
		return
	spawned_players.append(id)
	var player_name = nameassign()
	player_data[id] = {
		"name": player_name
	}
	spawn_player.rpc(id, player_name)

@rpc("authority", "call_local", "reliable")
func spawn_player(id: int, assigned_name: String):
	if get_tree().current_scene == null:
		return
	if get_tree().current_scene.has_node(str(id)):
		return
	var player = PLAYER_SCENE.instantiate()
	player.name = str(id)
	player.set_anim(animes[animenumber])
	animenumber = (animenumber + 1) % animes.size()
	player.set_multiplayer_authority(id)
	player.namnam = assigned_name
	get_tree().current_scene.add_child(player)
	print(
		"Spawned player: ", id,
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

func nameassign():
	return names.pick_random()
