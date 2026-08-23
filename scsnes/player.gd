extends CharacterBody2D

func _process(delta: float) -> void:
	if get_parent().state == 1:
		$CanvasLayer/ColorRect.color = Color(0,0,0,0)
	else:
		$CanvasLayer/ColorRect.color = Color(0,0,0,1)

func _physics_process(delta: float) -> void:
	var dir = Vector2.ZERO
	if Input.is_action_pressed("ui_left"):
		dir = Vector2.LEFT
	elif Input.is_action_pressed("ui_right"):
		dir = Vector2.RIGHT
	if get_parent().state == 1:
		velocity = dir * 300
	move_and_slide()
