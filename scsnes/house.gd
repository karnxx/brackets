extends Node2D

var state := 1
var cycle_start_time: int

const LIGHT_TIME := 10
const BLACKOUT_TIME := 5
const TOTAL_TIME := LIGHT_TIME + BLACKOUT_TIME

@onready var darkness = $CanvasModulate
@onready var timer_label = $CanvasLayer/BlackoutTimer

signal black
signal white

func _ready():
	if multiplayer.is_server():
		cycle_start_time = Time.get_ticks_msec()
		sync_cycle.rpc(cycle_start_time)

func _process(_delta):
	if cycle_start_time == 0:
		return
	var elapsed := (Time.get_ticks_msec() - cycle_start_time) / 1000
	var cycle_time := int(elapsed) % TOTAL_TIME
	if cycle_time < LIGHT_TIME:
		white.emit()
		state = 1
		darkness.color = Color.WHITE
		var remaining := LIGHT_TIME - cycle_time
		timer_label.text = "LIGHTS\n00:%02d" % remaining
		pulse_timer(remaining <= 3)
	else:
		black.emit()
		state = 0
		darkness.color = Color(0.08, 0.08, 0.08)
		var blackout_elapsed := cycle_time - LIGHT_TIME
		var remaining := BLACKOUT_TIME - blackout_elapsed
		timer_label.text = "BLACKOUT\n00:%02d" % remaining
		pulse_timer(remaining <= 3)

@rpc("authority", "call_local", "reliable")
func sync_cycle(start_time: int):
	cycle_start_time = start_time

func pulse_timer(urgent: bool):
	var tween = create_tween()
	if urgent:
		timer_label.scale = Vector2(1.3, 1.3)
	else:
		timer_label.scale = Vector2(1.15, 1.15)
	tween.tween_property(timer_label, "scale", Vector2.ONE, 0.2)
