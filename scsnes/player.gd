extends CharacterBody2D

@onready var sprite = $AnimatedSprite2D
@onready var camera = $Camera2D
@onready var canvas_layer = $CanvasLayer

var room = 0


func _ready() -> void:
	if not is_multiplayer_authority():
		camera.enabled = false
		canvas_layer.visible = false
		return

	canvas_layer.visible = true

	await get_tree().process_frame

	camera.enabled = true
	camera.make_current()
	camera.zoom = Vector2(2.8, 2.8)

	print("LOCAL PLAYER CAMERA ENABLED: ", multiplayer.get_unique_id())


@rpc("any_peer", "call_local", "unreliable")
func sync_state(pos: Vector2, anim: StringName, facing_left: bool):
	if is_multiplayer_authority():
		return

	global_position = pos
	sprite.play(anim)
	sprite.flip_h = facing_left


func _process(_delta: float) -> void:
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
	if not is_multiplayer_authority():
		return

	var room_height = camera.limit_bottom - camera.limit_top

	if room_height <= 0:
		return

	var zoom_amount = 648.0 / room_height

	camera.zoom = Vector2(zoom_amount, zoom_amount)

	camera.global_position.y = (
		camera.limit_top + camera.limit_bottom
	) / 2.0


func _physics_process(_delta: float) -> void:
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
		sprite.play("idle")

	if get_parent() is not Control:
		if get_parent().state == 1:
			velocity = dir * 120
		else:
			velocity = Vector2.ZERO

	move_and_slide()

	sync_state.rpc(
		global_position,
		sprite.animation,
		sprite.flip_h
	)
