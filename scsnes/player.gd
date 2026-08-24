extends CharacterBody2D

@onready var sprite = $AnimatedSprite2D

var room = 0

@onready var sync = $MultiplayerSynchronizer

func _ready():
	var config = SceneReplicationConfig.new()
	config.add_property(NodePath("..:position"))

	sync.replication_config = config

	if not is_multiplayer_authority():
		$Camera2D.enabled = false
		$CanvasLayer.visible = false
	else:
		$Camera2D.enabled = true
		$Camera2D.zoom = Vector2(2, 2)

func _process(delta: float) -> void:
	if get_parent() is not Control:
		if get_parent().state == 1:
			$CanvasLayer/ColorRect.visible = false
			$CanvasLayer/ColorRect.color = Color(0, 0, 0, 0)
		else:
			$CanvasLayer/ColorRect.visible = true
			$CanvasLayer/ColorRect.color = Color(0, 0, 0, 1)

func _unhandled_input(event):
	if not is_multiplayer_authority():
		return
	if event.is_action_pressed("interact"):
		interact()

func interact():
	var item = get_hovered_item()
	if item == null:
		return
	if global_position.distance_to(item.global_position) > item.interact_distance:
		return
	item.request_interaction()

func get_hovered_item():
	for item in get_tree().get_nodes_in_group("inter"):
		if item.mouse_over:
			return item
	return null
func set_camera_to_room():
	var cam = $Camera2D

	var room_height = cam.limit_bottom - cam.limit_top

	var zoom_amount = 648.0 / room_height

	cam.zoom = Vector2(zoom_amount, zoom_amount)

	cam.global_position.y = (cam.limit_top + cam.limit_bottom) / 2.0

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
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
	if get_parent() is not Control:
		if get_parent().state == 1:
			velocity = dir * 120
		else:
			velocity = Vector2.ZERO

	move_and_slide()
