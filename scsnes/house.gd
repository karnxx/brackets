extends Node2D
var state := 1
var cycle_start_time: int = 0
var last_state := -1
const LIGHT_TIME := 20
const BLACKOUT_TIME := 10
const TOTAL_TIME := LIGHT_TIME + BLACKOUT_TIME
@onready var darkness = $CanvasModulate
@onready var timer_label = $CanvasLayer/BlackoutTimer
signal black
signal white
var plrs
var plrdex = {}

var votes = {}

var game_started := false

var roles = {
	"resident": 0,
	"intruder": 0,
	"medic": 0
}

var resweight := 0.5
var intweight := 0.25
var medweight := 0.25

var rnd := 0

func _ready():
	cycle_start_time = 0
	white.connect(blabal)
	if multiplayer.is_server():
		$CanvasLayer/Button.visible = true
	else:
		$CanvasLayer/Button.visible = false

func start():
	if not multiplayer.is_server():
		return
	assign_roles()
	cycle_start_time = Time.get_ticks_msec()
	start_game.rpc()

@rpc("authority", "call_local", "reliable")
func start_game():
	game_started = true
	$CanvasLayer/Button.visible = false
	$CanvasLayer/BlackoutTimer.visible = true
	if not multiplayer.is_server():
		request_cycle_sync.rpc_id(1)



func blabal():
	if not multiplayer.is_server():
		return
	if rnd == 1:
		return
	votes.clear()
	plrs = get_tree().get_nodes_in_group("plr")
	var intu := false
	for p in plrs:
		if p.role == "intruder":
			intu = true
	print("SERVER ROLES:")
	for p in plrs:
		print(p.namnam, " = ", p.role)
	if plrs.size() > 2 and not intu:
		for p in plrs:
			if not p.ded:
				p.start_vote.rpc_id(p.get_multiplayer_authority())
		get_tree().create_timer(5.0).timeout.connect(voting_end)
	elif plrs.size() <= 2 and intu:
		intwin()

func intwin():
	pass

@rpc("any_peer", "call_remote", "reliable")
func cast_vote(target_id: int):
	if not multiplayer.is_server():
		return
	var voter_id = multiplayer.get_remote_sender_id()
	if votes.has(voter_id):
		return
	var voter = get_tree().current_scene.get_node_or_null(str(voter_id))
	var target = get_tree().current_scene.get_node_or_null(str(target_id))
	if voter == null or target == null:
		return
	if voter.ded or target.ded:
		return
	if voter_id == target_id:
		return
	votes[voter_id] = target_id

@rpc("any_peer", "call_remote", "reliable")
func cast_skip():
	if not multiplayer.is_server():
		return
	var voter_id = multiplayer.get_remote_sender_id()
	if votes.has(voter_id):
		return
	var voter = get_tree().current_scene.get_node_or_null(str(voter_id))
	if voter == null or voter.ded:
		return
	votes[voter_id] = -1

func voting_end():
	if not multiplayer.is_server():
		return
	var vote_counts := {}
	var skip_count := 0
	for vote in votes.values():
		if vote == -1:
			skip_count += 1
		else:
			vote_counts[vote] = vote_counts.get(vote, 0) + 1
	var highest_count := 0
	var highest_player = null
	for target_id in vote_counts:
		var target = get_tree().current_scene.get_node_or_null(str(target_id))
		if target == null or target.ded:
			continue
		if vote_counts[target_id] > highest_count:
			highest_count = vote_counts[target_id]
			highest_player = target
	for p in get_tree().get_nodes_in_group("plr"):
		p.cleachoiuca.rpc_id(p.get_multiplayer_authority())
	print("SKIPS:", skip_count)
	print("HIGHEST:", highest_player, " VOTES:", highest_count)
	if skip_count >= highest_count:
		print("VOTE SKIPPED")
		votes.clear()
		return
	if highest_player:
		highest_player.die.rpc()
	votes.clear()

@rpc("any_peer", "call_remote", "reliable")
func request_cycle_sync():
	if not multiplayer.is_server():
		return
	var elapsed_ms = Time.get_ticks_msec() - cycle_start_time
	sync_cycle.rpc_id(multiplayer.get_remote_sender_id(), elapsed_ms)

@rpc("authority", "call_remote", "reliable")
func sync_cycle(elapsed_ms: int):
	cycle_start_time = Time.get_ticks_msec() - elapsed_ms

func _process(_delta):
	if cycle_start_time == 0:
		return
	var elapsed := (Time.get_ticks_msec() - cycle_start_time) / 1000
	var cycle_time := int(elapsed) % TOTAL_TIME
	if cycle_time < LIGHT_TIME:
		plrs = get_tree().get_nodes_in_group("plr")
		state = 1
		darkness.color = Color.WHITE
		var remaining := LIGHT_TIME - cycle_time
		timer_label.text = "LIGHTS\n00:%02d" % remaining
		if last_state != 1:
			last_state = 1
			rnd += 1
			white.emit()
		pulse_timer(remaining <= 3)
	else:
		state = 0
		darkness.color = Color(0.08, 0.08, 0.08)
		var blackout_elapsed := cycle_time - LIGHT_TIME
		var remaining := BLACKOUT_TIME - blackout_elapsed
		timer_label.text = "BLACKOUT\n00:%02d" % remaining
		if last_state != 0:
			last_state = 0
			if multiplayer.is_server():
				for i in get_tree().get_nodes_in_group("plr"):
					i.carry_role.rpc_id(i.get_multiplayer_authority())
		pulse_timer(remaining <= 3)

func pulse_timer(urgent: bool):
	var tween = create_tween()
	if urgent:
		timer_label.scale = Vector2(1.3, 1.3)
	else:
		timer_label.scale = Vector2(1.15, 1.15)
	tween.tween_property(
		timer_label,
		"scale",
		Vector2.ONE,
		0.2
	)

func assign_roles():
	if not multiplayer.is_server():
		return
	reset_roles()
	var plrs = get_tree().get_nodes_in_group("plr")
	for p in plrs:
		var assigned_role = "medic" #roleassigng()
		p.set_role.rpc(assigned_role)
		print(p.namnam, " -> ", assigned_role)

func reset_roles():
	roles["intruder"] = 0
	roles["medic"] = 0

func roleassigng():
	var randa = randf()
	if randa <= medweight or randa <= intweight:
		var randa2 = randf()
		if randa2 <= 0.5 and roles["medic"] == 0:
			roles["medic"] = 1
			return "medic"
		elif roles["intruder"] == 0:
			roles["intruder"] = 1
			return "intruder"
		else:
			return "resident"
	else:
		return "resident"
