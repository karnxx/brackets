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

func _ready():
	if multiplayer.is_server():
		cycle_start_time = Time.get_ticks_msec()
	else:
		request_cycle_sync.rpc_id(1)
	white.connect(blabal)

func blabal():
	plrdex = {}
	var role = false
	for i in plrs:
		plrdex[i] = 0
		if i.role == "intruder":
			role = true
	if plrdex.size() > 2 and role == false:
		for i in plrs:
			i.vote()
		get_tree().create_timer(5).timeout.connect(voting_end)
	elif plrdex.size() <=2 and role == true:
		intwin()

func intwin():
	pass

func voting_end():
	var highest_count = -1
	var highest_player = null
	for i in plrdex:
		i.cleachoiuca()
		if plrdex[i] > highest_count:
			highest_count = plrdex[i]
			highest_player = i
	if highest_player:
		highest_player.die()

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
			black.emit()
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
