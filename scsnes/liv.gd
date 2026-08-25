extends Area2D
@export var room : int
@export var cords : Array[int]

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	print("backroom")
	if body.is_in_group('plr') and is_instance_valid(body):
		print("greening")
		body.room = room
<<<<<<< HEAD
		get_parent().get_node('player/Camera2D').limit_left = cords[0]
		get_parent().get_node('player/Camera2D').limit_right = cords[1]
		get_parent().get_node('player/Camera2D').limit_top = cords[2]
		get_parent().get_node('player/Camera2D').limit_bottom = cords[3]
=======
		var cam = body.get_node('Camera2D')
		cam.limit_left = cords[0]
		cam.limit_right = cords[1]
		cam.limit_top = cords[2]
		cam.limit_bottom = cords[3]
>>>>>>> 0da43f87222c5c74248fb8b633fad1e6d674aef7
		body.set_camera_to_room()
