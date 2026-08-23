extends Node2D

# 1 = lights on
# 0 = lights off
var state = 1

@onready var darkness = $CanvasModulate

func _ready():
	light_cycle()

func light_cycle():
	while true:
		state = 1
		darkness.color = Color.WHITE
		print("LIGHTS ON")

		await get_tree().create_timer(10.0).timeout

		state = 0
		darkness.color = Color(0.08, 0.08, 0.08)
		print("LIGHTS OFF")

		await get_tree().create_timer(5.0).timeout
