extends CharacterBody2D

@onready var sprite = $AnimatedSprite2D


func _process(delta: float) -> void:
	if get_parent().state == 1:
		$CanvasLayer/ColorRect.color = Color(0, 0, 0, 0)
	else:
		$CanvasLayer/ColorRect.color = Color(0, 0, 0, 1)


func _physics_process(delta: float) -> void:
	var dir = Vector2.ZERO

	if Input.is_action_pressed("ui_left"):
		dir = Vector2.LEFT
		sprite.play("walk_left")
		sprite.flip_h = false

	elif Input.is_action_pressed("ui_right"):
		dir = Vector2.RIGHT
		sprite.play("walk_left")
		sprite.flip_h = true

	elif Input.is_action_pressed("ui_up"):
		dir = Vector2.UP
		sprite.play("walk_up")
		sprite.flip_h = false

	elif Input.is_action_pressed("ui_down"):
		dir = Vector2.DOWN
		sprite.play("walk_down")
		sprite.flip_h = false

	else:
		sprite.stop()

	if get_parent().state == 1:
		velocity = dir * 120
	else:
		velocity = Vector2.ZERO

	move_and_slide()
