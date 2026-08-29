extends Node2D
var state := 1
var pstart: int = 0
var pdurara: int = 0
var timer_running := false
const lightitme := 30
const votime := 10
const blacktime := 10
signal black
signal white
var plrs
var plrdex = {}

var votes = {}

var started := false

var roles = {
	"resident": 0,
	"intruder": 0,
	"medic": 0
}

var resweight := 0.5
var intweight := 0.25
var medweight := 0.25

var rnd := 0
var pending_actions := 0
var pending_choices := {}
var blackout_started := false

var voting_started := false
var vote_light := false


func _ready():
	if multiplayer.is_server():
		$CanvasLayer/Button.visible = true
	else:
		$CanvasLayer/Button.visible = false

func start():
	if not multiplayer.is_server():
		return
	roleasign()
	startgam.rpc()

@rpc("authority", "call_local", "reliable")
func startgam():
	started = true
	$CanvasLayer/Button.visible = false
	$CanvasLayer/BlackoutTimer.visible = true
	if multiplayer.is_server():
		start_lightitmer()

func start_lightitmer():
	if not multiplayer.is_server():
		return
	rnd += 1
	vote_light = false
	whitee.rpc()

@rpc("authority", "call_local", "reliable")
func whitee():
	state = 1
	$CanvasModulate.color = Color.WHITE
	pstart = Time.get_ticks_msec()
	pdurara = lightitme
	timer_running = true
	white.emit()

func blablalba():
	if not multiplayer.is_server():
		return
	timer_running = false
	blackout_started = false
	pending_choices.clear()
	darken.rpc()
	plrs = get_tree().get_nodes_in_group("plr")
	pending_actions = 0
	for p in plrs:
		if not p.ded and (p.role == "intruder" or p.role == "medic"):
			pending_actions += 1
	for i in plrs:
		if not i.ded and (i.role == "intruder" or i.role == "medic"):
			i.carry_role.rpc_id(i.get_multiplayer_authority())
	if pending_actions == 0:
		resaction()
	else:
		get_tree().create_timer(15.0).timeout.connect(fblackout)

func fblackout():
	if not blackout_started:
		resaction()

@rpc("any_peer", "call_remote", "reliable")
func subaction(action_role: String, target_id: int):
	if not multiplayer.is_server():
		return
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = multiplayer.get_unique_id()
	if pending_choices.has(sender_id):
		return
	var sender = get_tree().current_scene.get_node_or_null(str(sender_id))
	var target = get_tree().current_scene.get_node_or_null(str(target_id))
	if sender == null or target == null:
		return
	if sender.ded:
		return
	if sender.role != action_role:
		return
	if action_role == "intruder":
		if target.ded:
			return
	elif action_role == "medic":
		if target == sender:
			return
	pending_choices[sender_id] = {
		"role": action_role,
		"target": target_id
	}
	pending_actions -= 1
	print(
		"ACTION RECEIVED | ",
		sender.namnam,
		" | ",
		action_role,
		" | TARGET: ",
		target.namnam
	)
	if pending_actions <= 0 and not blackout_started:
		resaction()

func resaction():
	if not multiplayer.is_server() or blackout_started:
		return
	blackout_started = true
	print("RESOLVING ACTIONS")
	for sender_id in pending_choices:
		var choice = pending_choices[sender_id]
		if choice["role"] == "intruder":
			var target = get_tree().current_scene.get_node_or_null(str(choice["target"]))
			if target and not target.ded:
				print("KILLING: ", target.namnam)
				target.die.rpc()
	for sender_id in pending_choices:
		var choice = pending_choices[sender_id]
		if choice["role"] == "medic":
			var target = get_tree().current_scene.get_node_or_null(str(choice["target"]))
			if target == null:
				continue
			if target.ded:
				print("REVIVING: ", target.namnam)
				target.revive.rpc()
			else:
				print("SHIELDING: ", target.namnam)
				target.set_shield.rpc(true)
	pending_choices.clear()
	blackout.rpc()

@rpc("authority", "call_local", "reliable")
func darken():
	state = 0
	$CanvasModulate.color = Color(0.08, 0.08, 0.08)

@rpc("authority", "call_local", "reliable")
func blackout():
	state = 0
	$CanvasModulate.color = Color(0.08, 0.08, 0.08)
	pstart = Time.get_ticks_msec()
	pdurara = blacktime
	timer_running = true
	black.emit()

func vota2():
	if not multiplayer.is_server():
		return
	if voting_started:
		return
	voting_started = true
	votes.clear()
	plrs = get_tree().get_nodes_in_group("plr")
	var alive_count := 0
	var intu := false
	for i in plrs:
		if not i.ded:
			alive_count += 1
			if i.role == "intruder":
				intu = true
	print("SERVER ROLES:")
	for i in plrs:
		print(i.namnam, " = ", i.role, " | ded: ", i.ded)
	if alive_count <= 2 and intu:
		intwin()
		voting_started = false
		return
	if alive_count <= 2:
		votend()
		return
	startvote.rpc()
	for i in plrs:
		if not i.ded:
			i.start_vote.rpc_id(i.get_multiplayer_authority())
	get_tree().create_timer(15.0).timeout.connect(votend)

@rpc("authority", "call_local", "reliable")
func startvote():
	state = 1
	$CanvasModulate.color = Color.WHITE
	timer_running = false
	$CanvasLayer/BlackoutTimer.text = "VOTING"
	white.emit()

func intwin():
	pass

@rpc("any_peer", "call_remote", "reliable")
func vota(target_id: int):
	if not multiplayer.is_server():
		return
	var voter_id = multiplayer.get_remote_sender_id()
	if voter_id == 0:
		voter_id = multiplayer.get_unique_id()
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
	var alive_count := 0
	for i in get_tree().get_nodes_in_group("plr"):
		if not i.ded:
			alive_count += 1
	if votes.size() >= alive_count:
		votend()

@rpc("any_peer", "call_remote", "reliable")
func skip():
	if not multiplayer.is_server():
		return
	var voter_id = multiplayer.get_remote_sender_id()
	if voter_id == 0:
		voter_id = multiplayer.get_unique_id()
	if votes.has(voter_id):
		return
	var voter = get_tree().current_scene.get_node_or_null(str(voter_id))
	if voter == null or voter.ded:
		return
	votes[voter_id] = -1
	var alive_count := 0
	for i in get_tree().get_nodes_in_group("plr"):
		if not i.ded:
			alive_count += 1
	if votes.size() >= alive_count:
		votend()

func votend():
	if not multiplayer.is_server():
		return
	if not voting_started:
		return
	voting_started = false
	var vote_counts := {}
	var skip_count := 0
	for i in votes.values():
		if i == -1:
			skip_count += 1
		else:
			vote_counts[i] = vote_counts.get(i, 0) + 1
	var highest_count := 0
	var highest_player = null
	for i in vote_counts:
		var target = get_tree().current_scene.get_node_or_null(str(i))
		if target == null or target.ded:
			continue
		if vote_counts[i] > highest_count:
			highest_count = vote_counts[i]
			highest_player = target
	for i in get_tree().get_nodes_in_group("plr"):
		i.cleachoiuca.rpc_id(i.get_multiplayer_authority())
	votes.clear()
	if skip_count >= highest_count:
		print("VOTE SKIPPED")
	elif highest_player:
		highest_player.die.rpc()
	lightvote.rpc()

@rpc("authority", "call_local", "reliable")
func lightvote():
	state = 1
	$CanvasModulate.color = Color.WHITE
	pstart = Time.get_ticks_msec()
	pdurara = votime
	timer_running = true
	white.emit()

func _process(_delta):
	if not timer_running:
		return
	var elapsed := (Time.get_ticks_msec() - pstart) / 1000
	var remaining: int = pdurara - int(elapsed)
	if remaining < 0:
		remaining = 0
	$CanvasLayer/BlackoutTimer.text = ("LIGHTS\n00:%02d" if state == 1 else "BLACKOUT\n00:%02d") % remaining
	pulse_timer(remaining <= 3)
	if elapsed >= pdurara and multiplayer.is_server():
		timer_running = false
		if state == 1:
			if vote_light:
				vote_light = false
				blablalba()
			else:
				blablalba()
		else:
			vota2()

func pulse_timer(urgent: bool):
	var tween = create_tween()
	if urgent:
		$CanvasLayer/BlackoutTimer.scale = Vector2(1.3, 1.3)
	else:
		$CanvasLayer/BlackoutTimer.scale = Vector2(1.15, 1.15)
	tween.tween_property(
		$CanvasLayer/BlackoutTimer,
		"scale",
		Vector2.ONE,
		0.2
	)

func roleasign():
	if not multiplayer.is_server():
		return
	resroles()
	var plrs = get_tree().get_nodes_in_group("plr")
	for i in plrs:
		var assigned_role = roleassigng()
		i.set_role.rpc(assigned_role)

func resroles():
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
