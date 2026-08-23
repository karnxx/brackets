extends Node2D

# 1 =lights on
# 0 =lights off
var state = 1

func _ready():
	light_cycle()
	
func light_cycle():
	while true:
		state = 1
		print("LIGHTS ON")
		await get_tree().create_timer(10.0).timeout

	state=0
	print("LIGHTS OFF")
	
	await get_tree().create_time(5.0).timeout


	
	
	
