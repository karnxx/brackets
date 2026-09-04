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

@onready var emp: TextureRect = $CanvasLayer/CenterContainer/emp
@onready var ful: TextureRect = $CanvasLayer/CenterContainer/ful


var flickeringa = false
var flicktween 

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

const chatdistance := 250.0

func _ready():
	if multiplayer.is_server():
		$CanvasLayer/Button.visible = true
		$CanvasLayer/TextureRect.visible = false
	else:
		$CanvasLayer/Button.visible = false
		$CanvasLayer/TextureRect.visible = false

func start():
	if not multiplayer.is_server():
		return
	print('ikthe')
	roleasign()
	startgam.rpc()

@rpc("authority", "call_local", "reliable")
func startgam():
	started = true
	$CanvasLayer/Button.visible = false
	$CanvasLayer/BlackoutTimer.visible = false
	if multiplayer.is_server():
		start_lightitmer()

func flickerflocker():
	if flicktween and flicktween.is_valid():
		flicktween.kill()
	var darkaa
	if state == 1:
		darkaa = true
	else:
		darkaa = false
	var colo1
	var colo2
	if darkaa:
		colo1 = Color.WHITE
		colo2 = Color(0.15, 0.15, 0.15)
	else:
		colo1 = Color(0.08, 0.08, 0.08)
		colo2 = Color(0.4, 0.4, 0.4)
	var plara = get_tree().current_scene.get_node_or_null(str(multiplayer.get_unique_id()))
	flicktween = create_tween()
	var flicks = 9
	for i in range(flicks):
		$AudioStreamPlayer2.pitch_scale = randf_range(0.8, 1.3)
		$AudioStreamPlayer2.volume_db = randf_range(-10.0, 0.0)
		$AudioStreamPlayer2.play()
		var arnda = randf_range(0.15, 0.35)
		flicktween.tween_property($CanvasModulate, "color", colo2, arnda * 0.35)
		flicktween.parallel().tween_property(ful, "modulate:a", randf_range(0.1, 0.4), arnda * 0.35)
		flicktween.tween_property($CanvasModulate, "color", colo1, arnda * 0.65)
		flicktween.parallel().tween_property(ful, "modulate:a", 1.0, arnda * 0.65)
	flicktween.tween_callback(func():
		ful.modulate.a = 1.0
		$CanvasModulate.color = colo1
	)

func bloodpile(plar):
	var blooda = preload("res://scsnes/bluddle.tscn").instantiate()
	blooda.global_position = Vector2(plar.global_position.x,22)
	add_child(blooda)

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
	flickeringa = false
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
	for i in plrs:
		i.reset_kill_flag.rpc_id(i.get_multiplayer_authority())
		if not i.ded and i.role == "intruder":
			pending_actions += 1
		if not i.ded and i.role == "medic":
			if rnd - i.medround >= 2:
				pending_actions += 1
	for i in plrs:
		if not i.ded and i.role == "intruder":
			i.carry_role.rpc_id(i.get_multiplayer_authority())
		elif not i.ded and i.role == "medic":
			if rnd - i.medround >= 2:
				i.carry_role.rpc_id(i.get_multiplayer_authority())
	if pending_actions == 0:
		resaction()
	else:
		get_tree().create_timer(15.0).timeout.connect(fblackout)

func fblackout():
	if not blackout_started:
		resaction()

@rpc("any_peer", "call_local", "reliable")
func subaction(rola: String, tid: int):
	if not multiplayer.is_server():
		return
	var sid = multiplayer.get_remote_sender_id()
	if sid == 0:
		sid = multiplayer.get_unique_id()
	if pending_choices.has(sid):
		return
	var sender = get_tree().current_scene.get_node_or_null(str(sid))
	var target = get_tree().current_scene.get_node_or_null(str(tid))
	if sender == null or target == null:
		return
	if sender.ded:
		return
	if sender.role != rola:
		return
	if rola == "intruder":
		if target.ded:
			return
	elif rola == "medic":
		if target == sender:
			return
	pending_choices[sid] = {
		"role": rola,
		"target": tid
	}
	pending_actions -= 1
	if pending_actions <= 0 and not blackout_started:
		resaction()

func resaction():
	if not multiplayer.is_server() or blackout_started:
		return
	blackout_started = true
	for i in pending_choices:
		var cc = pending_choices[i]
		if cc["role"] == "intruder":
			var target = get_tree().current_scene.get_node_or_null(str(cc["target"]))
			if target and not target.ded:
				target.die.rpc()
				$AudioStreamPlayer4.play()
	for i in pending_choices:
		var cc = pending_choices[i]
		if cc["role"] == "medic":
			var target = get_tree().current_scene.get_node_or_null(str(cc["target"]))
			if target == null:
				continue
			if target.ded:
				target.revive.rpc()
			else:
				target.set_shield.rpc(true)
	pending_choices.clear()
	blackout.rpc()

@rpc("authority", "call_local", "reliable")
func darken():
	state = 0
	$CanvasModulate.color = Color(0.08, 0.08, 0.08)
	if $AudioStreamPlayer != null:
		$AudioStreamPlayer.play()

@rpc("authority", "call_local", "reliable")
func blackout():
	state = 0
	$CanvasModulate.color = Color(0.08, 0.08, 0.08)
	pstart = Time.get_ticks_msec()
	pdurara = blacktime
	timer_running = true
	flickeringa = false
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
	showwin.rpc("1")

@rpc("any_peer", "call_local", "reliable")
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
func chatmessage(message: String):
	if not multiplayer.is_server():
		return
	var sid = multiplayer.get_remote_sender_id()
	if sid == 0:
		sid = multiplayer.get_unique_id()
	var sender = get_tree().current_scene.get_node_or_null(str(sid))
	if sender == null or sender.ded:
		return
	message = message.strip_edges()
	if message == "":
		return
	if message.length() > 100:
		message = message.left(100)
	for i in get_tree().get_nodes_in_group("plr"):
		if i == null:
			continue
		if i.room != sender.room:
			continue
		if sender.global_position.distance_to(i.global_position) <= chatdistance:
			var id: int = i.get_multiplayer_authority()
			if id == 1:
				chatreceive(sid, message)
			else:
				chatreceive.rpc_id(id, sid, message)

@rpc("authority", "call_local", "reliable")
func chatreceive(ida: int, message: String):
	var sender = get_tree().current_scene.get_node_or_null(str(ida))
	if sender == null:
		return
	sender.chatshow(message)
	for i in range(message.length()):
		$AudioStreamPlayer3.pitch_scale = randf_range(0.2, 1.6)
		$AudioStreamPlayer3.play()
		await get_tree().create_timer(0.51).timeout

@rpc("any_peer", "call_local", "reliable")
func skip():
	if not multiplayer.is_server():
		return
	var votera = multiplayer.get_remote_sender_id()
	if votera == 0:
		votera = multiplayer.get_unique_id()
	if votes.has(votera):
		return
	var voter = get_tree().current_scene.get_node_or_null(str(votera))
	if voter == null or voter.ded:
		return
	votes[votera] = -1
	var aliveppl := 0
	for i in get_tree().get_nodes_in_group("plr"):
		if not i.ded:
			aliveppl += 1
	if votes.size() >= aliveppl:
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
		highest_player.die.rpc(true)
		$AudioStreamPlayer4.play()
		if highest_player.role == "intruder":
			showwin.rpc("2")
	lightvote.rpc()

@rpc("authority", "call_local", "reliable")
func showwin(result: String):
	$CanvasLayer/win.enda(result)


@rpc("authority", "call_local", "reliable")
func lightvote():
	state = 1
	$CanvasModulate.color = Color.WHITE
	pstart = Time.get_ticks_msec()
	pdurara = votime
	timer_running = true
	flickeringa = false
	white.emit()

func _process(_delta):
	if not timer_running:
		return
	var elapsed := (Time.get_ticks_msec() - pstart) / 1000
	var remaining: int = pdurara - int(elapsed)
	if remaining < 0:
		remaining = 0
	if remaining <= 5 and remaining > 0 and not flickeringa:
		flickeringa = true
		flickerflocker()
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
		var rara = roleassigng()
		i.set_role.rpc(rara)
		show_role.rpc_id(i.get_multiplayer_authority(), rara)

@rpc("authority", "call_local", "reliable")
func show_role(i):
	await $CanvasLayer/RoleReveal.doit(i)

func resroles():
	roles["intruder"] = 0
	roles["medic"] = 0

func roleassigng():
	var randa = randf()
	if randa <= medweight or randa <= intweight:
		var randada = randf()
		if randada <= 0.5 and roles['intruder'] == 0:
			roles["intruder"] += 1
			return "intruder"
		elif randada > 0.5 and roles['medic'] == 0:
			roles['medic'] += 1
			return "medic"
	var randadada = randf()
	if randadada <= 0.5 :
		if roles['intruder'] == 0:
			roles['intruder'] += 1
			return "intruder"
		elif roles['medic'] == 0:
			roles['medic'] += 1
			return "medic"
	else:
		if roles['medic'] == 0:
			roles['medic'] += 1
			return "medic"
		elif roles['intruder'] == 0:
			roles['intruder'] += 1
			return "intruder"
	roles['resident'] += 1
	return "resident"
