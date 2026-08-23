extends CharacterBody2D

@onready var sprite = $AnimatedSprite2D

var room = 0

func _process(delta: float) -> void:
	if get_parent().state == 1:
		$CanvasLayer/ColorRect.color = Color(0, 0, 0, 0)
	else:
		$CanvasLayer/ColorRect.color = Color(0, 0, 0, 1)

func set_camera_to_room():
	var cam = $Camera2D
	
	var room_width = cam.limit_right - cam.limit_left
	var viewport_width = get_viewport_rect().size.x
	
	var zoom_amount = viewport_width / room_width
	
	cam.zoom = Vector2(zoom_amount, zoom_amount)

func _physics_process(delta: float) -> void:
	var dir = Vector2.ZERO
	if Input.is_action_pressed("ui_left"):
		dir = Vector2.LEFT
		sprite.play("walk")
		sprite.flip_h = true
	elif Input.is_action_pressed("ui_right"):
		dir = Vector2.RIGHT
		sprite.play("walk")
		sprite.flip_h = false
	if dir == Vector2.ZERO:
		$AnimatedSprite2D.play("idle")
	
	if get_parent().state == 1:
		velocity = dir * 120
	else:
		velocity = Vector2.ZERO

	move_and_slide()
