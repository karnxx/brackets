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
		var cam = body.get_node('Camera2D')
		cam.limit_left = cords[0]
		cam.limit_right = cords[1]
		cam.limit_top = cords[2]
		cam.limit_bottom = cords[3]
		body.set_camera_to_room()
