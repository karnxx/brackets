extends Area2D


@export var room : int
@export var cords : Array[int]

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group('plr') and is_instance_valid(body):
		body.room = room
		get_parent().get_node('player/Camera2D').limit_left = cords[0]
		get_parent().get_node('player/Camera2D').limit_right = cords[1]
		get_parent().get_node('player/Camera2D').limit_top = cords[2]
		get_parent().get_node('player/Camera2D').limit_bottom = cords[3]
		body.set_camera_to_room()
