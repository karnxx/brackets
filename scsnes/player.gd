extends CharacterBody2D

@onready var sprite = $AnimatedSprite2D

var room = 0

var role
var namnam
var is_using = false
var shield = false
var ded = false

var anima = "0"

var lastvote := -1

func _ready() -> void:
	$Label.text = namnam
	if not is_multiplayer_authority():
		$Camera2D.enabled = false
		$CanvasLayer.visible = false
	else:
		$Camera2D.enabled = true
		set_camera_to_room()
		print("LOCAL PLAYER CAMERA ENABLED: ", multiplayer.get_unique_id())

@rpc("any_peer", "call_local", "unreliable")
func sync_state(pos: Vector2, anim: StringName, facing_left: bool, dead: bool):
	if is_multiplayer_authority():
		return
	global_position = pos
	ded = dead
	sprite.play(anima + anim + ("0" if ded else "1"))
	sprite.flip_h = facing_left

func am_i_dead() -> bool:
	for p in get_tree().get_nodes_in_group("plr"):
		if p.is_multiplayer_authority():
			return p.ded
	return false

func _process(_delta: float) -> void:
	var i_am_dead := am_i_dead()
	visible = not ded or i_am_dead
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

func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	var dir := Vector2.ZERO
	if Input.is_action_pressed("move_left"):
		dir.x -= 1
	if Input.is_action_pressed("move_right"):
		dir.x += 1
	var anim := "idle"
	if dir != Vector2.ZERO:
		dir = dir.normalized()
		anim = "walk"
		if dir.x < 0:
			sprite.flip_h = true
		elif dir.x > 0:
			sprite.flip_h = false
	if get_parent() is not Control:
		if get_parent().state == 1:
			velocity = dir * 120
		else:
			velocity = Vector2.ZERO
	else:
		velocity = dir * 120
	move_and_slide()
	sprite.play(anima + anim + ("0" if ded else "1"))
	sync_state.rpc(
		global_position,
		anim,
		sprite.flip_h,
		ded
	)

func cleachoiuca():
	is_using = false
	for child in $CanvasLayer/VBoxContainer.get_children():
		child.hide()
		if child.name != "skip":
			child.queue_free()

@rpc("any_peer", "call_local", "reliable")
func carry_role():
	print(
		"CARRY ROLE CALLED | Local ID:",
		multiplayer.get_unique_id(),
		" | Player:",
		name,
		" | Role:",
		role,
		" | Authority:",
		get_multiplayer_authority()
	)
	if role == "intruder":
		is_using = true
		for i in get_tree().get_nodes_in_group("plr"):
			if i != self and i.ded == false:
				var bitun: Button = preload("res://scsnes/chooseb.tscn").instantiate()
				bitun.text = i.namnam
				bitun.pressed.connect(use.bind(i))
				$CanvasLayer/VBoxContainer.add_child(bitun)
	elif role == "medic":
		is_using = true
		for i in get_tree().get_nodes_in_group("plr"):
			if i != self:
				var bitun: Button = preload("res://scsnes/chooseb.tscn").instantiate()
				bitun.text = i.namnam
				bitun.pressed.connect(use.bind(i))
				$CanvasLayer/VBoxContainer.add_child(bitun)

@rpc("any_peer", "call_local", "reliable")
func die():
	if shield:
		set_shield.rpc(false)
		return
	ded = true

@rpc("any_peer", "call_local", "reliable")
func revive():
	ded = false
	set_shield.rpc(false)

@rpc("any_peer", "call_local", "reliable")
func start_vote():
	vote()

@rpc("any_peer", "call_local", "reliable")
func set_role(new_role: String):
	role = new_role
	print(
		"ROLE SET | ",
		name,
		" | ",
		role,
		" | Local ID: ",
		multiplayer.get_unique_id()
	)

func use(bitun):
	if not is_using:
		return
	cleachoiuca()
	if role == "intruder":
		if is_instance_valid(bitun):
			bitun.die.rpc()
	elif role == "medic":
		if not is_instance_valid(bitun):
			return
		if bitun.ded:
			bitun.revive.rpc()
		else:
			bitun.set_shield.rpc(true)

func skip_vote():
	if lastvote != -1:
		return
	lastvote = -2
	$CanvasLayer/VBoxContainer/skip.visible = false
	cleachoiuca()
	get_parent().cast_skip.rpc_id(1)

@rpc("any_peer", "call_local", "reliable")
func set_shield(value: bool):
	shield = value

@rpc("any_peer", "call_local", "reliable")
func vote():
	cleachoiuca()
	lastvote = -1
	for i in get_tree().get_nodes_in_group("plr"):
		if i != self and not i.ded:
			var bitun: Button = preload("res://scsnes/chooseb.tscn").instantiate()
			bitun.text = i.namnam
			var target_id := i.get_multiplayer_authority()
			bitun.pressed.connect(add_vote.bind(target_id))
			$CanvasLayer/VBoxContainer.add_child(bitun)
	$CanvasLayer/VBoxContainer/skip.visible = true

func add_vote(target_id: int):
	if lastvote != -1:
		return
	lastvote = target_id
	$CanvasLayer/VBoxContainer/skip.visible = false
	for child in $CanvasLayer/VBoxContainer.get_children():
		if child.name != "skip":
			child.queue_free()
	get_parent().cast_vote.rpc_id(1, target_id)
