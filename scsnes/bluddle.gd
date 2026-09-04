extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group('plr'):
		body.footsteps = "b"

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group('plr'):
		body.footsteps = "n"
