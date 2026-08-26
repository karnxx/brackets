extends CharacterBody2D

@onready var sprite = $AnimatedSprite2D

var room = 0

var role

var namnam

var is_using = false

var shield = true

var ded = false

func _ready() -> void:
	if not is_multiplayer_authority():
		$Camera2D.enabled = false
		$CanvasLayer.visible = false
	else:
		$Label.text = namnam
		$Camera2D.enabled = true
		set_camera_to_room()
		print("LOCAL PLAYER CAMERA ENABLED: ", multiplayer.get_unique_id())

@rpc("any_peer", "call_local", "unreliable")
func sync_state(pos: Vector2, anim: StringName, facing_left: bool):
	if is_multiplayer_authority():
		return
	global_position = pos
	sprite.play(anim)
	sprite.flip_h = facing_left

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
	if Input.is_action_pressed("move_left"):
		dir.x -= 1
	if Input.is_action_pressed("move_right"):
		dir.x += 1
	if dir != Vector2.ZERO:
		dir = dir.normalized()
		sprite.play("walk")
		if dir.x < 0:
			sprite.flip_h = true
		elif dir.x > 0:
			sprite.flip_h = false
	else:
		sprite.play("idle")
	if get_parent() is not Control:
		if get_parent().state == 1:
			velocity = dir * 120
		else:
			velocity = Vector2.ZERO
	else:
		velocity = dir * 120
	move_and_slide()
	sync_state.rpc(
		global_position,
		sprite.animation,
		sprite.flip_h
	)

func carry_role():
	if role == "intruder":
		is_using = true
		for i in get_tree().get_nodes_in_group("plr"):
			if i != self and i.ded == false:
				var bitun : Button = preload("res://scsnes/chooseb.tscn").instantiate()
				bitun.text = i.namnam
				bitun.pressed.connect(use.bind(i))
				$CanvasLayer/VBoxContainer.add_child(bitun)
	elif role == "medic":
		for i in get_tree().get_nodes_in_group("plr"):
			if i != self:
				var bitun : Button = preload("res://scsnes/chooseb.tscn").instantiate()
				bitun.text = i.namnam
				bitun.pressed.connect(use.bind(i))
				$CanvasLayer/VBoxContainer.add_child(bitun)

@rpc("any_peer", "call_local")
func die():
	if shield:
		shield = false
		return
	ded = true

@rpc("any_peer", "call_local")
func revive():
	ded = false

func use(bitun):
	if is_using:
		if role == "intruder":
			bitun.die.rpc()
		if role == "medic":
			if bitun.ded == true:
				bitun.revive.rpc()
			else:
				bitun.shield = true
