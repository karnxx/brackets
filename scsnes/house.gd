extends Node2D

# 1 =lights on
# 0 =lights off
var state = 1

func _ready() -> void:
	light_crc()

func light_crc():
	while true:
		if state == 0:
			await get_tree().create_timer(5.0).timeout
			state = 1
			print("LIGHTS ON")
		elif state == 1:
			await get_tree().create_timer(10.0).timeout
			state = 0
			print("LIGHTS OFF")
